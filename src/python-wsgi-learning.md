Python WSGI学习笔记
=================

WSGI的具体内容就不在这里赘述了，官方的[PEP 333](http://legacy.python.org/dev/peps/pep-0333/)和[PEP 3333](http://legacy.python.org/dev/peps/pep-3333/)说的很详细，不想看英文文档的可以看看[这篇文章](https://jasonlvhit.github.io/articles/wsgi/)，我感觉写的挺简单易懂的。简单来说，WSGI规范把Web组件分成了三个部分，从上到下分别是Application/Framework，Middleware，和Server/Gateway，其中Middleware并不是必需的。有了这三个部分，就可以构建一个完整的Web应用。我主要从下面这几个方面说一下我自己的体会。

### 高度解耦

在阅读WSGI规范的时候，让我感觉比较给力的地方，是这三个层次几乎实现了完美的解耦：Application/Framework层只需要实现一个callable就可以了；Server/Gateway层，只需要把客户端的请求处理成environ，然后传给Application/Framework就可以了；Middleware这个基本上相当于是一个装饰器，同样也是高内聚低耦合的。这三个部分互相之间几乎没有依赖，这使得使用Python开发和部署Web应用变得十分灵活。

为了解耦的需要，WSGI把接口减少到只有一个变量environ，一个callable start_response。这样做为解耦带来方便的同时，也为直接使用WSGI开发带来了困难。要在一个callable里面处理URL Routing，Cookie，Caching之类的，可想而知需要使用多少if else，哪怕使用Middleware恐怕也不会简单到哪里去。因此我们还需要使用Web开发框架。

WSGI的[Q&A](http://legacy.python.org/dev/peps/pep-3333/#questions-and-answers)里明确说明了，WSGI并不是一个Web开发框架，而是一个Web框架和服务器之间交互的接口规范( It's just a way for frameworks to talk to web servers, and vice versa.)。因此不应该把它当成一个框架来使用（虽然实际上是可以这么搞的，如果你不嫌麻烦的话）。

### 与Web框架之间的异同

Web框架对开发者提供了更为友好的接口，例如使用Flask框架，可以使用如下的代码来构建一个输出Hello World的小应用:

```python
from flask import Flaskapp = Flask(__name__)
@app.route(’/’)def hello_world():    return ’Hello World!’if __name__ == ’__main__’:    app.run()
```

而如果直接使用WSGI，可能需要写成这样:

```python
from wsgiref.simple_server import make_server

HELLO_WORLD = b"Hello World!\n"

def my_app(environ, start_response):
    status = '200 OK'
    response_headers = [('Content-type', 'text/plain')]
    start_response(status, response_headers)
    path = environ['PATH_INFO']
    if path == '' or path == '/':
        return [HELLO_WORLD]
    else:
        raise NotFound
        
server = make_server('127.0.0.1', 5000, my_app)
server.serve_forever()
```

很明显使用框架的代码更加简单和明了，可扩展性也更强。

同时，大部分Web框架都提供了符合WSGI规范的接口，也就是说可以作为WSGI app来使用：

```python
# Flask
from flask import Flaskapp = Flask(__name__)

my_app = app.wsgi_app
```

```python
# Tornado 
import tornado.webimport tornado.wsgi
class MainHandler(tornado.web.RequestHandler):    def get(self):        self.write("Hello, world")
        application = tornado.wsgi.WSGIApplication([        (r"/", MainHandler),])
```

```python
# Django
from django.core.wsgi import get_wsgi_application

application = get_wsgi_application()
```

### 多样的部署选择

由于上面提到的高度解耦特性，理论上，任何一个符合WSGI规范的App都可以部署在任何一个实现了WSGI规范的Server上，这给Python Web应用的部署带来了极大的灵活性。

Flask自带了一个基于Werkzeug的调试用服务器。根据Flask的文档，在生产环境不应该使用内建的调试服务器，而应该采取以下方式进行部署：

* mod_wsgi(Apache)
* 独立的WSGI Container（其中包括Gunicorn, Tornado HTTPServer, Twisted Web等）
* uWSGI
* FastCGI
* CGI

实际看来，直接使用mod_wsgi，FastCGI，CGI这些的比较少，这些可能更适合部署PHP使用。比较多的是使用Apache或Nginx做反向代理服务器，然后使用uWSGI或者那几个WSGI Container中的一个来做后端的Server。