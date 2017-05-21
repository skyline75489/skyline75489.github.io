C# Native Interop：从入门到再次入门
================================

## C# 与 Native API 的互操作性

.NET 平台对于 C/C\+\+ 等 Native 库具有良好的互操作性，其中一部分原因是，微软本身在实现 .NET Framework 的过程中发现，Win32 API 经过多年的发展已经过于庞大，大到无法也没有必要使用 C# 全部重新实现一遍，不如直接通过 C# 调用 Win32 API 来的实际。如今 .NET Framework 中很多类库到最底层也是使用的 Win32 或 COM 的 API。因此，当我们自己需要调用 C++ 类库时也可以放心大胆的使用 C# 的互操作技术。

目前 .NET 平台提供了下面三种互操作技术：

1. Platform Invoke(P/Invoke)，主要用于调用 C/C++ 库函数和 Windows API
2. C\+\+/CLI Interop, 即在 Managed C++(托管C++)中调用 C/C++ 类库
3. COM Interop, 主要用于在 .NET 中调用 COM 组件

其中 C\+\+/CLI Interop 和 P/Invoke 技术在底层实现上实质是一致的，只是在上层使用上有所差异。因此本文对于 C++/CLI 技术不再单独讲述，感兴趣的读者可以自行查阅有关资料。本文主要对使用场景最多的 P/Invoke 技术进行一些探讨，同时对 COM 技术以及 COM Interop 进行一下简单介绍，希望能给读者以启发和帮助。

## P/Invoke

P/Invoke 的前身是当年微软专属的 Java 实现 J++ 当中使用的 J/Direct 技术。和 JNI 技术不同，J/Direct 跨过 Java 虚拟机直接和 Native 代码进行交互，达到了相对更高的性能。后来随着 .NET 技术的兴起，J/Direct 也在 .NET 的世界里以 P/Invoke 的方式得到了重生。

P/Invoke 依托于 CLR 和 JIT，实现了在 .NET 平台对于非托管 DLL 的加载和调用。在介绍 P/Invoke 之前，我们首先了解一下非托管 DLL 的有关知识。

### Native DLL

DLL 是 Windows 平台上专属的动态库格式，具体来说应该被称为 PE/COFF 文件。注意 DLL 实际上是有很多种的，有最普通的 Native 代码生成的 DLL，还有后面会涉及到的 COM DLL，以及 .NET 托管 DLL。这里主要介绍 Native DLL，即非托管 DLL。Win32 大部分类库，以及我们自己使用 C/C++ 代码编译生成的都是这种 DLL。

DLL 技术是整个 Win32 运行库的基础。Win32 绝大部分 API 都是通过 DLL 暴露给开发者的。DLL 技术本身也极其复杂，这里我们只涉及一些和本文内容有关的知识。

#### DLL 导出

DLL 当中的内容需要显式地导出之后才能使用。这里 DLL 同 Linux 上的 ELF （以及苹果 Darwin 平台上的 Mach-O？）显著不同的一点。ELF 格式是默认导出所有符号的，因此也就不存在导出这个概念了。而在 DLL 中 如果符号没有被导出，那么外部是没有办法使用的，Linker 会找不到对应的内容。

下面是一个 DLL 导出函数的示例：

```cpp
#define EXPORT_API __declspec(dllexport)

EXPORT_API void PrintNumber(int number);
```

`__declspec(dllexport)` 是 Windows 上用于 DLL 导出的一个编译器指令，我们用它来标示想要导出的函数。可以看到，我们使用 `__declspec(dllexport)` 导出了一个名为 `PrintNumber` 的函数。

为了直观的看到 DLL 导出的效果，我们可以使用 `dumpbin` 命令查看生成的 DLL 的具体信息。在 VS 的 Developer Command Prompt 中使用下面的命令：

```plaintext
dumpbin /exports testcpp.dll
```

可以看到类似下面的输出：

```plaintext
....
    ordinal hint RVA      name

          1    0 0001125D ?PrintNumber@@YAXH@Z = @ILT+600(?PrintNumber@@YAXH@Z)
...
```

