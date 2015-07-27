UIView Animation 学习笔记
========================

### 引言

动画一直是 iOS 开发中很重要的一部分。设计良好，效果炫酷的动画往往能对用户体验的提升起到很大的作用，在这里将自己学习 iOS 动画的体会记录下来，希望能对别人有所帮助。

iOS 的动画框架，即 CoreAnimation，本身十分庞大和复杂，这里暂时分两个部分进行介绍，分别是 UIView 动画 和 CALayer 动画。

### UIView Animation

#### 简单动画

对于 UIView 上简单的动画，iOS 提供了很方便的函数：

    + animateWithDuration:animations:
 
第一个参数是动画的持续时间，第二个参数是一个 block，在 `animations` block 中对 UIView 的属性进行调整，设置 UIView 动画结束后最终的效果，iOS 就会自动补充中间帧，形成动画。

可以更改的属性有:

* frame
* bounds
* center
* transform
* alpha
* backgroundColor
* contentStretch

这些属性大都是 View 的基本属性，下面是一个例子，这个例子中的动画会同时改变 View 的 `frame`，`backgroundColor` 和 `alpha` ：

```objective-c
[UIView animateWithDuration:2.0 animations:^{
    myView.frame = CGRectMake(50, 200, 200, 200);
    myView.backgroundColor = [UIColor blueColor];
    myView.alpha = 0.7;
}];
```

其中有一个比较特殊的 `transform` 属性，它的类型是 `CGAffineTransform`，即 2D 仿射变换，这是个数学中的概念，用一个三维矩阵来表述 2D 图形的矢量变换。用 `transform` 属性对 View 进行：

* 旋转
* 缩放
* 其他自定义 2D 变换

iOS 提供了下面的函数可以创建简单的 2D 变换：

* `CGAffineTransformMakeScale`
* `CGAffineTransformMakeRotation`
* `CGAffineTransformMakeTranslation`

例如下面的代码会将 View 缩小至原来的 1/4 大小：

```objective-c
[UIView animateWithDuration:2.0 animations:^{
    myView.transform = CGAffineTransformMakeScale(0.5, 0.5);
}];
```

#### 调节参数

完整版的 animate 函数其实是这样的：

    + animateWithDuration:delay:options:animations:completion:

可以通过 `delay` 参数调节让动画延迟产生，同时还一个 `options` 选项可以调节动画进行的方式。可用的 `options` 可分为两类：

**控制过程**

例如 `UIViewAnimationOptionRepeat` 可以让动画反复进行， `UIViewAnimationOptionAllowUserInteraction` 可以让允许用户对动画进行过程中同 View 进行交互（默认是不允许的）

**控制速度**

动画的进行速度可以用速度曲线来表示（参考[这里](http://zhuanlan.zhihu.com/cheerfox/20031427#!)），提供的选项例如 `UIViewAnimationOptionCurveEaseIn` 是先慢后快，`UIViewAnimationOptionCurveEaseOut` 是先快后慢。

不同的选项直接可以通过“与”操作进行合并，同时使用，例如:

    UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction
    
#### 关键帧动画

上面介绍的动画中，我们只能控制开始和结束时的效果，然后由系统补全中间的过程，有些时候我们需要自己设定若干关键帧，实现更复杂的动画效果，这时候就需要关键帧动画的支持了。下面是一个示例：


```objective-c
[UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionRepeat | UIViewKeyframeAnimationOptionAutoreverse animations:^{
    [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
        self.myView.frame = CGRectMake(10, 50, 100, 100);
    }];
    [UIView addKeyframeWithRelativeStartTime: 0.5 relativeDuration:0.3 animations:^{
        self.myView.frame = CGRectMake(20, 100, 100, 100);
    }];
    [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
        self.myView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    }];
} completion:nil];
```

这个例子添加了三个关键帧，在外面的 `animateKeyframesWithDuration` 中我们设置了持续时间为 2.0 秒，这是真实意义上的时间，里面的 `startTime` 和 `relativeDuration` 都是相对时间。以第一个为例，`startTime` 为 0.0，`relativeTime` 为 0.5，这个动画会直接开始，持续时间为 2.0 X 0.5 = 1.0 秒，下面第二个的开始时间是 0.5，正好承接上一个结束，第三个同理，这样三个动画就变成连续的动画了。

#### View 的转换

iOS 还提供了两个函数，用于进行两个 View 之间通过动画换场：

    + transitionWithView:duration:options:animations:completion:
    + transitionFromView:toView:duration:options:completion:

需要注意的是，换场动画会在这两个 View 共同的父 View 上进行，在写动画之前，先要设计好 View 的继承结构。

同样，View 之间的转换也有很多选项可选，例如 `UIViewAnimationOptionTransitionFlipFromLeft` 从左边翻转，`UIViewAnimationOptionTransitionCrossDissolve` 渐变等等。

### CALayer Animation 

UIView 的动画简单易用，但是能实现的效果相对有限，上面介绍的 UIView 的几种动画方式，实际上是对底层 CALayer 动画的一种封装。直接使用 CALayer 层的动画方法可以实现更多高级的动画效果。

#### 基本动画（CABasicAnimation）

CABasicAnimation 用于创建一个 CALayer 上的基本动画效果，下面是一个例子：

```objective-c
CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
animation.toValue = @200;
animation.duration = 0.8;
animation.repeatCount = 5;
animation.beginTime = CACurrentMediaTime() + 0.5;
animation.fillMode = kCAFillModeRemoved;
[self.myView.layer addAnimation:animation forKey:nil];
```

##### KeyPath

这里我们使用了 `animationWithKeyPath` 这个方法来改变 layer 的属性，可以使用的属性有很多，具体可以参考[这里](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreAnimation_guide/AnimatableProperties/AnimatableProperties.html)和[这里](http://www.cnblogs.com/pengyingh/articles/2379631.html)。

上面我们使用了 `position` 属性，注意 layer 的这个 `position` 属性和 View 的 `frame` 以及 `bounds` 属性都不相同，可以由下面的公式计算得到：

```objective-c
position.x = frame.origin.x + 0.5 * bounds.size.width；  
position.y = frame.origin.y + 0.5 * bounds.size.height； 
```

具体计算的原理可以参考[这篇文章](http://wonderffee.github.io/blog/2013/10/13/understand-anchorpoint-and-position/)。


##### 属性

CABasicAnimation 的属性有下面几个：

* beginTime
* duration
* fromValue
* toValue
* byValue
* repeatCount
* autoreverses
* timingFunction

可以看到，其中 beginTime，duration，repeatCount 等属性和上面在 UIView 中使用到的 duration，UIViewAnimationOptionRepeat 等选项是相对应的，不过这里的选项能够提供更多的扩展性。

需要注意的是 `fromValue`，`toValue`，`byValue` 这几个选项，支持的设置模式有下面几种：

* 设置 fromValue 和 toValue：从 fromValue 变化到 toValue
* 设置 fromValue 和 byValue：从 fromValue 变化到 fromValue + byValue
* 设置 byValue 和 toValue：从 toValue - byValue 变化到 toValue
* 设置 fromValue： 从 fromValue 变化到属性当前值
* 设置 toValue：从属性当前值变化到 toValue
* 设置 byValue：从属性当前值变化到属性当前值 + toValue

看起来挺复杂，其实概括起来基本就是，如果某个值不设置，就是用这个属性当前的值。


