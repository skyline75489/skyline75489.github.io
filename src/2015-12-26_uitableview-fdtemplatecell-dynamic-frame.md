FDTemplateLayoutCell Frame 布局实践
==================================

**注意:**以下内容均是针对 FDTemplateLayoutCell 的 1.3 版本，1.4 版本中 frame layout 有关的内容出现了 breaking change，导致下面的内容不再完全适用，望周知。

[UITableView+FDTemplateLayoutCell](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell) 是百度知道团队出品的一款用于在 UITableView 中基于 auto layout 解决动态高度计算问题的框架。由于作者本身使用 XIB 比较多，有关基于 frame 布局的内容就介绍的比较少，使得我自己在基于这个框架使用 frame 布局时碰到了一些问题，在这里记录一下，供大家参考。

### 基本使用

首先说一下取 Cell 的问题，FDTemplateLayoutCell 依赖于我们把 Cell Identifier 注册到 tableView，然后通过 Cell Identifier 取出 Cell，不少同学可能还在使用旧的先 dequeue，然后再判断是不是 nil 的方法：

```objectivec
UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"];
}
// ...
```

这种方法确实是可行的，但是现在已经不再推荐了。推荐使用的方法是，先把 cell 的 class 和 identifier 注册到 tableView:

```objectivec
[self.tableView registerClass:[TableViewCell class] forCellReuseIdentifier:kCellIdentifier];
```

然后再使用`dequeueReusableCellWithIdentifier:forIndexPath:
`这个方法（注意和上面方法名称上的区别，多了一个 forIndexPath 参数）取出 cell:

```objectivec
TableViewCell *cell = (TableViewCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
// ... 
return cell;
```

可以看到这里是不用判断 `if (cell == nil)` 的，因为这个方法保证返回的 cell 是可用的。如果没有可以 dequeue 的 cell 它会创建一个新的返回过来（其实也就是上面 `if (cell == nil)` 那个逻辑，不过不需要我们来做了，苹果帮我们实现了）。

FDTemplateLayoutCell 也是根据 cell identifier 来得到 cell 的，因此需要我们使用注册 cell 的方法，不然直接就会报找不到 cell 的错误。

