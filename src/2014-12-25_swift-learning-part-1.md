Swift学习笔记——语法初探
====================

最近闲了一些，打算系统地学习一下Swift语言，写一个系列日志来记录一下学习中的心得和体会，也起到监督自己的作用。

Swift语言的起源啊之类的废话就不说了，直接上干货。这一篇日志主要讲一下Swift语法上的一些特点。

### "强制"空格

Swift语言并不是像C/C++，Java那样完全忽视空格，Swift对空格的使用有一定的要求，但是又不像Python对缩进的要求那么严格。

在Swift中，运算符不能直接跟在变量或常量的后面。按照[Stackoverflow上的说法](https://stackoverflow.com/questions/24134354/swift-error-prefix-postfix-is-reserved)，是为了区分前缀运算符和后缀运算符，避免写出```++i++```这样的代码。看起来很美好，但是实际使用中还是有一些别扭，例如下面的代码会报错（注意空格）：

```swift
let a= 1 + 2
``` 

错误信息是：

```plaintext
error: prefix/postfix '=' is reserved
```
意思大概是等号直接跟在前面或后面这种用法是保留的。

下面的代码还是会报错（继续注意空格）：

```swift
let a = 1+ 2
```

错误信息是：

```plaintext
error: consecutive statements on a line must be separated by ';'
```

这是因为Swift认为到```1+```这个语句就结束了，```2```就是下一个语句了。

只有这样写才不会报错：

```swift
let a = 1 + 2;  // 编码规范推荐使用这种写法
let b = 3+4	// 这样也是OK的
```

### 全新的字符串处理

Swift的字符串是全Unicode的，于是就产生了在网上流传的用Emoji表情写的代码（用中文写的话，岂不就是传说中的“中文编程”了？）

```swift
let wiseWords = "\"Imagination is more important than knowledge\" - Einstein"
// "Imagination is more important than knowledge" - Einstein
let dollarSign = "\x24"        // $,  Unicode scalar U+0024
let blackHeart = "\u2665"      // ♥,  Unicode scalar U+2665
let sparklingHeart = "\U0001F496"  // 💖, Unicode scalar U+1F496”
```

由于这个特点，Swift中字符串不再使用length来获得属性，而是使用全局方法```countElements```，这样能使不同语言的字符串都得到正确的长度结果。

同时，Swift还带来了全新的构建字符串的方式——字符串插值，简化了字符串的构建操作。

```swift
let multiplier = 3let message = "\(multiplier) times 2.5 is \(Double(multiplier) * 2.5)"
```

最感人的是对字符串可变性的处理。Swift中使用```let```和```var```来区分可变字符串和不可变字符串，不再使用```NSString```和```NSMutableString```。同时字符串的拼接可以像Python一样直接使用加号，判断两个字符串是否相等也可以直接使用等号，终于可以告别```[str1 isEqualToString:str2]```和```[str1 stringByAppendingString:str2]```这种繁琐的语法了。


### Optional与Unwrap

Optional大概是Swift里最有特色的”特色“了，苹果为这个特色也准备了很多语法糖。关于Optional的具体含义和用法可以参考[这篇文章](http://onevcat.com/2014/06/walk-in-swift/)，这里只简单讲一下语法上的内容。

首先是大量的```?```和```!```使用，刚开始看起来会让人摸不着头脑，明白的话好理解了。

```swift
let possibleString: String? = "An optional string."///这个String可以是nil

println(possibleString!)///必须使用!才能取出String值，不然打印出的是一个Optional值
```

简单来说，```?```用来声明变量为Optional，```!```用于强制unwrap一个Optional。

然后是```let```关键字可用于Optional Binding，就是这种写法：

```swift
if let constantName = someOptional {
	statements
}
```

这种写法类似于Go语言，可以在if语句执行之前做一个赋值操作：

```go
if err := file.Chmod(0664); err != nil {
    log.Print(err)
    return err
}
```
不过由于Optional的特性，Swift中不再需要```err != nil```这一句了，显得更简洁一些。


### 运算符

Swift的运算符和C基本是一样的，不过Swift的取余运算是可用于浮点数的。这种运算符我真的是第一次见到：

```swift
let a = 10 % 3    // a = 1
let b = 10.8 % 3  // b = 1.8000000000000007
```

这里%运算符的作用不再是取模了，官方文档特意强调了这一点，它的作用就是取余。

### For In 与 Range

Swift引入了很多语言中都有的For In语法和Range语法，使得遍历操作变得很方便：

```swift
for index in 1...5 {
    println("\(index) times 5 is \(index * 5)")
}
// 1 times 5 is 5
// 2 times 5 is 10
// 3 times 5 is 15
// 4 times 5 is 20
// 5 times 5 is 25
```

这里的```1...5```表示全闭，可以用```1..<5```表示半开半闭，也就是不包括5。这里注意一点，有些资料比较旧，使用的是旧的写法```1..5```，这种写法在新版本的Xcode上是不能通过编译的。