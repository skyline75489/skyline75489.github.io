pod install 和 pod update 的区别（译）
===================================

原文： https://github.com/CocoaPods/CocoaPods/issues/760#issuecomment-46300500

### pod install

每次在 Podfile 中增加或者删除一个 pod  之后，应该使用 pod install。

* 执行 `pod install` 的时候，它会下载并且安装新的 pod，将安装的 pod 信息写入 `Podfile.lock`。这个文件主要是用来跟踪已经安装的 pod 并且锁定（lock）它们的版本。

* 执行 `pod install` 的时候，它会对那些**不**在 `Podfile.lock` 中的 pod 进行依赖分析

    * 对于已经在 `Podfile.lock` 中的 pod，它会下载在 `Podfile.lcok` 中指示的版本，不会去检查有没有新版本。

    * 对于没有出现在 `Podfile.lock` 中的 pod，它会搜索符合 `Podfile` 中要求的版本（例如 `pod 'MyPod', '~>1.2'`）

### pod outdated

当执行 `pod outdated` 的时候，CocoaPods 会在已安装的 Pod 中（出现在 `Podfile.lock` 中）找出所有有新版本可用的 Pod，这些 pod 在满足 `Podfile` 中要求的情况下，可以被更新（例如 `pod 'MyPod, '~>x.y'`。

### pod update

当你执行 `pod update SomePodName` 的时候， CocoaPods 会试着找到一个更新的 `SomePodName`，不会理会已经在 `Podfile.lock` 中已经存在的版本。在满足 `Podfile` 中对版本的约束的情况下，它会试图把 pod 更新到尽可能新的版本。

如果你只执行 `pod update` 后面没有跟任何 pod 的名字，CocoaPods 会把 `Podfile` 中所有列出的 pod 都更新到尽可能新的版本。

### 用法

使用 `pod update SomePodName`，你可以只更新一个 pod（检查新版本，并且更新）。 `pod install` 不会试图查找一个已经安装的 pod 的新版本。

通常情况下，当你在 `Podfile` 中添加了新 pod，你应该使用 `pod install`，而不是 `pod update`。这样你可以只安装新的 pod ，不会同时把已经存在的 pod 也更新掉。

只有当你想更新某个或者全部 pod 时，你才应该使用 `pod update`。

更详尽的描述可以参考官方的 [Guide](http://guides.cocoapods.org/using/pod-install-vs-update.html)。