然后，到了使用 FDTemplateLayoutCell 来计算高度的时候了。实话说，官网的 README 对我这种小白来说感觉是有些误导性的，在 [Basic Usage](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell#basic-usage) 这个部分，它说用 `fd_heightForCellWithIdentifier` 这个方法，在 block 里对 Cell 进行 configure 就可以了，然后我就照着做了，把 configure 挪到了 heightForRow 里：

```objectivec
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = (TableViewCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView fd_heightForCellWithIdentifier:kCellIdentifier configuration:^(TableViewCell *cell){
        [cell configureUsingText:self.dataSource[indexPath.row]];
    }];
}
```

结果运行一看，Cell 里啥都没有。。。

看一下 FD 自己的 Demo 和它的源码我才发现，还是自己太 naive 了。`fd_height` 这个函数在实现里面这个 cell 和真正显示的 cell 并不是一回事，真正显示的 cell 还是在 cellForRowAtIndexPath 那个里返回的。`fd_height` 里的 cell 就是单纯地算了一下高度而已。因此我们可以看到，FD 自己的 Demo 里，configure 其实是使用了两次的：

```objectivec
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FDFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FDFeedCell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    FDSimulatedCacheMode mode = self.cacheModeSegmentControl.selectedSegmentIndex;
    switch (mode) {
        case FDSimulatedCacheModeNone:
            return [tableView fd_heightForCellWithIdentifier:@"FDFeedCell" configuration:^(FDFeedCell *cell) {
                [self configureCell:cell atIndexPath:indexPath];
            }];
            // ...
}
```

更深层的原因是，tableView 的方法中，heightForRow 是先于 cellForRow 被调用的，在这里你也没办法对真正的 cell 进行configure，因为人家还不存在呢。

### 算高优化

FD 本身对于高度计算提供了缓存机制，可以很大程度上减少高度的计算量。但是在上面我们看到，为了得到正确的高度，configure 这个函数被调用了两次。当 cell 当中的控件比较多时，以及在下面我们要提到的需要 Cell 高度进行动态变化时，这样执行两次 configure 的成本也是比较高的。

有没有办法优化呢？其实仔细想想我们就会发现，在 heightForRow 中我们其实没有必要进行完整的 configure，因为我们只是想得到高度而已，这里面的 cell 也不会真正被使用。我们可以单独写一个 updateHeight，专门用于计算高度：

```objectivec
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = (TableViewCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    [cell configureUsingText:self.dataSource[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView fd_heightForCellWithIdentifier:kCellIdentifier configuration:^(TableViewCell *cell){
        [cell updateHeightUsingText:self.dataSource[indexPath.row]];
    }];
}
```
例如 cell 中有图片和 label，我们在 updateHeight 中计算出正确的高度就可以了，没有必要去真正执行  `[_imageView setImage:]` 和 `[_label setText:]` 这些应该放到 configure 中的方法。

首先我们定义一个简单的 MyLabel：

```objectivec
@interface MyLabel : UILabel

@property (nonatomic) CGFloat caculatedHeight;

- (void)updateHeightUsingText:(NSString *)text;

@end

@implementation MyLabel

- (void)updateHeightUsingText:(NSString *)text {
    self.caculatedHeight = [text boundingRectWithSize:CGSizeMake(300, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{ NSFontAttributeName:[self font]} context:nil].size.height;
}

@end
```

之所以要定义 MyLabel 就是为了存储计算的出来真正的高度(caculatedHeight)，然后在自定义的 Cell 中：


```objectivec
- (void)configureUsingText:(NSString *)text {
    _label.text = text;
    [self.label updateHeightUsingText:text];
}
- (void)updateHeightUsingText:(NSString *)text {
    [self.label updateHeightUsingText:text];
}
```

注意在 configure 中也是要做 update 高度的，因为真正 configure 的 Cell 和 `fd_height` 当中的 cell 不是一个 cell，如果不做这一步的话，真正显示出来的 cell 的 label 中 caculatedHeight 这个属性还是会为 0（不知道这么说大家理解没理解，没理解的话可以去跑一下 FD 的代码，你会发现在 `fd_height` 这个函数的 configuration block 中出现的 cell 一直就是那一个，地址没变过，它和真正显示出来的 Cell 不是一个实例）。

现在出来的结果是这样的：


![1](../img/fd_frame/1.png)

可以看到 Cell 的高度是没问题了，但是 Label 本身大小还是没有变化。出现这种情况，是因为我们少了一个关键的步骤—— layoutSubviews：

```objectivec
- (void)layoutSubviews {
    [super layoutSubviews];
    _label.frame = CGRectMake(5, 5, 300, self.label.caculatedHeight);
}
```

注意这里需要调用 `super`，如果不调用的话，会发现 Cell 自己的高度出现问题。

现在终于得到了我们想要的结果：

![2](../img/fd_frame/2.png)


### 高度变化

当我们需要 Cell 的高度在运行过程中发生变化时，上面单独提出 updateHeight 方法的优势就体现出来了，我们可以针对某个 Cell 单独调用 updateHeight 方法算一下高度就可以了，不需要再执行 model 数据的设置，更不需要整个 tableView 进行 `reloadData`：

```objectivec
// 这里使用通知来发送 Cell 高度需要更新的消息
// 在 Cell 的某个 subview 中 post 通知，同时把自己作为 object 传进去
// 在这里通过查找 superview 来找到 cell 实例 
- (void)handleCellUpdate:(NSNotification *)notification {
    UITableViewCell *cell = (UITableViewCell *)notification.object;
    while (![cell isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *)cell.superview;
    }
    if (cell) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        // 下面这个方法可以做到单独更新一个 Cell 的高度
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone]; 
    }
}
```

### 总结

到这里我们整理总结了一下在基于 Frame 布局时使用 FDTemplateCell 时需要注意的一些问题。这些问题大部分其实不是 FD 自己的锅，而是 Frame 布局本身的锅，如果使用 XIB 的话这些问题可能根本就不存在了。现在苹果总体也是在推动使用 XIB 布局的，在内容比较简单的情况下，XIB 相对完全基于 frame 的代码布局还是有很大优势的。 

希望这些内容对大家有帮助，如果发现错误的话，欢迎联系指正。

文章中提到的示例代码完整版在[这里](https://github.com/skyline75489/FDTemplateCell-Frame-Example)。