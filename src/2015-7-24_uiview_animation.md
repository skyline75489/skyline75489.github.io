UIView Animation 学习笔记
========================

### 引言

动画一直是 iOS 开发中很重要的一部分。设计良好，效果炫酷的动画往往能对用户体验的提升起到很大的作用，在这里将自己学习 iOS 动画的体会记录下来，希望能对别人有所帮助。

iOS 的动画框架，即 CoreAnimation，本身十分庞大和复杂，这里暂时分两个部分进行介绍，分别是 UIView 动画 和 CALayer 动画。

### UIView Animation

对于 UIView 上简单的动画，iOS 提供了很方便的函数：

    animateWithDuration:delay:options:animations:completion
 
在 `animations` block 中对 UIView 的属性进行调整，设置 UIView 动画结束后最终的效果，iOS 就会自动补充中间帧，形成动画。

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

除了基本属性之外，有一个 `transform` 属性，它的类型是 `CGAffineTransform`，即 2D 仿射变换，这是个数学中的概念，用一个三维矩阵来表述 2D 图形的矢量变换。用 `transform` 属性对 View 进行：

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
 

