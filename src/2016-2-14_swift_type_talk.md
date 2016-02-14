Swift学习笔记(五)——类型系统初探
===========================

### 从头学习 Swift

尽管 Swift 的语法参考了 Python，JavaScript 等，然而 Swift 是一个不折不扣的**强类型**，**静态类型**语言。Swift 对于类型的检查非常严格，以至于让我这样写熟了 Python 的人写起来非常不适应 :(

```swift
var a = 10; // 自动类型推导
a = "Hello" // 报错，类型不匹配
```

因为 Swift 的类型特性，想用写 Python 和 JS 的思想去写 Swift 是不靠谱的，大量的编译报错会把人弄崩溃。同时，用写 OC 的思想去写 Swift 也会被坑。

```swift
let clz = NSClassFromString(name) as! NSObject.Type
let instance = clz.init() 
// NSClassFromString 返回值为 AnyClass
// 想调用 init 必须要强制 cast 成 NSObject
// 然而强制 cast 本身又是不被推荐的
```

看来想达到“熟悉Swift”，需要从头开始理解 Swift，并且形成一种独立的编程思想（当初是谁说 Swift 大幅降低 iOS 学习成本的，分明是提高了好吗...）。

### Optional 与 AnyObejct 的纠缠

Optional 类型是 Swift 中非常亮眼的特性，我在[之前的博文](https://skyline75489.github.io/post/2014-12-25_swift-learning-part-1.html)中也提到过。当变量的类型本身是确定的情况下，Optional 是很好用的。但是当变量类型是 AnyObject? 时，使用 Optional 就不可避免的要引入类型转换了。在使用旧的 OC API 时会碰到很多这种情况：

```swift
let d = NSMutableDictionary()
let r = d["Something"] // 类型为 AnyObject?

// 推荐这样进行类型转换，以防止强转失败
if let r2 = d["Other"] as? String {
   // Do something
}
```

当大量出现 AnyObject? 时，代码会变得非常啰嗦。[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)的 README 中展示了一个例子：

```swift
if let JSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [[String: AnyObject]],
    let username = (JSONObject[0]["user"] as? [String: AnyObject])?["name"] as? String {
        // There's our username
}
```

正如[SwifterTips 中的这篇文章](http://swifter.tips/any-anyobject/)提到的，AnyObject（以及 Any，AnyClass）等本身就是为了向 OC 类型提供兼容而出现的妥协产物。然而 Swift 语言本身还在发展进步中，大家抛弃 OC 的步伐也没有想象中那么快。因此，尽管有了[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)这样方便大家的开源库，在可预见的未来里，上面例子中的痛点在 Swift 开发中依然会存在。

### 泛型与 Extension 的矛盾

在最新的 Objective-C 2.0 里苹果引入了轻量级泛型的支持，仅仅是语法层次上的静态检查，已经是 OC 开发者的一大福音了：

```objectivec
@property (nonatomic) NSArray<Person *> *persons
```

Swift 中泛型支持已经是一个单独的特性了，和 OC 相比是一大进步：

```swift
struct Stack<Element> {
    var items = [Element]()
    mutating func push(item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
}
```

同时 Swift 中还支持对泛型类型进行限制，例如 Dictionary 的 key 类型限制为 Hashable：

```swift
public struct Dictionary<Key : Hashable, Value> : CollectionType, DictionaryLiteralConvertible {
   // ...
}
```

这个特性很先进，而且很好用（对比 C++...）。

在泛型的诸多好用之处以外，和 Extension 的混用应该算是一个不大不小的痛点。

例如我们试着给 Array 类型加一个 Extension：

```swift
extension Array {
    mutating func someFunc() {
        self.append("Hello")
    }
}
```

上面的代码会报 `Cannot invoke 'append' with an argument list of type '(String)'`。这里不管 append 什么类型都会报错，因为 Array 本身是一个泛型类型，不确定的类型是没法随便 append 的。

正确的写法应该是这样的：

```swift
extension Array where Element:StringLiteralConvertible {
    mutating func someFunc() {
        self.append("Hello")
    }
}
```

同理，如果想添加别的类型的支持（例如整数类型），就要写在另一个 Extension 里，并且加上类型限制：

```swift
extension Array where Element: IntegerLiteralConvertible {
    mutating func otherFunc() {
        self.append(188)
    }
}
```

在给泛型类型添加 Extension 时仍然需要确定泛型的具体类型，其实等于是丧失了 Extension 的灵活性。这里的矛盾也可以看成是旧特性（OC 的 Category & Extension）与新特性（泛型）之间的一种妥协。

希望苹果在 Swift 的下个版本中能对这篇文章里提到的这些痛点给出更好的解决方案。如果你知道更好的写法的话，欢迎随时骚扰 :)