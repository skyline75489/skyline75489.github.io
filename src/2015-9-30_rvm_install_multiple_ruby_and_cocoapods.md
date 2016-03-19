使用 RVM 安装多个版本的 Ruby 以及 CocoaPods
=======================================

因为工作原因，需要使用旧版本的 CocoaPods。而想使用 Swift 的话，又必须要用 0.38 以上版本的 CocoaPods 。为了能同时使用两个版本的 CocoaPods 而不产生冲突，可以使用 rvm 再安装一个 ruby，这样就可以在系统 ruby 里安装一个 CocoaPods，在 rvm 的 ruby 里安装另一个版本，这样就可以使用 rvm 切换 ruby 版本来无缝切换两个版本的 CocoaPods 了。

### 安装 rvm

安装 rvm 相对来说比较简单，官方提供了一个脚本可以直接安装

```no-highlight
curl -sSL https://get.rvm.io | bash -s stable
```

但是 `rvm.io` 这个网站有被墙的感觉，如果发现这个脚本执行半天还没反应，估计就是网络环境的问题了。可以科学上网之后把这个脚本下载下来，然后再执行。

### 安装 ruby

安装 ruby 本来也应该比较简单，只需要执行一个命令:

```no-highlight
rvm install 2.2.3
```

但是执行过程中却出现了：

```no-highlight
Searching for binary rubies, this might take some time.
No binary rubies available for: osx/10.10/x86_64/ruby-2.2.1.
Continuing with compilation. Please read 'rvm help mount' to get more information on binary rubies.
```

看这意思是没有找到二进制的包，要是自己下源码编译的话，恐怕要花挺长时间了。为什么它找不到二进制的包呢？在网上查了一下资料，知道 rvm 是在 `~/.rvm/config/remote` 中找二进制包的，打开这个文件，里面的内容类似这样：

```no-highlight
https://rvm_io.global.ssl.fastly.net/binaries/amazon/2013.03/x86_64/ruby-1.9.3-p448.tar.bz2
https://rvm_io.global.ssl.fastly.net/binaries/amazon/2013.03/x86_64/ruby-2.0.0-p247.tar.bz2
https://rvm_io.global.ssl.fastly.net/binaries/arch/libc-2.15/x86_64/ruby-1.9.3-p194.tar.bz2
https://rvm_io.global.ssl.fastly.net/binaries/arch/libc-2.15/x86_64/ruby-1.9.3-p286.tar.bz2
https://rvm_io.global.ssl.fastly.net/binaries/arch/libc-2.15/x86_64/ruby-1.9.3-p327.tar.bz2
```
	
一看 fastly 就秒懂了，这些地址也是被墙了，导致 rvm 找不到二进制包。

能不能安装本地的包呢？也是可以的，答案就在上面提示的 `rvm mount` 命令中。我们可以先把二进制包下载到本地，然后通过 `rvm mount` 命令安装。

首先用科学上网的方法把二进制包下载下来（除了上面的地址，还可以去 https://rvm.io/binaries/ ），然后使用 

```no-highlight
rvm mount ~/Downloads/ruby-2.2.3.tar.bz2
```

这样就可以安装成功了。更多关于 mount 命令的使用，可以参考[这篇英文博客](http://syntaxi.net/2012/12/21/installing-binaries-in-rvm/)

### 切换 ruby 版本

上面的步骤完成之后，就可以通过 rvm 来切换 ruby 版本了：

```bash
rvm use system # 使用系统 ruby
rvm use 2.2.3  # 使用 rvm ruby
```

 在切换 ruby 版本之后，gem 也会跟着切换，我们就可以安装两个版本的 CocoaPods 了。
