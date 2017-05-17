C# Native Interop：从入门到再次入门
================================

## C# 与 Native API 的互操作性

.NET 平台对于 C/C++ 等 Native 库具有良好的互操作性，其中一部分原因是，微软本身在实现 .NET Framework 的过程中发现，Win32 API 经过多年的发展已经过于庞大，大到无法也没有必要使用 C# 全部重新实现一遍，不如直接通过 C# 调用 Win32 API 来的实际。如今 .NET Framework 中很多类库到最底层也是使用的 Win32 或 COM 的 API。因此，当我们自己需要调用 C++ 类库时也可以放心大胆的使用 C# 的互操作技术。

目前 .NET 平台提供了下面三种互操作技术：

1. Platform Invoke(P/Invoke)，主要用于调用 C/C++ 库函数和 Windows API
2. C++/CLI Interop, 即在 Managed C++(托管C++)中调用 C/C++ 类库
3. COM Interop, 主要用于在 .NET 中调用 COM 组件

其中 C++/CLI Interop 和 P/Invoke 技术在底层实现上实质是一致的，只是在上层使用上有所差异。因此本文对于 C++/CLI 技术不再单独讲述，感兴趣的读者可以自行查阅有关资料。本文就 P/Invoke 和 COM Interop 两种技术进行一些探讨，希望能给读者以启发和收获。

## P/Invoke

P/Invoke 的前身是当年微软专属的 Java 实现 J++ 当中使用的 J/Direct 技术。和 JNI 技术不同，J/Direct 通过跨过 Java 虚拟机直接和 Native 代码进行交互达到了相对更高的性能。后来随着 .NET 技术的兴起，J/Direct 也在 .NET 的世界里以 P/Invoke 的方式得到的重生。

P/Invoke 依托于 CLR 和 JIT，实现了在 .NET 平台对于非托管 DLL 的加载和调用。在介绍 P/Invoke 之前，我们首先了解一下非托管 DLL 的有关知识。

### Native DLL

DLL 是 Windows 平台上专属的动态库格式，具体来说应该被称为 PE/COFF 文件。注意 DLL 实际上是有很多种的，有最普通的 Native 代码生成的 DLL，还有后面会涉及到的 COM DLL，以及 .NET assembly DLL。这里主要介绍 Native DLL，Win32 大部分类库，以及我们自己使用 C/C++ 代码编译生成的都是这种 DLL。

DLL 技术是整个 Win32 运行库的基础。Win32 绝大部分 API 都是通过 DLL 暴露给开发者的。DLL 技术本身也极其复杂，这里我们只涉及一些和本文内容有关的知识。

#### DLL 导出

DLL 当中的内容需要显式地导出之后才能使用。这里 DLL 同 Linux 上的 ELF （以及苹果 Darwin 平台上的 Mach-O？）显著不同的一点。ELF 格式是默认导出所有符号的，因此也就不存在导出这个概念了。而 DLL 如果一个符号没有被导出，那么外部是没有办法使用的，Linker 会找不到对应的内容。

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
* https://msdn.microsoft.com/zh-cn/library/aa686045.aspx
* https://www.codeproject.com/Articles/28969/HowTo-Export-C-classes-from-a-DLL