这里我们省略了部分输出，只保留了我们关心的部分。和本文有关的只有两个值 ordinal 和 name。可以看到我们导出的函数 `PrintNumber` 的 ordinal 是 1，name 是 `?PrintNumber@@YAXH@Z`。下面我们分别介绍一下。

ordinal，即函数序号，在上古时期由于内存十分有限，需要通过序号而不是名字来对 DLL 中的函数进行查找。现在你仍然可以这么做，不过这种做法已经不推荐了。因为使用序号会导致 DLL 更新变得异常困难，维护名字显示要比维护序号更加自然和容易。因此我们对于 DLL 函数中的调用主要依赖于函数的名字，即这里的 name。

熟悉 C\+\+ 的同学可以看出来，这里编译器对于 C++ 的函数名称进行了修饰(mangling)，因此导出的函数名字和最初定义的并不完全一致。由于这种命名修饰和编译器版本相关，即可能随着编译器更新而发生变化。因此为了方便外部调用，通常我们会使用 C 的方式对函数进行导出：

```cpp
#ifdef __cplusplus
extern "C"
{
#endif
  EXPORT_API void PrintNumber(int number);
#ifdef __cplusplus
}
#endif
```

这样导出函数的名字就和定义是相同的了：

```plaintext
...
    ordinal hint RVA      name

          1    0 000111AE PrintNumber = @ILT+425(_PrintNumber)
...
```

**Bonus**：

细心的同学可能注意到了上面的 name 区域有一个 = 等于号，这其实是 DLL 中的导出重命名。我们可以看到，尽管使用了 C 方式导出，其实也有名称修饰发生（函数名称前面加了一个下划线），为了处理各种各样的名称修饰，DLL 当中的重命名就显得非常有必要了。使用导出重命名可以让导出的名称保持干净。

DLL 导出还有另一种方式，是使用 `def` 文件，即模块定义文件(module definition file)。`def` 文件的作用就可以看成是一种导出重命名。例如我们有另一个函数：

```cpp
void PrintNumber2(int number)
{
// impl
}
```

定义下面的 `def` 文件：

```plaintext
LIBRARY

EXPORTS
    ; Explicit exports can go here
	PrintNumber2
```

导出的 DLL 会出现：

```plaintext
...
    ordinal hint RVA      name

          2    0 000111AE PrintNumber = @ILT+425(_PrintNumber)
          1    1 00011393 PrintNumber2 = @ILT+910(?PrintNumber2@@YAXH@Z)
...
```

可以看到 `def` 文件和 `__declspec(dllexport)` 可以同时使用而不会出现错误，不过个人并不推荐这种用法。因为大部分情况下使用 `def` 文件并没有显著的好处，而维护两种导出函数的方法总是不如维护一种。相比之下，笔者更倾向于维护代码形式的 `__declspec`。

#### DLL Runtime Library

在编写 C/C\+\+ 类库的时候不可避免地会使用到系统的基础类库，即 runtime library。在 VS 中打开 Project->Properties...->Configuration Properties->C/C++->Code Generation->Runtime Library，可以看到提供了四种 runtime library 版本：

* Multi-threaded (/MT)
* Multi-threaded Debug (/MTd)
* Multi-threaded DLL (/MD)
* Multi-threaded DLL Debug (/MDd)

其中有两个维度的选择，一个是 Debug 或 Release，另一个是使用动态库 DLL 或静态库 Static library。

第一个维度的选择很容易，VS 默认也会帮我们配置好，在 Debug 配置下使用 Debug 版本的 runtime library，可以得到更好的调试体验，在 Release 配置下使用版本的 runtime library，可以获得更好的性能。

另一个维度就需要我们根据具体需求来决定了。在 Debug 环境下使用动态库和静态库除了调试的体验之外实际上没有什么区别，这里就不讨论了。我们只讨论 Release 环境下对于 runtime 库的选择。

**动态库**

