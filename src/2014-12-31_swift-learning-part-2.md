Swift学习笔记——集合类型
====================

Swift中集合类型有数组和字典两种，对应着Objective-C里面的NSArray和NSDictionary两个类型。

### 数组

Swift中的数组是强类型的，即数组中的元素必须是同一类型，这是它和NSArray以及NSMutableArray一个明显的不同之处。

```swift
var a = [1, 2, 3]       // 这里Swift会进行自动类型推导，认为a是Array<Int>

var b = [1, 2, "Hello"] // 报错 error: 'String' is not convertible to 'Int'

// 也可以显式声明数组的类型
// 旧的Swift官方文档，提供的是c:Int[]这种写法
// 现在这种写法已经废弃了，正确的写法是下面这样的
var c:[Int] = [4, 5, 6]

var d = [Int]()        						// 声明一个空数组
var e = [Int](count:4, repeatedValue:5) // 使用构造函数，e = [5, 5, 5, 5]
```

类似Python，数组可以直接使用```append```方法，```extend```方法或者+=运算符添加元素。

```swift
a.append(4) // a = [1, 2, 3, 4]
c += [7]    // c = [4, 5, 6, 7]
a.extend(c) // a = [1, 2, 3, 4, 4, 5, 6, 7]
```

数组可以使用下标取出元素，也支持通过...取出和修改部分元素，类似Python中的切片操作。

```swift
let d = a[4...6]  		// d = [4, 5, 6]
a[4..6] = [12, 13, 14] // a = [1, 2, 3, 4, 12, 12, 14, 7]
```

不过Swift中并不支持Python中负数下标这种用法，例如a[:-2]。

遍历数组可以使用for in，同时也可以使用```enumerate```来同时得到下标和值。（这个用法跟Python真是太像了，可以说是一模一样）

```swift
for (index, val) in enmerate(c) {
	println("Item:\(index) \(val)")
}
/* 打印出
Item:0:4
Item:1:5
Item:2:6
Item:3:7
*/
```

### 字典

和数组类型一样，字典类型的键和值的类型也必须是确定的。Swift在类型安全上的要求还是挺严格的。