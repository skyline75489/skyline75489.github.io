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
    
#### View 的转换

iOS 还提供了两个函数，用于进行两个 View 之间通过动画换场：

    + transitionWithView:duration:options:animations:completion:
    + transitionFromView:toView:duration:options:completion:

需要注意的是，换场动画会在这两个 View 共同的父 View 上进行，在写动画之前，先要设计好 View 的继承结构。

同样，View 之间的转换也有很多选项可选，例如 `UIViewAnimationOptionTransitionFlipFromLeft` 从左边翻转，`UIViewAnimationOptionTransitionCrossDissolve` 渐变等等。

### CALayer Animation 

UIView 的动画简单易用，但是能实现的效果相对局限，CALayer 可以实现更多高级的动画效果。