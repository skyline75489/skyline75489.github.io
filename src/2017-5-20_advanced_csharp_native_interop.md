C# Native Interop：从入门到再次入门
================================

## C# 与 Native API 的互操作性

.NET 平台对于 C/C++ 等 Native 库具有良好的互操作性，其中一部分原因是，微软本身在实现 .NET Framework 的过程中发现，Win32 API 经过多年的发展已经过于庞大，大到无法也没有必要使用 C# 全部重新实现一遍，不如直接通过 C# 调用 Win32 API 来的实际。如今 .NET Framework 中很多类库到最底层也是使用的 Win32 或 COM 的 API。因此，当我们自己需要调用 C++ 类库时也可以放心大胆的使用 C# 的互操作技术。

目前 .NET 平台提供了下面三种互操作技术：

1.	Platform Invoke(P/Invoke)，主要用于调用 C/C++ 库函数和 Windows API
2.	C++/CLI Interop, 即在 Managed C++(托管C++)中调用 C/C++ 类库
3.	COM Interop, 主要用于在 .NET 中调用 COM 组件

其中 C++/CLI Interop 实质上和 P/Invoke 技术在底层实现上是一致的，只是在上层使用上有所差异。因此本文对于 C++/CLI 不再单独讲述，感兴趣的读者可以自行查阅有关资料。本文就 P/Invoke 和 COM Interop 两种技术进行一些探讨，希望能给读者以启发和收获。

## P/Invoke

### Native DLL

#### DLL 导出

#### DLL Runtime Linking

### blittable 类型

### 托管堆与非托管堆

### Calling Convention

## COM Interop

### COM - A Better C++

### COM 内存机制

### COM 与 C#

## 参考资料

* https://msdn.microsoft.com/en-us/library/eaw10et3(v=vs.110).aspx
* https://msdn.microsoft.com/en-us/library/04fy9ya1(v=vs.80).aspx
* https://www.codeproject.com/Articles/28969/HowTo-Export-C-classes-from-a-DLL


