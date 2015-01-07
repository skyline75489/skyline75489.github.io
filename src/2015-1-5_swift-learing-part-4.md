Swift学习笔记(四)——类与对象
========================

Swift对面向对象提供了良好的支持，下面说几个比较有意思的特性。

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

类似于C#和Python中的@property，Swift也支持给属性赋值或者取出值时进行计算：
	

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