一般情况下推荐使用动态库，这样做一个好处是可以减小用户程序的大小，另一个好处是如果 runtime 有更新我们的程序也可以自动用上最新的 runtime。而动态库的坏处就是要求部署的时候对应的 runtime library 也需要部署到用户机器上。可以通过两种方式做到这一点，一种方式是在用户机器上安装微软提供的 Visual C\+\+ Redistributable，另一种方式是跟随程序把 runtime library 也一起部署到用户机器上。

需要特别注意的是，runtime library 是有版本要求的，使用不同版本的 VS 会导致编译出的库依赖不同版本的 runtime library。如果版本对不上，那么 DLL 是没有办法正确加载的。这就是为什么一些程序和游戏在安装的时候，要求我们安装对应版本的 Visual C\+\+ Redistributable。

可以通过 `dumpbin` 命令查看一个 DLL 依赖了哪些其他库，其中就可以找到依赖的 runtime library：

```plaintext
dumpbin /imports testcpp.dll
```

可以得到类似下面的输出：

```plaintext
...
File Type: DLL

  Section contains the following imports:

    VCRUNTIME140.dll
              10002030 Import Address Table
              1000286C Import Name Table
                     0 time date stamp
                     0 Index of first forwarder reference

                   48 memset
                   25 __std_type_info_destroy_list
                    1 _CxxThrowException
                   22 __std_exception_destroy
                   21 __std_exception_copy
                   35 _except_handler4_common
...
```

对于 VS 2015 之前的版本，可以看到带有 MSVCR 和 MSVCP 字样的 runtime library 依赖。

**静态库**

使用静态库的话，就不需要额外在客户的电脑上进行部署了，有关的依赖会被打进 DLL 里面。这样带来的坏处是，如果程序依赖了多个 Native DLL 库，就会保留多份同样的依赖。同时如果不同的 Native 库依赖的 runtime 版本还不是一个，就会导致更加混乱的状况：同一个程序中加载了不同版本的多个 runtime。这种情况会导致程序占用内存变大，同时在 runtime 边界进行编程时也可能会产生错误。

**Bonus**

Debug 版本的 DLL 原则上讲是不能用于分发的。如果你部署把 Debug 版本的应用程序部署到客户机上，同时附带上 Debug 版本的 runtime DLL 理论上讲也能够运行，不过这违反了 VS 的使用条款。

### P/Invoke 基础

非托管代码在 .NET 的世界中被认为是不安全的，要想使用 P/Invoke，首先要在项目中勾选 Allow unsafe code。惯例上我们会把 P/Invoke 方法专门封装到一个类中，其中类的名字指明这些方法是 Native 的。例如我们对前面提到的 PrintNumber 进行封装：

```csharp
public unsafe class NativeApi
{
    [DllImport(".\\testcpp.dll", CallingConvention = CallingConvention.Cdecl)]
    internal static extern void PrintNumber(int number);
}
```

在 C# 中可以直接调用这个方法：

```csharp

private static void InteropCppTest()
{
    NativeApi.PrintNumber(42);
}
```

其中对于 NativeApi 的定义有几个需要注意的点：

* 必须使用 extern，表明这个方法不需要方法体
* 必须使用 static，所有的非托管方法都是可以直接调用的
* 必须给方法加上 DllImport 属性

其中 DllImport 属性我们使用了两个参数，一个是 DLL 路径，另一个是 CallingConvetnion。CallingConvention 在后面的内容中会提到，我们首先看下找 DLL 的问题。DllImport 当中给出了 DLL 的路径，这个位置可以是相对路径，也可以是绝对路径，如果 CLR 找不到对应的 DLL 就会抛出 DllNotFoundException。

### 托管与非托管 DLL 的目标架构

有些时候 DLL 明明找到了，但是系统却抛出了 BadImageFormatException ，排除 DLL 本身是损坏的这种情况，这个 exception 通常是托管程序和非托管 DLL 的架构不一致导致的。

.NET 托管程序默认是平台无关的，并且由于有 JIT 的存在，可以实现在 x86 平台上跑 32 位，在 x64 平台上会跑 64 位，以尽可能地利用平台优势。然而非托管 DLL 则是和平台相关的，并且是在编译时就确定的。对于非托管 DLL 可以使用 dumpbin 命令查看它的架构：

