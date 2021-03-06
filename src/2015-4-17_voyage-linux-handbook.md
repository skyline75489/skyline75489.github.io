Voyage Linux 虚拟机安装手记
=========================

尽管 Mac 的 Unix 内核让 Mac 和 Linux 在命令行的体验上几乎一模一样，但是有些时候还是避免不了需要 Linux 环境，比如需要编译某些只以 Linux 为 Target 的程序。如果没有别的空闲电脑的话，最好的解决方法就是使用虚拟机了。因为我们还是在使用 Mac 的桌面，实际上我们不需要 Linux 有桌面环境，仅仅是需要有一个纯的 Linux 环境就可以了。因此我们没必要选择笨重的 Ubuntu 桌面版。Ubuntu Server 版是个不错的选择，但是对于我来说还是不够精简。Arch Linux 可以做到很精简，但是安装起来又太折腾。在网上找了一些资料之后，我发现 Voyage Linux 正好可以满足我的需求。


### 简介

[Voyage Linux](http://linux.voyage.hk/) 是一个基于 Debian 的 Linux 发行版，主要面向 x86 嵌入式设备。它十分小巧，镜像仅仅 65M 大小，全新安装完也只有几百兆。同时它对系统配置的要求也比较低，虚拟机分配一个 CPU + 256MB 内存完全足够了，不会太耗费资源。另外它是基于 Debian 的，因此可以使用 Debian 的源和熟悉的 apt-get 来安装软件。基本上可以看成是精简版的 Ubuntu Server。

Voyage Linux 提供了面向嵌入式设备的系统 tar 包，应该是直接刻到设备存储里就能用。因为要用虚拟机，所以要从[这里](http://linux.voyage.hk/live-cd)下载一个 Live CD 的镜像，我使用的是 voyage-0.9.5.iso，基于 Debian Wheezy。使用虚拟机加载这个镜像就可以启动了。


### 安装和配置

在 Voyage 的官网上[这里](http://linux.voyage.hk/content/getting-started-live-cd-v09x) 提供了完整的安装教程，按照程序提示一步一步选择就可以完成安装。需要注意的是，在选择安装类型那一步，我选择的是 Generic PC，因为其他选项基本都是嵌入式设备。安装完成后，弹出镜像，重启机器，就可以进入全新的 Voyage Linux 系统了。

Voyage 安装好之后自己就已经配置好 SSH 的 Server 了，因此我们可以从 Mac 的终端直接 SSH 过去，使用 root 用户，默认密码 voyage 登陆虚拟机，虚拟机窗口直接最小化就行了。

登陆进去之后就可以开始配置了。在配置之前，有一个比较严重的问题，由于 Mac 使用的是 SSD，Voyage Linux 就被安装到了闪存设备上，它的默认配置是在闪存设备上启动时，默认使用只读加载文件系统，因此我们不能修改任何文件，系统基本就是废的。官网上[这个页面](http://wiki.voyage.hk/rw_ro.txt) 提供了解决方案：

首先执行

```nohighlight
remountrw
```
 
以读写模式加载文件系统，不然我们没办法修改配置文件，然后找到 `/etc/init.d/voyage-util`，在 110 行左右有类似如下的代码：

```nohighlight
echo -n "Remounting / as read-only ..."
/usr/local/bin/remountro
echo "Done."
```

这段代码就是用来将文件系统挂载成只读的，将它注释掉，下次启动时系统就变成可读写的了。

接下来我们可以开始配置这个虚拟机环境，在配置之前建议新建一个普通用户，不要直接使用 root 用户。之后和 Ubuntu 一样，进行配置开发环境，修改软件源等操作。在配置 git 的过程中我遇到了一些坑，顺便在这里也记录一下。

Debian Wheezy 主仓库里的 Git 版本是 1.7 的，已经有些老了，可以在 `sources.list` 里加入：

```nohighlight
deb http://http.debian.net/debian wheezy-backports main
```

然后使用

```nohighlight
sudo apt-get wheezy-backports install git
```

来安装比较新的版本，我装上的版本是 1.9.1

使用 `git clone` 时可能会报 `Permission Denied(Public Key)`，如果使用的是 HTTPS， 有可能是因为没有安装必要的证书，需要使用下面的命令来安装证书：

```nohighlight
sudo apt-get install ca-certificates
```

如果使用的是 SSH，有可能是没有正确配置 SSH。根据 [Github 的帮助文档](https://help.github.com/articles/error-permission-denied-publickey/) 对 SSH 进行配置。核心的步骤就是使用 `eval "$(ssh-agent -s)"` 启动 ssh-agent，然后使用 `ssh-add` 添加证书。
    
    
### 总结

使用 PD9 安装好的虚拟机，整个虚拟机大小只有 1.4G 左右，相比之下 Ubuntu 桌面版和 Ubuntu Server 版装好之后大概占 7G 的空间。可以说 Voyage Linux 是非常精简了，在配置好环境之后，使用体验和 Ubuntu Server 基本上一样的。我个人感觉，Voyage Linux 作为小型的服务器操作系统，应该也是没有什么压力的，作为虚拟机实在是有点大材小用了。如果你发现了更精简，更方便的 Linux 虚拟机解决方案，欢迎随时联系我。