解决 Macbook 找不到摄像头的问题
===========================

今天在用 Macbook 的过程中突然发现摄像头不好使了，具体表现就是跟没有摄像头一样，使用 QuickTime 打开屏幕录制和 FaceTime 都不好使。

在网上搜了半天，发现都是要关机重启什么的（类似[这个](http://site.douban.com/155429/widget/notes/8911817/note/265756112/)）。感觉就这么个小问题不至于需要重启吧，去 Google 用英文搜索才终于搜出来靠谱的答案（果然谷歌大法好）。

苹果官方论坛的[一个回复](https://discussions.apple.com/thread/4282533)给出了一个很简单的解决办法，打开 Terminal，在命令行里输入：

    sudo killall VDCAssistant


这一条命令就解决了我的问题了。如果不行的话，可以试试[这个网页](http://osxdaily.com/2013/12/27/fix-there-is-no-connected-camera-error-mac/)里给出的方法，多了一条命令：

    sudo killall AppleCameraAssistant;sudo killall VDCAssistant


当然重启按道理来说也应该能解决问题，不过既然有简单的方法也就没有必要祭出重启大法了。
