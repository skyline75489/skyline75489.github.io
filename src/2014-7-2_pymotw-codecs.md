(译)PyMOTW(6.1)——codecs
===============================

### 6.1 codecs-字符串编码和解码

>**作用** 将字符串在不同表现形式之间转换的编码器和解码器

>**可用性** 2.1及以后

codecs模块提供了流和文件接口，用于在程序中转换编码。它最常见用于处理Unicode文本，它也支持其他编码和其他各种用途。

#### 6.1.1 Unicode入门

CPython 2.x支持两种类型的字符串，用于处理文本数据。旧式的```str```实例使用一个8-bit字节的ASCII编码来表示每个字符。与之相反，unicode字符串在内部使用一串Unicode码点来管理。码点的值使用2字节或4字节存储，这取决于Python
编译时给出的选项。```str```和```unicode```都继承自一个公共的基类，支持相似的API。

当```unicode```字符输出的时候，它们使用标准方法中的某一种进行编码，使得字节序列可以在之后重建，还原成原来的字符串。编码出的值并不一定和码点的值相同，编码本身定义了用于在两种类型的值之间进行转换的方法。读取Unicode数据同样需要知道编码，以使读取的数据被转化成```unicode```类中的内部表示。

西方语言最常见的编码是UTF-8和UTF-16，它们分别使用1个和2个字节来表示字符。其他编码更适合存储那些字符本身需要多于2字节码点表示的语言。

**请参看**:

