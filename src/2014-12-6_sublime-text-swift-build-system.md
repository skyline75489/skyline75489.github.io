使用Sublime Text 2 编译并执行Swift程序
===================================

最近稍微闲了一些，打算学习一下Swift。刚开始在Playground里打代码，虽然Playground看起来挺炫酷的，但是总是感觉一边写代码另一边会有点卡，偶尔还崩溃几次也让人挺心烦的。在命令行下是可以使用```swiftc```或者```swift```命令直接编译执行Swift代码的，但是效率实在是不高。

以前学Python的时候Sublime Text可以作为很好的轻量级IDE，因为它内置了Build系统，可以直接用快捷键编译执行Python代码。既然Python没问题，Swift想必也是OK的，

首先装一个Swift的高亮插件，没有高亮的代码实在看不下去，直接在Package Control里搜Swift第一个就可以。

然后打开Sublime Text，选择 Tools -> Build System -> New Build System，输入下面的内容

    {
	    "cmd": ["swift", "${file}"],
        "file_regex": "^(...*?):([0-9]*):?([0-9]*)",
        "path": "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/",
        "selector": "source.swift"
    }
    
把它保存为```swift.sublime-build```，重启一下Sublime，然后再打开Swift的源代码，按Ctrl(Command) + B就可以Build了，在下面的Console里可以看到执行的结果。

参考： http://www.carlosicaza.com/2014/07/04/minimalist-sublime-text-swift-build/
