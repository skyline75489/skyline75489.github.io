弱引用 weak 的前世今生
====================

### 手动内存管理

在 C 语言的世界中，严格意义上说并没有引用这种东西存在，唯一存在的是指针（pointer）——一个威力和杀伤力都十分巨大的东西。

```c
int *p = (int *)malloc(sizeof(int));
*p = 10;
free(p);
// p 成为了野指针
int b = *p; // 危险操作！
```

上面的代码可以通过编译，没有任何警告，但是实际上已经跑飞了。C 语言要求程序员手动对内存进行管理，编译器却没有对于程序行为进行足够多的检查，加上指针操作本身十分灵活，如果没有对于程序足够强的掌控能力，程序的可维护性很可能将成为一场灾难。

C 语言的后辈 C++，在内存管理上做出了一些新的尝试，一个比较大的变化就是增加了引用类型。和指针相比，引用类型在安全上的限制更加严格了：

1. 引用必须被初始化，必须有初始化绑定，且不能初始化为 nullptr

```c++
int &r1; // error: references must be initialized
int &r2 = 0; // error: cannot convert from 'int' to 'int &'
int &r3 = nullptr; // error: cannot convert from 'nullptr' to 'int &'
```

2. 引用不能被重新绑定

```c++
int a1 = 5;
int a2 = 6;

int &b = a1; // b 和 a1 绑定在一起，并且再也不能绑定别的值
b = a2; // a1 的值也被改变，a1 = a2 = 6
```

3. 引用没有多层关系，即没有引用的引用

```c++
int x = 0;
int y = 0;
int *p = &x;
int *q = &y;
int **pp = &p;
pp = &q; // *pp = q，而 p 不受影响
**pp = 4;
assert(y == 4);
assert(x == 0);
```

4. 引用作为返回值，如果用法不当，会有 warning

```c++
int * squarePtr(int number) {
  int localResult = number * number;
  return &localResult; // warning: returning address of local variable or temporary: localResult
}

int & squarePtr(int number) {
  int localResult = number * number;
  return localResult; // warning: returning address of local variable or temporary: localResult
}
```

可以看到，C++ 的引用某种程度上是想引入更加严格的生命周期管理，不过限于很多地方对于 C 语言兼容的要求，引用类型往往还是被当做一个 const 的指针来使用。C++ 的引用更像是对象的一个 alias，而不是一个可以保证对象存活的 reference。同时 C++ 引用也没有（想）解决更加 common 的内存过早释放问题：

```c++
const char * getString() {
  std::string(a);
  return a.c_str(); // a 提前释放，返回值不再有意义
}
```

### 自动内存管理

C++ 语言在 C++ 11 标准中引入了智能指针类型，让 C++ 内存管理进入了自动时代。智能指针类型本身是基于引用计数的，可以表达出对于对象的“拥有”关系。

1. `unique_ptr` 唯一拥有

```c++
void SmartPointerDemo()
{    
    // 创建对象 unique_ptr
    std::unique_ptr<LargeObject> pLarge(new LargeObject());

    // 调用方法
    pLarge->DoSomething();

    // 传递对象引用
    ProcessLargeObject(*pLarge);

} // 对象出 scope 被自动释放
```

2. `shared_ptr` 共享拥有

```c++
std::shared_ptr<int> p1(new int(5));
std::shared_ptr<int> p2 = p1; // 两个指针同时拥有对象

p1.reset(); // p2 还在，因此对象不会被释放
p2.reset(); // 释放对象，因为已经没有人拥有它
```

3. `weak_ptr` 弱拥有

实际上表达了一种只是使用，而不拥有的语义：

```c++
std::shared_ptr<int> p1(new int(5)); // p1 拥有对象
std::weak_ptr<int> wp1 = p1; 

p1.reset(); // 释放对象

std::shared_ptr<int> p3 = wp1.lock(); // 返回一个空指针
if(p3)
{
  // 不会执行
}
```

同时，由于采用引用计数，不可避免的会存在引用循环的问题：

```c++
struct B;
struct A {
  std::shared_ptr<B> b;  
  ~A() { std::cout << "~A()\n"; }
};

struct B {
  std::shared_ptr<A> a;
  ~B() { std::cout << "~B()\n"; }  
};

void useAnB() {
  auto a = std::make_shared<A>();
  auto b = std::make_shared<B>();
  a->b = b;
  b->a = a;
  // A 和 B 互相引用
}
```

将其中一个指针改为 weak 可以解决引用循环的问题。

### Objective-C & Swift 中的 weak

### GC 环境下的 Weak

### 总结


#### 参考资料

* https://stackoverflow.com/questions/57483/what-are-the-differences-between-a-pointer-variable-and-a-reference-variable-in
* https://www.ntu.edu.sg/home/ehchua/programming/cpp/cp4_PointerReference.html
* https://stackoverflow.com/questions/27085782/how-to-break-shared-ptr-cyclic-reference-using-weak-ptr
* https://en.wikipedia.org/wiki/Smart_pointer#shared_ptr_and_weak_ptr
