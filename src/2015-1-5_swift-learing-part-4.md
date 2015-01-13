Swift学习笔记(四)——类与对象
========================

Swift对面向对象提供了良好的支持，下面介绍几个其独有的特性。

### 懒加载属性

Swift在语言层面上提供了类中懒加载属性的支持，使用```lazy```作为关键字：

```swift
class Renderer {
	lazy var loader = Loader()
	var data = [String]()
	var render() {
		// Do something...
	}
}

let renderer = Renderer()
renderer.data.append("## Hello")
renderer.data.append("## Hello Again")
// loader不会被创建
renderer.loader.loadData()
// loader现在才会被创建
```

### 属性计算与属性观察器

类似于C#和Python中的```@property```，Swift也支持给属性赋值或者取出值时进行计算：
	

```swift
class Square {
	var length = 0.0
	var size: Double { // 必须显式声明类型
		get {
			return length * length
		}
		set (newSize) {
			length = sqrt(newSize)
		}
	}
}
```

也可以用下面的方法将属性设置成只读的：

```swift
class Square {
	var length = 0.0
	var size: Double {
			return length * length
		}
	}
}
```

除了 set 和 get ，Swift还提供了更细粒度的对于属性值变化的观察方法——属性观察器 willSet 和 didSet ：

```swift
class Person {
	var age: Int = 0 {
		willSet(newAge) {
			println("About to set new age")
		}
		didSet {
			println("Did set new age")
		}
	}
}
```

willSet 和 didSet在每次属性赋值时都会被调用，不管新值是否与旧值相同，但是在init函数中给属性赋值时则不会被调用。


### 使用下标访问属性

Swift提供了subscript语法，可以使用下标来访问类的属性，类似于Python中的``__getitem__``


```swift
class Dict {
	subscript(key: String) -> String {
		get {
		// 取值
		}
		
		set(newValue) {
		// 赋值
		}
}
```

### Convenience初始化器

Swift支持两个层次的初始化，一种叫做Designated，另一张叫做Convenience，顾名思义，是一种用于方便初始化过程的初始化器。

```swift
class Person {
	var name: String
	init(name: String) {
		self.name = name
	}
	convenience init() {
		self.init(name: "Unknown")
	}
}
```

例如上面的代码，我们便可以使用无参数的init来快速初始化一个Person实例。

你可能要问，为什么不在原来的init里使用默认参数，而是单独再加一个初始化函数呢？我个人的理解是，当初始化参数比较多，而且类型不同时，使用默认参数会使得初始化函数变得过于复杂，而且可读性差。使用Convenicence可以把这些参数全部解耦到不同的函数里，使得代码更加漂亮。例如SwiftJSON里就大量地使用了这一特性:

```swift
public convenience init(url:String) {//...}
public convenience init(nsurl:NSURL) {//...}
public convenience init(data:NSData) {//...}
```

有了这些初始化函数，我们就可以很方便地使用String,URL,NSData等来构造JSON对象。
