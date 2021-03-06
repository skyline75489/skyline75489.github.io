使用 CocoaPods 集成环信 3.0
=========================

环信是一个很常用的第三方 IM 解决方案。现在的环信 SDK 提供了两个版本，一个是 2.0 ，一个是 3.0。官方对于 2.0 版本提供了使用 CocoaPods 集成的支持，具体的 Podfile 如下：

```ruby
pod 'EaseMobSDKFull', :git => 'https://github.com/easemob/sdk-ios-cocoapods-integration.git'
pod 'EaseUI', :git => 'https://github.com/easemob/easeui-ios-cocoapods.git'
```

对于 3.0 版本来说，EaseUI 的部分官方并没有提供 CocoaPods 的 podspec。手动添加依赖的方法太过繁琐，也不利于维护。为了方便，笔者手动创建了 EaseUI 3.0 版本的 podspec，并托管在了 Coding 上。使用 3.0 版本的 Podfile 如下：

```ruby
pod 'HyphenateFullSDK', :git => 'https://github.com/easemob/hyphenate-full-cocoapods.git'
pod 'EaseUI', :git => 'git://git.coding.net/skyline75489/EaseUI.git'
```

亲测可用正常工作，希望能对读者有所帮助。