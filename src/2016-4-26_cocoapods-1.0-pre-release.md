拥抱 CocoaPods 1.0
==================

CocoaPods 作为 iOS 社区应用最广泛的依赖管理工具，终于要发布 1.0 版本了。虽然我没有找到具体的 roadmap，不过现在已经发布到 1.0.0 Beta8 了，距离正式版应该也就是几个 Beta 或者 rc 的问题了。尽管 CocoaPods 早就已经成了事实上 iOS 界依赖管理的标准，开发者们还是很谦虚的表示 1.0 版本才是真正实现了一个依赖管理工具的所有需求。

>1.0.0 will be the milestone where we feel confident that all the basic requirements of a Cocoa dependency manager are fulfilled.

这句话在 CocoaPods 的 FAQ 里存在了许多年，现在这个目标终于近在眼前了。

下面进入正题，CocoaPods 的 1.0 版本出现了很多改变，有一些是 breaking changes，官网上的 [Migration Guide](http://blog.cocoapods.org/CocoaPods-1.0/) 里面有很全面的介绍。我把其中感觉比较重要的几点在这里说明一些，辅以我自己的一些使用经验，希望对读者有所帮助。

#### Podfile 语法改变

这部分改变差不多是最直接的了，有几个改变会直接让现在已有的 Podfile 不能工作：

1. 必须指明 `target`

   我自己就经常图省事把 `target` 省略掉，看来今后这个地方要改变习惯了。
   
2. `:exclusive => true` 和 `link_with` 被去掉了

   因为有了 `abstract_target` 这个特性，可以让我们重用一个 target 里的 Pods，加上上面必须指明 target 的要求，这两个选项存在的意义就不大了。在我[之前的文章](https://skyline75489.github.io/post/2015-11-26_cocoapods_multiple_target.html)里提到过可以用函数来实现 pod 的重用，现在又有了一种新的方法。下面是官网的例子：
   
   ```ruby
   # Note: There are no targets called "Shows" in any       Xcode projects
   abstract_target 'Shows' do
     pod 'ShowsKit'
     pod 'Fabric'

     # Has its own copy of ShowsKit + ShowWebAuth
     target 'ShowsiOS' do
       pod 'ShowWebAuth'
     end

     # Has its own copy of ShowsKit + ShowTVAuth
     target 'ShowsTV' do
       pod 'ShowTVAuth'
     end 
   end
   ```
   
3. `xcodeproj` 被重命名成 `project`。
4. `:local` 被去掉了，现在想使用本地的 pod 只能使用 `:path`。

#### CocoaPods 行为改变

