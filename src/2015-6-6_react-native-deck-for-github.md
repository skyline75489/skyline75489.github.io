React Native 开发中遇到的一些坑（持续更新）
=====================================

最近尝试使用 React Native 开发了一些小项目（[Sunshine](https://github.com/skyline75489/Sunshine-React-Native) 和 [Deck](https://github.com/skyline75489/Deck)），体会到了 React Native 开发的强大之处，例如使用 flexbox 布局让 Layout 变得分外简单，更新程序不用重启模拟器，大大提高了开发效率等等。由于 React Native 尚未发布 1.0 版本，本身还并不是很成熟，在开发过程中也遇到了一些坑，在这里记录一下。

1. 升级 React Native 导致程序无法启动
    
    在从 0.4.1 版本向 0.4.2 升级的过程中，不管是使用 `npm update` 还是重新 `npm install` 都会报 `failed to parse query: unknown expression term 'dirname'` 导致 packager 无法启动，重新用 `react-native init` 创建新项目也不行。我向 React Native 官方提了 [issue](https://github.com/facebook/react-native/issues/1213)，也没有得到好的答复，反倒是路过的群众在 issue 下面提出了解决办法——重新安装 watchman:
       
    ```nohighlight
    brew uninstall watchman
    brew install --HEAD watchman
    ```
   
    亲测可行（不愧是高手在民间），看 issue 里官方的意思看样子也不打算再管这个问题了，有解决方案就得了。
   
    最近想从 0.4.4 升级到 0.5.0，不出意外也崩溃了，报找不到 `docblock.js` ，目前还没有找到解决办法，只能继续用 0.4.4 了。
   
2. props 的可变性问题

    在 `render` 方法中不能改变 props 或者 states，例如下面的代码：
    
    ```javascript
    module.exports = React.createClass({
	  handlePress: function() {
	    this.setProps({
	      id: '1',
	    });
	  }, 
	  render: function() {
	    return (
          <View>
            <TouchableOpacity onPress={this.handlePress}>
              <Text>Activity</Text>
            </TouchableOpacity>
          </View>
	    );
	  }
	});
	```

    当点击时，会报
    
    ```nohighlight   
    Error: Invariant Violation: setProps(...): 
    Cannot update during an existing state transition (such as within `render`). 
    Render methods should be a pure function of props and state.
    ```

    大体意思就是在 render 这种需要 props 和 state 进行渲染的方法中，不能再对 props 和 state 进行更新。我的理解是，React 会在 props 和 state 改变的时候调用 render 进行 DOM diff 然后渲染，如果在渲染过程中再对 props 和 state 进行更改，就陷入死循环了。
    
    
3. onPress 的正确使用姿势
    
    一般的 ListView 中每个 Row 的点击会对应一个 onPress 的事件，例如 push 到下一个 View，这种情况使用 `onPress={this.handlePress}` ，然后在 `handlePress` 里进行响应的操作就 OK 了。
    
    在显示 Github 时间线的时候，每个 Row 里会提到多个用户名和仓库名，点击用户名和仓库名时需要做不同的处理。最容易想到的方法就是给 `handlePress` 传递参数了，如果使用下面的代码：
    
    ```javascript
    var action = <View style={styles.action}>
                   <Text>{actionDescription}</Text>
                   <TouchableOpacity onPress={this.goToUser(this.props.data.name)}><Text>data.payload.member.login</Text></TouchableOpacity>
                 <Text> to </Text>
    ```
    
    点击时同样会报
    
    ```nohighlight
    Error: Invariant Violation: setState(...): Cannot update ...
    ```
    
    因为上面的写法等于是在渲染的时候执行了 `this.goToUser`，会导致 state 改变。 onPress 应该传递进一个**函数**，这个函数会在点击的时候执行。一种可行的写法是使用匿名函数封装：
    
    ```javascript
    <TouchableOpacity onPress={()=>{
      this.goToUser(this.props.data.name)
     }}>
    </TouchableOpacity>
    ```
    
    这样就不会在渲染的时候跑里面的函数，也就避免了冲突。
    
    完整的代码在[这里](https://github.com/skyline75489/Deck/blob/master/App/Components/EventRow.js#L50)。
    
    
    
4. Navigator 的 pop 方法灵异的行为

    在 [Deck](https://github.com/skyline75489/Deck)，只在 Dashboard 中进行操作，View 的 push 和 pop 都没有问题。如果进入次级 View 中，再点击 Me 进行 Tab 切换，再次回到 Dashboard 之后会发现 Back 按钮不好用了，更诡异的是，用拖拽的方式还能够正常返回。更更诡异的是，对 Me 这个 Tab 做相同的操作不会出现问题，更更更诡异的是，如果不是切换到 Me，而是切换到另两个 Tab，也不会出现问题。。。
    
    其实在点按仓库名或者用户名之后，底部的 Tab 导航应该是隐藏的，可惜这个功能现在还没有实现，有人已经提了 [issue](https://github.com/facebook/react-native/issues/1489)。
    
5. AlertIOS 导致高 CPU 占用

    在 [这里](https://github.com/skyline75489/Deck/blob/master/App/Components/RepoDetail.js#L197) 有一行 AlertIOS 弹出的消息，在我测试的过程中不知道为什么会导致程序 CPU 占用率飙涨到 100%，整个应用近乎卡死。任务监视器显示有一个 `backboardd` 进程在狂消耗 CPU，搜索了半天也没有解决方案。
    
6. 文档不完善

    React Native 的文档现在基本处于半残状态，现有的文档内容都比较少，也缺少例子，很难看懂，像 Navigator 控件，直接看文档基本是看不懂的。还有些内容文档上根本就没有，例如 ActionSheetIOS 和 AdSupport。
    
7. Navigator 中使用自定义的 NavigatorBar 
    
    在 View 直接切换需要使用 Navigator 组件。Navigator 要实现上面 navbar 保持不变，需要使用 navigationBar 属性。在 push 之前和之后，还要对其中的内容进行处理，包括改变标题，添加 Back 按钮等。
    
    以 [react-native-router](https://github.com/t4t5/react-native-router) 的代码为例，它使用了 navigationBar 属性（[看这里](https://github.com/t4t5/react-native-router/blob/master/index.js#L115)），同时写了很多代码来实现 View 之间 push 时候的[处理](https://github.com/t4t5/react-native-router/blob/master/components/NavBarContent.js#L60)，最终实现的效果很好，用起来也很方便。在 Deck 的 Dashboard 和 Me 界面中都是直接使用的 react-native-router。
    
    但是到了搜索页面，react-native-router 就玩不动了，因为我们需要高度自定义的，同时组件之间还需要互操作的 navbar。
        
    ![Search](https://raw.githubusercontent.com/skyline75489/Deck/master/Screenshots/4.png)
    
    上面的三个部件需要互相联动，例如点击左边的面包按钮改变搜索设置，需要中间的输入框的 placeholder 进行相应改变，点击右边的搜索按钮需要得到中间输入框当前的值，同时让输入框放弃焦点。另外最重要的是，在输入框提交和点击右侧的搜索按钮时，下面需要显示搜索结果。
    
    总之 navbar 三个部件以及下面的搜索结果页面之间需要互操作，四个组合成一个大的组件，可以通过 ref 在 parent 中获得它们的引用，以及把 customAction 传递进去，从而实现互操作：
    
    ```javascript
    <View style={styles.navbar}>
      <SearchOption style={[styles.corner, styles.alignLeft]} customAction={this.customAction} />
       <SearchTextInput ref="input" customAction={this.customAction} />
       <SearchIcon style={[styles.corner, styles.alignLeft]} customAction={this.customAction} />
    </View>
    <View style={styles.searchResult}>
       <SearchResult />
    </View>
    ```
    
    这样的做法实现了搜索组件的功能，但是 push 的时候又出问题了，这种做法没有使用 navigationBar，会导致 push 到下一个 View 的时候，上面就没有标题栏了。
    
    为什么不能使用 navigationBar？因为 navigationBar 要求是一个相对独立的组件，与其他组件之间应该是松耦合的，但是这里的 navbar 恰好是需要强耦合的，产生了矛盾。
    
    现在搜索页面点击下面仓库或用户名，进入到的下一个页面就是没有 Navbar 的，希望将来能有更好的解决方案。