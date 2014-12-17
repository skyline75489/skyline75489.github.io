SimpleDNS——又一个DNS代理服务器
===========================

上一篇介绍了如何使用Dnsmasq和DNSCrypt在本机搭建干净无劫持的DNS服务器，我本来以为是很好的解决方案了。后来我发现Dnsmasq本身不能更改缓存存在的时间，导致缓存的效果并不明显，还是要经常向上游服务器发请求，导致解析速度不够理想。于是我在Dnamasq和DNSCrypt中间又加了一层pdnsd，专门用于缓存。为了得到正确地DNS解析结果需要同时跑三个程序，让我感觉很不爽。我就开始在网上找其他的解决方案。

我找到了[ChinaDNS](https://github.com/clowwindy/ChinaDNS)和[fqdns](https://github.com/fqrouter/fqdns)。他们解决DNS污染的思路是，将GFW返回的假冒记录忽略掉，这个思路比我之前想方设法得到正确的结果来的简单多了，不过局限性也很明显，需要维护一个GFW的假冒地址列表。还好GFW那帮人看起来也挺懒的，来回来去就用那么几个地址，一时半会儿应该不会怎么变化。

ChinaDNS支持的功能比较少，fqdns支持的功能多一点（国内域名使用国内DNS解析，强制TCP等）。但是有些我想要的功能它们都没有，比方说我很喜欢Dnsmasq的address和server规则，可以很灵活的根据地址配置不同的DNS服务器，还有pdnsd的根据min-ttl设置缓存时间的功能。等那两个项目的作者开发出来看起来是不现实了，于是我就自己用Twisted框架写了一个[SimpleDNS](https://github.com/skyline75489/SimpleDNS)，它支持了这些功能，同时由于使用了Twisted框架，保证了代码的轻巧和灵活性。它是我现在的DNS解决方案。


PS：在中国想好好上个网实在太费劲了

PPS：折腾了半天，还是Hosts大法好啊
