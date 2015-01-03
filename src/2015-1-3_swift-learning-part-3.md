Swift 学习笔记——函数与闭包
=======================

## 函数

Swift中的函数结合了很多语言的优点，使其变得更加强大而且灵活。

### 默认参数

类似Python，Swift也支持默认参数，如果使用了默认参数，那么这个参数的名称在使用时必须标示。

```swift
func convertToString(pretty: Bool = false) {
	// do something
}

convertToString()    			// pretty使用默认值
convertToString(pretty:true)    // 指明pretty的值
convertToString(true)			// 报错 missing argument label 'pretty:'
```

### 常量和变量参数

函数参数默认是常量，也就是不允许在函数体中对参数值进行改变。可以使用```var```显式地将参数值设置为变量:


```swift
func foo(var greeting:String) {
	// 现在可以改变 greeting 的值了
}
```

### 返回参数

变量参数可以在函数体中改变，但是函数执行完成之后其原来的值并没有改变。类似C#中的做法，要想在函数中对参数的值进行改变，需要使用```inout```关键字。

```swift
func swap(inout a: Int, inout b: Int) {
	// 交互两个数
}

swap(&intA, &intB) // 调用，类似使用引用传值
```

需要注意，```inout```关键字不能与```var```或者```let```同时使用，也不能有默认值。

### 真·函数

Swift中，函数是第一等公民，可以用于赋值，可以当做别的函数的参数进行传递，也可以在函数中嵌套函数。

```swift
func addTwoInt(a: Int, b: Int) {
	return a + b
}

var myAddFunc:(Int, Int) -> Int = addTwoInt

myAddFunc(4, 5) // 9

func makeIncre(n:Int) -> (Int) -> Int {
	func addN(a:Int) -> Int{
		return a + n
   }
   return addN
}

let addOne = makeIncre(1)
let addTwo = makeIncre(2)

addOne(6) // 7
addTwo(6) // 8
```

## 闭包

闭包类似于Objectivc-C里的Block，以及别的语言中的lambda，本质上就是一个小的匿名的函数。

