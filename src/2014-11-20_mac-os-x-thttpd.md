Mac OS X上编译thttpd
===================

[thttpd](http://acme.com/software/thttpd/)是我偶尔在网上闲逛找到的一个微型HTTP服务器，两三千行C代码便实现了对于HTTP/1.1的支持，使用的是select异步。

这货应该是很久没更新了，不支持在Mac OS X上直接编译。直接```./configure```会报错，在网上查了一下东西，发现需要执行
   

```plaintext   
./configure --prefix=/usr/local/thttpd --host=freebsd
```

虽然还是会报错，但是不影响configure的，configure完就可以```make```,```make install```了。

安装完成之后，直接在命令行里输入./thttpd，不能够正常启动，需要给他配置文件，新建一个配置文件```/usr/local/thttpd/conf/thttpd.conf```

输入

```plaintext
host=127.0.0.1
port=8080
user=thttpd
logfile=/usr/local/thttpd/log/thttpd.log
pidfile=/usr/local/thttpd/log/thttpd.pid
dir=/usr/local/thttpd/www/
cgipat=**.cgi|**.pl
```

然后再执行

```plaintext    
./thttpd -C /usr/locat/thttpd/conf/thttpd/conf
```
    
就可以正常运行了。thttpd对于资源消耗的控制还是比较优秀的，大概也就Apache的十分之一吧，当个小型Web Server应该没什么问题。