```plaintext
dumpbin /headers testcpp.dll
```

前面若干行输出如下：


```plaintext

File Type: DLL

FILE HEADER VALUES
            8664 machine (x64)
               7 number of sections
        591FCCC4 time date stamp Sat May 20 12:57:40 2017
               0 file pointer to symbol table
               0 number of symbols
              F0 size of optional header
            2022 characteristics
                   Executable
                   Application can handle large (>2GB) addresses
                   DLL
```

可以看到 DLL 头部中清晰地标明了这个一个 64 位的 DLL。

当我们使用 `AnyCpu` 配置编译 .NET 程序时，生成的是完全平台无关的 DLL。如果我们想在这样的 DLL 中调用非托管 DLL，就产生了一个问题：在 x86 平台跑时它只能加载 x86 的非托管 DLL，在 x64 平台跑时同理。如果非托管 DLL 和目标架构和托管程序不一致，就会导致 DLL 不能正确加载，即上面提到的 BadImageFormatException。

要解决这个问题，一种办法是分别给 x86 和 x64 两个平台准备一份非托管 DLL，例如 `testcpp.dll` 和 `testcpp64.dll`，同时在托管代码中也需要根据当前环境，判断调用哪个 DLL 当中的方法。

另一种办法是，强制让 .NET 程序跑在 32 位上，这样只准备一份 x86 位的非托管 DLL 就可以了。这种解决方案之所以可行，一是因为 64 位的 Windows 上本身就可以借助微软的 WoW64 技术直接运行 32 位程序，二是因为 .NET 本身也支持了这个特性。

.NET assembly 支持标志位表明自己是不是要求跑在 32 位下。可以使用 `corflags` 工具查看 .NET assembly 的标志位：

```plaintext
corflags test.exe
```

输出如下所示：

```plaintext
Version   : v4.0.30319
CLR Header: 2.5
PE        : PE32
CorFlags  : 0x1
ILONLY    : 1
32BITREQ  : 0
32BITPREF : 0
Signed    : 0
```

其中 32BITREQ 即表示这个 assembly 是不是要求在 32 位模式下运行。这里输出为 0 表示不要求，那么在 64 位机器上这个程序就会跑在 64 位下。

当我们使用 `x86` 而不是 `AnyCpu` 配置编译程序时，生成的可执行文件会设置 32BITREQ 位。这样这个程序在 64 位机器上会以 32 位程序的形式跑在 WoW64 上，也就可以正常加载 32 位的非托管 DLL 了。

**Bonus**：

如果有同学观察到了 32BITPREF 这个标志位并且对此感到疑惑的话，你需要知道你并不孤单。这个标志位是 .NET 4.5 加入的。它在 VS 里对应的配置是 Any CPU 32-bit preferred。它和 x86 配置的表现是一致的，唯一的区别是在 ARM 平台上 x86 配置编译的程序不能运行，而 Any CPU 32-bit preferred 可以。

### Calling Convention

### blittable 类型

### 托管堆与非托管堆

### Delegate 与 Callback

## COM Interop

### COM - A Better C++

### COM 内存机制

### COM 与 C#

## 参考资料

* https://msdn.microsoft.com/en-us/library/eaw10et3(v=vs.110).aspx
* https://msdn.microsoft.com/en-us/library/04fy9ya1(v=vs.80).aspx
* https://msdn.microsoft.com/zh-cn/library/aa686045.aspx
* https://msdn.microsoft.com/en-us/library/system.gc.keepalive(v=vs.110).aspx
* https://msdn.microsoft.com/en-us/library/ms235282.aspx
* https://www.codeproject.com/Articles/28969/HowTo-Export-C-classes-from-a-DLL
* http://www.davidlenihan.com/2008/01/choosing_the_correct_cc_runtim.html
* http://siomsystems.com/mixing-visual-studio-versions/
* http://blogs.microsoft.co.il/sasha/2012/04/04/what-anycpu-really-means-as-of-net-45-and-visual-studio-11/
