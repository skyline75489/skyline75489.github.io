弱引用 weak 的前世今生
===================

### 为什么需要弱引用？

#### 手动内存管理

在 C 语言中，严格意义上说并没有引用这种东西存在，唯一存在的是指针（pointer）——一个威力和杀伤力都十分巨大的东西。

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

### 非 GC 环境下的弱引用

#### C++ 中的 weak_ptr

#### OC & Swift 中的 weak

#### Rust 中的弱引用

### GC 环境下的弱引用

#### .NET 中的弱引用

#### Python 中的弱引用

### 总结


#### 参考资料

* https://stackoverflow.com/questions/57483/what-are-the-differences-between-a-pointer-variable-and-a-reference-variable-in
* https://www.ntu.edu.sg/home/ehchua/programming/cpp/cp4_PointerReference.html

