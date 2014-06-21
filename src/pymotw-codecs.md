PyMOTW(6.1)——codecs
===============================

### 6.1 codecs-字符串编码和解码

>**作用** 将字符串在不同表现形式之间转换的编码器和解码器

>**可用性** 2.1及以后

codecs模块提供了流和文件接口，用于在程序中转换编码。它最常见用于处理Unicode文本，它也支持其他编码和其他各种用途。

#### 6.1.1

CPython 2.x支持两种类型的字符串，用于处理文本数据。旧式的```str```实例使用一个8-bit字节的ASCII编码来表示每个字符。与之相反，unicode字符串在内部使用一串Unicode码点来管理。码点的值使用2字节或4字节存储，这取决于Python
编译时给出的选项。```str```和```unicode```都继承自一个公共的基类，支持相似的API。

当```unicode```字符输出的时候，它们使用标准方法中的某一种进行编码，使得字节序列可以在之后重建，还原成原来的字符串。编码出的值并不一定和码点的值相同，编码本身定义了用于在两种类型的值之间进行转换的方法。读取Unicode数据同样需要知道编码，以使读取的数据被转化成```unicode```类中的内部表示。

西方语言最常见的编码是```UTF-8```和```UTF-16```，它们分别使用1个和2个字节来表示字符。其他编码更适合存储那些字符本身需要多于2字节码点表示的语言。

**请参看**:

想了解更多关于Unicode的信息，请参考本部分最后的引用来源。Python的[Unicode HOWTO](http://docs.python.org/howto/unicode)尤其值得阅读。

#### Encodings

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

第一个编码示范从打印文本'pi: π'开始。使用```unicode```类的```repr```表示， 'π'这个字符被替换成了Unicode码点\u03c0。接下来两行代码把分别这个字符串编码成```UTF-8```和```UTF-16```，然后展示了编码结果的16进制表示。

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
