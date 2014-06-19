Python学习笔记 —— filter，map和reduce 
=====================================


在Python2.7中这是三个内置方法，可以对sequence(list,string,tuple)进行操作，返回类型和输入类型相同。在Python3.3中，filter，map和reduce全部变成了类，其中reduce还进入了functools包中，需要import才能使用，默认是找不到的，一些用法也和Python2.7中有所不同。

**1.filter**

filter的名字已经暗示了它的作用——”过滤“，它用function过滤输入的sequence，返回在function里判定为True的成员。下面是tutorial里给出的例子。

*Python 2.7*

```python
>>> def f(x): return x % 2 != 0 and x % 3 != 0
...
>>> filter(f, range(2, 25))
[5, 7, 11, 13, 17, 19, 23]

```

在Python3.3中，filter变成了类，不能直接产生list，需要进行一下转换。map和reduce也类似。

*Python 3.3*

```python
>>> def f(x): return x % 2 != 0  and x % 3 != 0

>>> list(filter(f,range(2,25)))
[5, 7, 11, 13, 17, 19, 23]
```

**2.map**

map对一个或多个sequence执行function函数，将结果作为一个sequence返回。单看解释似乎不够清楚，还是看例子比较好。

```python
>>> def cube(x): return x*x*x
...
>>> map(cube, range(1, 11))
[1, 8, 27, 64, 125, 216, 343, 512, 729, 1000]
```

用map可以很容易地利用已有的sequence生成新的sequence。当用多个sequence构造新的sequence的时候，function接受的参数数量和后面sequence的数量必须相同，否则在Python 2.7中会报错。在Python3.3里使用map构造对象不报错，但当试图将map对象转换成list时报错，如下面所示。

*Python 2.7*

```python
>>> seq = range(8)
>>> def add(x,y): return x+y

>>> map(add,seq,seq)
[0, 2, 4, 6, 8, 10, 12, 14]
>>> map(add,seq,seq,seq)

Traceback (most recent call last):
  File "<pyshell#38>", line 1, in <module>
    map(add,seq,seq,seq)
TypeError: add() takes exactly 2 arguments (3 given)
>>> 
```

*Python 3.3*

```python
>>> seq = range(8)
>>> def add(x,y): return x+y

>>> a = map(add,seq,seq,seq)
>>> a
<map object at 0x0202D950>
>>> list(a)
Traceback (most recent call last):
  File "<pyshell#9>", line 1, in <module>
    list(a)
TypeError: add() takes 2 positional arguments but 3 were given
>>> 
```

当sequence长度不相等的时候，Python2.7中直接报错，因为它把不足的元素全部替换成了None，于是产生了类型不兼容。而在Python 3.3中，生成的sequence长度和最短的那个一致，其他多余的元素被丢弃。

*Python 2.7*

```python
>>> seq1
[0, 1, 2, 3, 4, 5, 6, 7]
>>> seq2
[0, 2, 4, 6]
>>> map(add,seq1,seq2)

Traceback (most recent call last):
  File "<pyshell#48>", line 1, in <module>
    map(add,seq1,seq2)
  File "<pyshell#36>", line 1, in add
    def add(x,y): return x+y
TypeError: unsupported operand type(s) for +: 'int' and 'NoneType'
```

*Python 3.3*

```python
>>> list(seq1)
[0, 1, 2, 3, 4, 5, 6, 7]
>>> list(seq2)
[0, 2, 4, 6]
>>> list(map(add,seq1,seq2))
[0, 3, 6, 9]
>>> 
```

似乎Python 3.3的处理更加合理一些。

**3.reduce**

reduce将function作用于sequence上，每次对前两个元素产生作用，然后将生成的结果重新放回sequence里作为第一个元素，依次类推，最后得到一个结果。

```python
>>> def add(x,y): return x+y
...
>>> reduce(add, range(1, 11))
55
```

reduce还可以带第三个参数——初始值，作为结果的起点，同时当sequence为空时，初始值即为结果。如果没有设定初始值，那么当sequence为空时会报错。

```python
>>> reduce(add,range(1,11),10)
65
>>> reduce(add,[],10)
10
>>> reduce(add,[])

Traceback (most recent call last):
  File "<pyshell#8>", line 1, in <module>
    reduce(add,[])
TypeError: reduce() of empty sequence with no initial value
>>> 
```
