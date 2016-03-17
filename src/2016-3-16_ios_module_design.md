浅析 iOS 应用组件化设计
====================

这几天深入地阅读了 casatwy 老师的[iOS应用架构谈 组件化方案](http://casatwy.com/iOS-Modulization.html)，以及蘑菇街的 limboy 所分享的[蘑菇街 App 的组件化之路](http://limboy.me/ios/2016/03/10/mgj-components.html)，还有念纪的[模块化与解耦](http://blog.cnbluebox.com/blog/2015/11/28/module-and-decoupling/)，对于组件化这个概念有了一些新的理解。这几篇文章都有一定的深度，对于初学者来说理解起来有些难度。在这里试着从初学者的角度探讨一下有关组件化的问题，供读者参考。

### 为什么要做组件化

对于个人开发的项目来说，应用的架构通常就体现在 Xcode 项目的目录结构上，关于这部分也有很多文章提到。但是对于公司团队开发的大型项目来说，仅仅在 Xcode 目录这个层次进行分层已经是不够的了。不管你的目录是以业务进行划分还是以 M-V-C 三个部分进行划分，当业务量非常大（成百上千）的时候，你会发现，想找到某个具体业务的某部分代码简直是大海捞针。同时，由于所有文件都在一个 Project 里面，如果开发人员不注意的话，很容易出现头文件各种互相 include，产生各种混乱的依赖关系。

这时就需要引入多项目开发了，把不同的业务分解成不同的子项目，在主工程内引入子项目。这样我们等于在 `目录-文件` 的基础之上增加了一个层次，变成了 `子项目-目录-文件`，增加了一个层次类似于增加了一级索引，可以让我们方便地对项目进行拆分，整个项目的结构层次也更加清晰了。

### 怎么做组件化

上面提到了，做组件化首先要把文件拆分到各个模块当中去，这里具体怎么拆，也有很多可以谈的内容。

以蘑菇街为例，使用 CocoaPods 来做这件事的话，我们可以拆到主工程可以一行代码都没有，只有一个 Podfile，类似于下面这样：

```ruby
pod 'MGJiPhone-Foundation'
pod 'MGJiPhone-Hybrid'

pod 'MGJiPhone-Detail'
pod 'MGJiPhone-Me'
pod 'MGJiPhone-Shop'
# ...
```

在最理想的情况下，这些子工程直接应该只存在上层到下层的依赖，即业务模块对底层基础模块的依赖，业务工程之间尽可能不出现横向依赖。从 limboy 的描述来看，蘑菇街各个子模块是可以单独编译出东西来的，这说明各个子模块之间的横向依赖已经很少，证明子模块之间的拆分已经比较成功了。

理想很丰满，现实很骨感。在我们对一个工程开刀的过程中，会发现事情远没有那么简单。继续以蘑菇街 App 为例，例如我们想拆分 Detail 模块（即商品详情模块），Detail 模块中可能包含了下面诸多依赖：

```objectivec
#import "MGJShopViewController.h"
#import "MGJShopRequest.h"
#import "MGJUser.h"
#import "MGJCart.h"
#import "MGJFoundation.h"
#import "MGJWebViewController.h"
#import "MGJHybridAPI.h"
```

为什么会出现这么多依赖？因为 Detail 模块本身的业务就需要涉及到和多个不同模块之间进行交换，例如从用户模块获得用户的信息，当用户购物时和购物车模块进行交互，展示商品内容时和 Web 和 Hybrid 模块进行交互等等。这是业务本身决定的，我们没办法改变。我们所能做的是尽可能地减少**横向**的依赖。

上面也提到了横向依赖这个概念。这里说明一下，业务模块没有依赖是不可能的，我们希望做到的是，它只依赖那些底层的基础模块，而不依赖于和它同级的业务模块。

#### 基础依赖

哪些模块算是底层的基础依赖？一个判断的办法就是，看这个部分的代码是不是稳定的。最常见的基础依赖，包括稳定的三方库，底层网络通信模块，常用的 category 等等。这些代码不会频繁改动，可以作为基础依赖。

基础依赖在保持稳定的基础之上，还需要做到高复用性和单一职责性。这就要涉及到大家经常会去做的一件事了——创建一个 Common 模块。Common  模块可能会存一些常用的 category，helper，utils 等等东西：

```ruby
pod 'MGJiPhone-Common'
```

最开始的时候这么做会显的很方便，但是随着项目规模的增长，整个 Common 模块最终会成为依赖管理的噩梦。Common 本身作为一个模块集各种依赖于一身，缺乏内部的横向解耦，导致其整体的复用性非常差，简直是剪不断理还乱。因此最好一开始就避免创建 Common 模块，让每个模块都保持尽量少的职责：

```ruby
pod 'MGJiPhone-Location'
pod 'MJGiPhone-Device'
pod 'MGJiPhone-NSStringCategory'
pod 'MGJiPhone-NSDateCategory'
```

#### 横向依赖

把基础模块拆分完之后，下面需要对业务模块之间横向的依赖进行拆解。这部分是比较难也是容易碰到问题的。我在之前的博文[浅析 iOS 开发中 VC 之间数据传递的方式](https://skyline75489.github.io/post/2015-12-20_ios_vc_data_exchange.html)中提到过，对于两个模块之间的 vc 常见的 push 操作：

```objectivec
LanguageViewController *vc = [[LanguageViewController alloc] init];
vc.selectedIndex = self.currentSelectedIndex;
[self.navigationController pushViewController:vc animated:YES];
```

可以通过引入 Router 来去除对于 vc 类的强依赖：

```objectivec
// 注册
[[HHRouter shared] map:@"/lang/:index/" toControllerClass:[LanguageViewController class]];

// 获取
UIViewController *vc = [[HHRouter shared] matchController:@"/lang/1/"];
[self.navigationController pushViewController:vc animated:YES];
```

这种办法不仅可以用于 Controller，用于普通的对象也是可以的。Router 可以自动取得对应的类，并进行实例化。对于不需要实例化的模块来说，蘑菇街的解决办法中引入了 `ObjectHandler`：

```objectivec
[MGJRouter registerURLPattern:@"mgj://cart/ordercount" toObjectHandler:^id(NSDictionary *routerParamters){
    // do some calculation
    return @42;
}]
```

以及面向接口思想的 `ModuleManager`，做到了依赖于接口(protocol）而不依赖于实现。

以我浅薄的开发经验看来，基于 Router 的这种解决方案已经能处理大部分情况了，参考 HHRouter 我写过一个 Swift 版的 [SwiftRouter](https://github.com/skyline75489/SwiftRouter)，也获得了一些认可。说明大部分人还是认可这种解耦方式的。再加上 `ModuleManager` 这种面向接口的模块管理工具（代码实现可以参考念纪的 [AppLord](https://github.com/NianJi/AppLord)），如果用的好的话，已经能够把整个代码的依赖拆分的比较清楚了。

然而 casa 老师对蘑菇街的解决方案提出了批评，蘑菇街的解决方案主要存在下面几个问题：

1. 基于 URL 的方案无法表达非常规对象
   
   由于 URL 本身的限制，对于 UIImage 这种不容易序列化成文字的参数来说，是不容易作为参数传递的。这一点我也有所体会，其实岂止是 UIImage 这种，哪怕是普通的文本，如果含有一些特殊的 URL 字符的话（`/ ，？,=`）都会导致 Router 对于参数的解析发生错误。一个可行的解决办法是像浏览器那样，在发送端进行 URL Encode，接收端进行 URL Decode，无形中增加了调用的成本。
   
2. URL 注册使得可维护性下降

   由于注册 URL 的过程仍然需要在主工程当中操作，在新增或删除业务时，需要持续地对 URL 进行维护。从 limboy 的博文中可以看到，蘑菇街还专门有一个后台用来管理可用的 URL entry，确实是有维护成本比较高的问题。
   
3. 最根本的，思想上的错误，没有区分远程调用和本地调用，同时本末倒置地以远程调用的方式为本地间调用提供服务

   首先讲一下什么叫远程调用。大家之所以在 iOS 中使用基于 URL 的方法，一部分原因是 URL 本身的特性，另一部分是 iOS 提供的应用间通信方式也是基于 URL 的，即 `[[UIApplication sharedApplication] openURL:]`。因此当 App 内使用 URL 做通信时，对于外部的 URL 请求也可以方便地进行处理。
   
   蘑菇街在应用内部也使用了 URL 进行导航，也就是“以远程调用的方式为本地间调用提供服务”。在应用内的调用本身是可以直接进行的，传递参数也没有问题。但是蘑菇街本末倒置的做法，导致了上面提到的参数传递的问题。
   
   对于外部调用来说，本身就不太可能出现传递非常规对象的情况，因此使用 URL 方案是没有问题的。
   
   
同时，casa 老师自己提出来基于 target-action 的 Mediator 解耦方案，其设计的核心有下面几点：

1. 基于 Runtime 来实现动态调用，避免模块注册，同时也避免产生反向依赖
2. 通过 Category 暴露出更友好的接口，避免参数的构造和传递
3. 在 target-action 之上构建 openURL 的处理


这套方案差不多是我目前为止看到的最优秀的解耦方案了，从中可以看到作者很多的积淀和思考。有关它具体的一些探讨请移步[博文](http://casatwy.com/iOS-Modulization.html)和[代码仓库](https://github.com/casatwy/CTMediator)。

关于它的好处我就不说了，下面说一下我感觉有些问题的地方：

1. 学习成本高
   
   限于自己水平不够，老实说整个架构我看了好久才看明白其核心在哪儿。对于经验不足的开发者来说，想理解这套架构和背后的设计思想有一定难度，更不用说使用了。
   
2. 对各端协作要求很高

   由于整个架构核心是基于 Runtime 的，这也就要求前后台对于 URL 的规则一定是统一的。如果只有 iOS 端还好，对于蘑菇街来说，同样的 URL 规则对于安卓端可能意味着更高的维护成本（如果安卓端也有类似 Runtime 的机制那倒还好说）。
   
3. 采用 Runtime 机制可能会出现类没有被加载的情况

   整个架构对于 Target 部分没有显式的依赖，有可能会在试图通过 `NSClassFromString` 获取类时，对应的 Target 类还没有加载到 runtime 中。这个属于吹毛求疵了，大家看看就好。

### 组件化的优缺点

说了这么多，为了实现组件化折腾这么半天真的值得吗？首先我们来看下组件化有哪些优点：

* 简化了代码整体结构，降低了维护成本。
* 为代码和模块的复用提供了基础，假如蘑菇街要开发 iPad 客户端，可以想象大部分底层模块可以直接复用 iPhone 端原有的代码。
* 对不同的业务模块可以进行物理隔离（通过 git 仓库权限控制），进一步提升代码的稳定性。
* 极大地提升了整体架构的伸缩性，为将来的业务扩展打下了基础。

当然，组件化也有一些缺点：

* 学习成本高，对于开发人员对各种工具的掌握要求也比较高，对于新手来说入门较为困难。
* 由于工具和流程的复杂化，导致团队之间协作的成本变高，某些情况下可能会导致开发效率下降。

然而长远来看，组件化带来的好处是远远大于坏处的，特别是随着项目的规模增大，这种好处会变得越来越明显。


    
   
