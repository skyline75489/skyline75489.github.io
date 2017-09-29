C++/CLI——想说爱你不容易
=====================

在之前一篇介绍 C# Interop 的[文章](https://skyline75489.github.io/post/2017-5-20_advanced_csharp_native_interop.html)中，对于 C\+\+/CLI 部分选择一笔带过，原因也提到了，C\+\+/CLI 本质上和 P/Invoke 是同一种技术，只不过在语言层面用法不同。后面在工作中发现，C\+\+/CLI 技术还是有它独到的地方，在这里简单介绍一下，期望能给读者带来启发和帮助。

### C++/CLI 是什么

C\+\+/CLI 是微软推出的一个跑在 CLI 上的语言，它的主要特性都包含在名字里了：

1. 语法基于 C\+\+，理论上讲是 C\+\+ 语言的超集，面向 CLI 部分的语法是微软自创的一套新语法。
2. 目标平台是 CLI。和同门师兄弟 VB.NET，C# 和 F# 一样，C\+\+/CLI 以 CLI 平台为目标编译平台，因此天生具有和其他 CLI 语言的互操作性。

### C++/CLI 的优势

C\+\+/CLI 最大的一个优势，是可以直接和原生 C/C\+\+ 代码进行混合编译，使用 C/C\+\+ 的函数和数据结构（被微软称为 mixed mode 编程）。这个优势在进行 .NET 平台和 Native 代码互操作编程时体现的尤其明显。

首先，使用 C\+\+/CLI 调用 Native 代码时，再也不需要编写额外的 P/Invoke 代码，只需要引入头文件，然后直接调用就可以了：

```cpp
#include <curl\curl.h>

ref class CuryEasy
{
  public:
    CurlEasy()
    {
      easy = curl_easy_init();
    }

  private:
    CURL* easy;
}
```

调用 Native 代码在 C\+\+/CLI 中的体验和调用自身的方法几乎是完全一样的，背后是 C\+\+/CLI 编译器自动帮我们做了类似 P/Invoke 的脏活累活。当需要使用的结构很多时，如果不使用代码生成工具，手写 P/Invoke 的工作量是很大的，同时也很容易出错。在这一点上 C\+\+/CLI 的优势是 P/Invoke 难以比拟的。

在此基础之上，C\+\+/CLI 由于可以直接使用 Native 的类型和函数签名，在编译期间就可以进行类型检查，相比 P/Invoke 而言，类型安全性得到了更好的保障，很难再出现写 P/Invoke 代码时由于函数签名或者参数类型写错导致的运行期错误。

另外如果需要在原生 C/C\+\+ 代码上进行封装，封装的代码也可以和 C\+\+/CLI 工程直接混编在一起，不需要再用新的工程，打新的 DLL，这在使用 P/Invoke 时也是没办法做到的。

最后，C\+\+/CLI 和 P/Invoke 相比，其封装面向 .NET 平台而言更加自然。使用 P/Invoke 只能进行 static 函数的封装，而使用 C\+\+/CLI 可以封装出对象。同时前面提到，跑在 CLI 平台的若干种语言都有很好的互操作性，生成的 DLL 可以直接在 C# 工程中导入使用，就像使用普通的 C# DLL 一样，体验非常顺畅。

### C++/CLI 的劣势

讲完了优势，下面该谈一下 C\+\+/CLI 语言的劣势了。

首当其中的，应该是 C\+\+/CLI 的学习曲线。我们知道 C\+\+ 语言本身的语法已经很复杂，C\+\+/CLI 在 C\+\+ 的基础上又加入了自己一套新的语法，这两套东西交织起来，使得 C\+\+/CLI 的语法充满了魔幻色彩：

```cpp
#include <curl\curl.h>

namespace CurlCLIWrapper
{
  using namespace msclr::interop;

  public delegate void DataHandlerDelegate(array<System::Byte>^);
  public delegate void HeaderHandlerDelegate(String^);

  ref class CurlEasy
  {
    [UnmanagedFunctionPointer(CallingConvention::Cdecl)]
    delegate size_t NativeWriteHandlerDelegate(IntPtr buffer, size_t size, size_t nmemb, IntPtr instream);

    CurlEasy()
    {
      easy = curl_easy_init();

      auto writeHandler = gcnew NativeWriteHandlerDelegate(this, &CurlEasy::NativeWriteHandler);
      writeHandlerGcHandle = GCHandle::Alloc(writeHandler);
      // ...
    }
  }
}
```

除了语法层面的要求之外，使用 C\+\+/CLI 进行 Native 互操作编程，还要求开发人员有 .NET 平台的使用经验，以及在 .NET 平台调用非托管代码的经验。尽管 C\+\+/CLI 和 Native 混合编程部分的代码看起来简单，但是实际上却隐含了对于托管代码和非托管代码交互的正确理解。综合这些因素，相比 C# 的 P/Invoke 技术，C\+\+/CLI 的学习曲线可以说是十分陡峭了。

其次，C\+\+/CLI 由于语言本身的限制，在语法上提供的功能不及 C#，因此易用性上也大打折扣。例如 C\+\+/CLI 当中没有 closure 支持，导致 Action 和 Delegate 使用起来变的麻烦了很多：

```cpp
// 手动创建 Delegate
easy->DataHandler = gcnew DataHandlerDelegate(this, &CurlResponseStream::AppendBuffer);

// 手动创建 Action
easy->InnerCancelAction = gcnew Action<CurlEasy^>(multi, &CurlMulti::Cancel);
```

再例如，C\+\+/CLI 当中，局限于 C\+\+ 语法，LINQ 得不到完整的支持，只能通过静态方法调用实现一部分功能：

```cpp
List<int>^ list = gcnew List<int>();
int i = Enumerable::FirstOrDefault(list);
```

由于 C\+\+/CLI 陡峭的学习曲线和较差的易用性，和 C# 相比使用，做纯 .NET 平台开发时，使用 C\+\+/CLI 无非是自找麻烦。前面我们提到的 C\+\+/CLI 优势都是有关和 Native 交互有关的，可以说 C\+\+/CLI 几乎是专门为 Native Interop 而生的语言。遗憾的是，它也几乎只被大家用来做 Native Interop 了。

这些综合在一起，又进一步导致了 C\+\+/CLI 的另一大劣势——网络上有关资料非常少。由于使用的人本身就不多，不管是国内还是国外，有关 C\+\+/CLI 开发的资料都非常有限，甚至微软官方的文档都不是很全面（国内有一本《精通 .NET 互操作》里面对于 C\+\+/CLI 有部分介绍，算是比较不错的资料了）。有关 C\+\+/CLI 的开源代码和开源项目更是打着灯笼都找不到。这样的环境，又反过来提高了 C\+\+/CLI 的入门门槛，形成了恶性循环。

最后，微软官方自己对于 C\+\+/CLI 技术也是一种不温不火的态度。相比同门师兄 C# 来说，C\+\+/CLI 在 IDE 层面上的支持差的很远，代码的补全和重构等能力不可同日而语。同时微软似乎也没有想改善的意思，甚至从 VS2013 开始就不再支持使用 C\+\+/CLI 创建应用程序了，只支持创建类库。微软这种做法，进一步限制了 C\+\+/CLI 的应用场景。

### 总结

C\+\+/CLI 就是这样一个充满矛盾的技术，一方面在 Native Interop 上有着无可比拟的优势，另一方面在社区和学习难度上又有非常大的劣势。C\+\+/CLI 就像隐藏在石头当中的璞玉，等待着有心人的挖掘。

