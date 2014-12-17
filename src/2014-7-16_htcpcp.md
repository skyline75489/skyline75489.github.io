超文本咖啡壶控制协议
================

今天看[Werkzeug源码](https://github.com/mitsuhiko/werkzeug/blob/master/werkzeug/http.py)时偶然间看到一个http状态码是"418: I'm a teapot"，后面还标注着“see RFC 2324”。我挺好奇什么协议的返回码会是“我是个茶壶”？于是就去查了一下RFC 2324，才发现RFC原来也这么有恶搞精神。

[RFC 2324](http://www.ietf.org/rfc/rfc2324.txt)主要描述了**超文本咖啡壶控制协议**（英文：Hyper Text Coffee Pot Control Protocol，HTCPCP）。[维基百科](http://zh.wikipedia.org/wiki/HTCPCP)上说这是一种用于控制、监测和诊断咖啡壶的协议，可以视作一种早期的物联网实验。说白了就是RFC的一个恶搞。尽管是恶搞，但是人家的专业精神还在，整的这个协议跟真的一样，一点都不像是恶搞的（如果不仔细看内容的话）：

>HTCPCP是HTTP协议的扩展。HTCPCP请求通过URI架构coffee:来引用，并且还包含了若干种HTTP请求：

>BREW或POST：令HTCPCP服务器（咖啡壶）煮咖啡。
    GET：从服务器获取咖啡。
    PROPFIND：获取咖啡的元数据。
    WHEN：让服务器停止向咖啡中加入牛奶（如适用），即英文"say when"之意。
    
>这个协议还定义了两种错误答复：

>406 Not Acceptable（无法接受）：HTCPCP服务器由于某种原因而暂时不能煮咖啡。服务器在回复中应当包含一组可接受的咖啡类型列表。
   
>418 I'm a teapot（我是茶壶）：HTCPCP服务器是一个茶壶。这个错误答复可能是由一个又矮又胖的东西发出的。


以前真的不知道RFC这类国际组织也敢这么恶搞，推荐大家去看一下[RFC 2324](http://www.ietf.org/rfc/rfc2324.txt)，感受下什么是“专业“的恶搞。