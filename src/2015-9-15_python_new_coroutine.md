Python 3.5 Coroutine 特性初探
============================


Python 3.5 终于在前两天（13号）放出了正式版，其中最受大家关注的特性大概就是全新加入的 Coroutine 支持了。

在 Python 3.5 之前，我们可以使用 Python 的 generator 变相地写出 coroutine 的效果，在 Python 3.3 中还加入了 `yield from` 关键字，增强了对于 coroutine 的支持。现在在 Python 3.5 中，终于加入了原生的 coroutine 支持。本文会使用几个小例子，介绍一下 Python 3.5 中 coroutine 的使用。

Python 3.5 中为 coroutine 加入了两个新的关键字，`async` 和 `await`， `async` 用于定义 coroutine，`await` 用于从 coroutine 返回。

首先定义一个 coroutine:

```python
async def a():
    print('a1')
    print('a2')
    print('a3')
```


这个 coroutine 看起来像是函数，但是实际上它属于一个单独的 coroutine 类型，并且不能直接调用，如果我们直接调用它：

```python
a()
```

会报错：

    RuntimeWarning: coroutine 'a' was never awaited
      a()
  
可以打印一下它的类型：

```python
print(a())
```

会打印出类似下面的输出：

    <coroutine object a at 0x10190e7d8>
    
想要调用它，需要使用 send 函数：

```python
co = a()
try:
    co.send(None)
except StopIteration:
    pass
```

可以看到，coroutine 的使用和 generator 其实是非常接近的，在底层 coroutine 也确实是基于 generator 实现的。 Python 3.5 还专门提供了一个 decorator `types.coroutine()` 用于把旧式的 yield from 写法的 coroutine 转换成原生的 coroutine 类型。

```python

import types

@types.coroutine
def a():
    print('a1')
    yield
```

同样使用上面的 `send` 方法进行调用，这段代码和原生 coroutine 运行的效果是一样的。

在一个 coroutine 中，可以使用 `await` 用于从别的 couroutine 返回：


```python
async def a():
    print('a1')
    print('a2')
    await b()
    print('a3')

async def b():
    print('b1')
    print('b2')
    print('b3')
```

这段代码中，`await` 会导致 b() 执行，等 b() 执行完毕之后，再回来执行 a()。

需要注意的是， `await` 只能在 `async def` 中使用，同时 `await` 后面跟的类型必须为 `awaitable`，具体可以有下面几种：

* 原生的 coroutine，使用 `async def` 定义
* 使用 `types.coroutine` 包装过的基于 generator 的方法（如上面的例子中的方法）
* 实现了 `__await__` 的对象
* 使用 CPython API 实现了 `tp_as_async.am_await` 的对象（和上一条类似）

更多有关 coroutine 的信息，可以参考 [PEP-0492](https://www.python.org/dev/peps/pep-0492/)。