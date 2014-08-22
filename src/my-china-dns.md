我的DNS解决方案
=============


在中国这片神奇的土地上，网络自由是如此的可遇不可求。连DNS解析这样一个基础服务，都变成了网络封锁的目标。各种DNS劫持，污染，让人烦不胜烦。于是我开始寻找一个不受别人监视的，自由的DNS解决方案。

仅仅是改DNS地址已经不能满足我们的需求了。使用国内的114.114.114.114，国外地址的解析肯定不靠谱，使用OpenDNS这类国外DNS的话，国内的地址又会变得很慢。所以我们需要自己在本机搭建一个DNS服务器，它能够根据我们的配置，将不同的请求发送到不同的地址去，确保不管是国内还是国外的地址都能得到正确而且快速的解析结果。

感谢[DNSMasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)和[DNSCrypt](http://dnscrypt.org/)，想达到这样的效果并不是太困难。这个解决方案的原理是，把请求发给DNSMasq，DNSMasq根据请求的地址，判断将DNS请求发送到哪里，如果是国外的地址，将会通过DNSCrypt解析，防止DNS污染，如果是国内的地址，就交给114DNS。同时，由于DNSMasq可以进行缓存，哪怕通过DNSCrypt解析的速度比较慢，或者不稳定，我们的解析速度也不会受到太大的影响。

在Mac OS X上进行配置具体的步骤来自这里 https://gist.github.com/ahmozkya/8456503 ，根据这个Gist和查到的其他博文，我在这里总结一下具体的步骤（Linux用户可以自行查询一下有关资料，原理是一样的，只是某些步骤因为系统原因有差异）：

### 1.安装DNSMasq和DNSCrypt

使用 Homebrew 安装

```
$ brew install dnsmasq
$ brew install dnscrypt-proxy
```

装DNSMasq的时候这一步问题不大，但是安装DNSCrypt的时候，我发现DNSCrypt已经被墙了。没办法，只能先使用Wallproxy翻出去，把源码下载下来，然后在Downloads目录用```python -m SimpleHTTPServer```开一个本地服务器，然后再使用```brew edit dnscrypt-proxy```把Formula里的下载地址改成本地的地址，然后再执行install，才把DNSCrypt安装上。

### 2.配置

   这个部分是最麻烦的，因为需要根据地址不同，把国内地址和国外地址区分对待。幸亏有好心人做了一些工作，极大的减少我们的工作量。   https://github.com/felixonmars/dnsmasq-china-list 这个项目维护了一份中国地区大部分网站的地址。这个列表来可以帮助DNSMasq判断应该把DNS请求发向哪里。我们先要把里面的两个配置文件下载下来，创建 /usr/local/etc/dnsmasq.d 文件夹，把两个配置文件放到里面。

配置DNSMasq，修改 /usr/local/etc/dnsmasq.conf

```
# 不读取有关解析的配置文件，默认使用/etc/revolve.conf中的上游服务器地址进行解析
# 这里我们把地址直接写在配置文件里，所以不需要这个了
no-resolv
# 不检查有关解析的配置文件更新（原因同上）
no-poll
# 配置文件路径，加载dnsmasq-china-list的那两个配置文件
conf-dir=/usr/local/etc/dnsmasq.d
# 附加Hosts文件，可有可无，我觉得以后可能还是需要用到Hosts，就加入了这一行
addn-hosts=/usr/local/etc/dnsmasq.hosts
# 上游服务器设置成DNSCrypt
server=127.0.0.1#40
# 缓存大小，默认是150，调大点应该没坏处
cache-size=2000
# 启用DNSSEC代理，应该能增强安全性吧
proxy-dnssec
# 可以自行参照man dnsmasq里的内容继续添加别的参数
```

配置DNSCrypt，上面提到的Gist里把配置写在了 /Library/LaunchDaemons/homebrew.mxcl.dnscrypt-proxy.plist。可能是我安装的时候有问题，我没找到这个文件。经我自己的测试发现，使用launchctl启动DNSCrypt可能会出现DNSCrypt不停重启的情况。所以我们直接在后面使用命令行参数启动DNSCrypt。


### 3.启动服务

执行下面的命令可以启动DNSCrypt

```
$ sudo /usr/local/sbin/dnscrypt-proxy --local-address=127.0.0.1:40 --edns-payload-size=4096 --user=nobody --resolver-address=77.66.84.233:443 --provider-name=2.dnscrypt-cert.resolver2.dnscrypt.eu --provider-key=3748:5585:E3B9:D088:FD25:AD36:B037:01F5:520C:D648:9E9A:DD52:1457:4955:9F0A:9955 --daemonize

```

参数里面比较重要的有--local-address，使用的端口号是40，也就是我们上面DNSMasq的上游地址。还有那三个解析服务器相关的值，那个Gist里使用的是OpenDNS的地址，我感觉OpenDNS太出名，容易被封，就在 https://github.com/jedisct1/dnscrypt-proxy/blob/master/dnscrypt-resolvers.csv 里随便挑了一个能Ping通的。我试了几个，Ping值都在300，400毫秒左右，反正有缓存，查询速度慢点也没什么关系。daemonize表示以Daemon的方式启动，可以先不加这个参数试一下能不能正确启动，如果可以再加上它。


然后启动DNSMasq并清除系统DNS缓存

```
$ sudo launchctl stop homebrew.mxcl.dnsmasq
$ sudo launchctl start homebrew.mxcl.dnsmasq
$ sudo killall -HUP mDNSResponder
```

然后就可以查询一下，看看效果了

```
$ nslookup www.facebook.com
Server:		127.0.0.1
Address:	127.0.0.1#53
Non-authoritative answer:
www.facebook.com	canonical name = star.c10r.facebook.com.
Name:	star.c10r.facebook.com
Address: 31.13.90.17
```

查询结果已经不是那个诡异的韩国地址了。第一次查询用的时间会比较长，之后由于缓存，在一定时间内查询会很快。另外，浏览器可能会对DNS进行缓存，启动DNSMasq之后推荐清空浏览器的DNS缓存。

### 4.总结

   虽然安装配置这些步骤有些复杂，但是结果还是比较令人满意的，Gmail和Dropbox一下子就好用了，再也不用担心DNS被劫持了，也能起到一定的翻墙效果（可以直接用HTTPS上Facebook和Youtube）。如果你也有希望有一个更干净的DNS查询结果，希望这篇文章对你有所帮助。
