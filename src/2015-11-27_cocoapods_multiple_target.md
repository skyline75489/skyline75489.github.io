使用 CocoaPods 管理多个 Target 的依赖
====================================

CocoaPods 是常用是 iOS 依赖管理工具。默认情况下 CocoaPods 会把依赖安装到主的 Target 上：

```ruby
platform :ios, '5.0'

pod 'Quick', '0.5.0'
pod 'Nimble', '2.0.0-rc.1'
```

如果我们需要给多个 target 设置依赖的话，有两种办法，第一种是给每个 target 都写一遍依赖：

```ruby
platform :ios, '5.0'
target 'MyTests' do
    pod 'Quick', '0.5.0'
    pod 'Nimble', '2.0.0-rc.1'
end

target 'MyUITests' do
    pod 'Quick', '0.5.0'
    pod 'Nimble', '2.0.0-rc.1'
end
```

这样可以精确控制每个 target 的依赖。当各个 target 共享的依赖比较多的情况下，这样写会导致很多重复。

第二种做法是使用 `link_with` 来指定多个 target:

```
platform :osx, '10.7'

link_with 'MyApp', 'MyApp Tests'
pod 'AFNetworking', '~> 2.0'
pod 'Objection', '0.9'
```

这种写法不需要我们一个依赖写很多遍了，但是又不能精确控制每个 target 具体的依赖，如果有些依赖是不能共享的，这种写法就会引起问题。

例如在 App Extension 开发中，Extension 和主 App 是两个 target，有些依赖在主 App 中是需要的，但是可能并不支持 Extension ，因为 Extension 中不能使用 UIApplication 之类的 API，这样如果我们用 `link_with` 的写法就会导致 Extension 编译不通过。

可以看到上面两种写法都有局限性，这里介绍一种更好的写法。因为 Podfile 其实就是合法的 Ruby 源代码，我们可以在 Podfile 中直接使用 Ruby 的语法。对于上面提到的 Extension 的情况，我们可以这样做：

```ruby
def shared_pods
	pod "AFNetworking"
	pod "SDWebImage"
	
def app_only_pods
	pod "MBProgressHUD"
	
target :app do
	shared_pods
	app_only_pods
	
target :keyboard do
	shared_pods
```

我们利用了 Ruby 的函数，定义出了两个 target 可以共享的依赖，以及只能在 App 中使用的依赖，然后通过函数调用去给 target 设置依赖，这样既解决了重复问题，又能精确控制每个 target 的依赖。


参考资料：

* https://stackoverflow.com/questions/14906534/how-do-i-specify-multiple-targets-in-my-podfile-for-my-xcode-project
* http://natashatherobot.com/cocoapods-installing-same-pod-multiple-targets/
* http://www.tuicool.com/articles/e6VrieN
* https://guides.cocoapods.org/using/the-podfile.html