想了解更多关于Unicode的信息，请参考本部分最后的引用来源。Python的[Unicode HOWTO](http://docs.python.org/howto/unicode)尤其值得阅读。

##### Encodings

理解编码最好的方法便是看看同一个字符串，在不同编码下产生的不同字节序列。下面的例子使用这个函数来格式化字节字符串，使其更容易阅读。

```python
import binascii

def to_hex(t, nbytes):
    "Format text t as a sequence of nbyte long values separated by spaces."
    chars_per_item = nbytes * 2
    hex_version = binascii.hexlify(t)
    num_chunks = len(hex_version) / chars_per_item
    def chunkify():
        for start in xrange(0, len(hex_version), chars_per_item):
            yield hex_version[start:start + chars_per_item]
    return ' '.join(chunkify())

if __name__ == '__main__':
    print to_hex('abcdef', 1)
    print to_hex('abcdef', 2)
```

这个函数使用```binascii```来得到输入字符串的16进制表示，然后在每nbytes字节之前插入一个空格。

```bash
$ python codecs_to_hex.py
61 62 63 64 65 66
6162 6364 6566
```

第一个编码示范从打印文本'pi: π'开始。使用```unicode```类的```repr```表示， 'π'这个字符被替换成了Unicode码点\u03c0。接下来两行代码把分别这个字符串编码成UTF-8和UTF-16，然后展示了编码结果的16进制表示。

```python
from codecs_to_hex import to_hex

text = u'pi: π'
print 'Raw   :', repr(text)
print 'UTF-8 :', to_hex(text.encode('utf-8'), 1)
print 'UTF-16:', to_hex(text.encode('utf-16'), 2)

```

将```unicode```字符串编码的结果是一个```str```对象。

```bash
$ python codecs_encodings.py

Raw   : u'pi: \u03c0'
UTF-8 : 70 69 3a 20 cf 80
UTF-16: fffe 7000 6900 3a00 2000 c003
```

给出一个编码字节的序列作为```str```实例，```decode()```方法可以将他们转换成码点，并且返回```unicode```实例。

```python
from codecs_to_hex import to_hex

text = u'pi: π'
encoded = text.encode('utf-8')
decoded = encoded.decode('utf-8')

print 'Original :', repr(text)
print 'Encoded  :', to_hex(encoded, 1), type(encoded)
print 'Decoded  :', repr(decoded), type(decoded)

```

编码的选择并不影响输出类型。

```bash
$ python codecs_decode.py
Original : u'pi: \u03c0'
Encoded  : 70 69 3a 20 cf 80 <type 'str'>
Decoded  : u'pi: \u03c0' <type 'unicode'>
```

**注意**:默认编码在解释器启动阶段，```site```模块加载的时候就已经确认了。参考```Unicode Defaults```查看如何通过```sys```操作默认编码设置。

#### 6.1.2 文件操作

编码和解码字符串对于I/O操作至为重要。无论你需要将数据写入文件，socket，或者其他流中，你都需要确保数据使用了正确的编码。总体上讲，所有的文本数据在读取的时候都需要从二进制表示中解码，在写入的时候再从内部二进制值编码成特定的表现形式。你的程序可以显式地编码和解码数据。由于这种操作依赖于所使用的编码，想要完整地解码数据，判断是否读取了足够的字节并不是一件小事。```codecs```提供了管理数据编码和解码的类，你不再需要重复造轮子了。

最简单的接口是```codecs```提供的用于替换内建```open()```函数的同名版本。这个版本工作起来和内建函数几乎相同，只是添加了两个用于确定编码和错误处理行为的参数。

```python
from codecs_to_hex import to_hex
    import codecs
    import sys
    encoding = sys.argv[1]
    filename = encoding + '.txt'
    print 'Writing to', filename
    with codecs.open(filename, mode='wt', encoding=encoding) as f:
      f.write(u'pi: \u03c0')
      # Determine the byte grouping to use for to_hex()
      nbytes = { 'utf-8':1,
                'utf-16':2,
                'utf-32':4,
                }.get(encoding, 1)

# Show the raw bytes in the file
print 'File contents:'
with open(filename, mode='rt') as f:
  print to_hex(f.read(), nbytes)
```

开始是一个```unicode```字符串，其中有一个 π。这个例子将文本使用命令行中给出的编码存储到文件中。

```bash
$ python codecs_open_write.py utf-8
Writing to utf-8.txt
File contents:
70 69 3a 20 cf 80

$ python codecs_open_write.py utf-16
Writing to utf-16.txt
File contents:
fffe 7000 6900 3a00 2000 c003

$ python codecs_open_write.py utf-32
Writing to utf-32.txt
File contents:
fffe0000 70000000 69000000 3a000000 20000000 c0030000
```

使用```open()```读取文件简单明了，前提是你知道文件的编码。某些文件格式，例如XML，允许你指定编码并将其作为文件的一部分。但是通常编码还是要靠程序来确定。```codecs```只把编码作为一个参数并且假定它是正确的。

```python
import codecs
import sys

encoding = sys.argv[1]
filename = encoding + '.txt'

print 'Reading from', filename
with codecs.open(filename, mode='rt', encoding=encoding) as f:
    print repr(f.read())
```

这个例子读取前一个程序创建的文件，然后把它们用```unicode```对象的形式打印出来

```bash
$ python codecs_open_read.py utf-8
Reading from utf-8.txt
u’pi: \u03c0’

$ python codecs_open_read.py utf-16
Reading from utf-16.txt
u’pi: \u03c0’

$ python codecs_open_read.py utf-32
Reading from utf-32.txt
u’pi: \u03c0’
```

#### 6.1.3 字节序

像UTF-16和UTF-32这样的多字节编码，在不同计算机上传输数据时，不管是直接复制还是通过网络传输，都会遇到另一个问题。不同的计算机系统的高位和低位字节采用不同的顺序。这个特性依赖于计算机的硬件架构和操作系统以及应用开发者，通常被称为**字节序**(endianness)。有些时候我们没有办法提前得知给出的数据采用哪种字节序，所以在多字节编码中包含了一个__字节顺序标识__(BOM, byte-order-maker)，放在编码输出的前几个字节。例如，UTF-16定义0xFFEE和0xFEFF不是可用的字符，可以被用来指示字节序。```codecs```为UTF-16和UTF-32使用的字节序定义了常量。
