P/Invoke 与 DLL 动态加载
=======================

熟悉 P/Invoke 技术的同学应该了解，由于 Attribute 使用的限制，P/Invoke 是不能指定去动态加载某个 DLL 的：

```csharp
public unsafe class NativeApi
{
    public static string DllPath { get; set; }

    //error CS0182: An attribute argument must be a constant expression, typeof expression or array creation expression of an attribute parameter type 
    [DllImport(DllPath, CallingConvention = CallingConvention.Cdecl, EntryPoint = "PrintNumber")]
    internal static extern void PrintNumber(int number);
}
```

也就是说，P/Invoke 的代码在编译期间就需要确实调用哪个 Native DLL，同时在运行期间不能更改。

有些时候，我们需要根据运行环境，加载不同的 DLL。为了解决这个问题，有下面几种常见的解决方案。

第一种办法，也是最容易想到的，就是为不同的 DLL 写两套不同的 P/Invoke 代码，这个办法在之前的 [文章](https://skyline75489.github.io/post/2017-5-20_advanced_csharp_native_interop.html) 就提到过，可以解决不同架构上加载不同 Native DLL 的问题：

```csharp
public unsafe class NativeApi32
{
    [DllImport("testdll32", CallingConvention = CallingConvention.Cdecl, EntryPoint = "PrintNumber")]
    internal static extern void PrintNumber(int number);
}

public unsafe class NativeApi64
{
    [DllImport("testdll64", CallingConvention = CallingConvention.Cdecl, EntryPoint = "PrintNumber")]
    internal static extern void PrintNumber(int number);
}
```

这种办法，如果 P/Invoke 的接口比较多，那么编程实现上会显得比较复杂，也不够优雅。

第二种办法，是放弃使用 P/Invoke，直接用更加底层的 Win32 API 去加载 DLL 并调用其中的方法。这样的方式脱胎于 Win32 C++ 编程，只不过把 Win32 调用改成了 C# P/Invoke：

```csharp
public class TestClass
{
    public static void Main(String[] args)
    {
        IntPtr user32 = LoadLibrary("user32.dll");
        IntPtr procaddr = GetProcAddress(user32, "MessageBoxW");
        MyMessageBox mbx = (MyMessageBox)Marshal.GetDelegateForFunctionPointer(procaddr, typeof(MyMessageBox));
        mbx(IntPtr.Zero, "Hello, World", "A Test Run", 0);
    }

    internal delegate int MyMessageBox(IntPtr hwnd, [MarshalAs(UnmanagedType.LPWStr)]String text, [MarshalAs(UnmanagedType.LPWStr)]String Caption, int type);

    [DllImport("kernel32.dll")]
    internal static extern IntPtr LoadLibrary(String dllname);

    [DllImport("kernel32.dll")]
    internal static extern IntPtr GetProcAddress(IntPtr hModule, String procname);
}
```

这种方式的优点是非常灵活，同时不像第一种方法，需要写两套代码，只要替换掉 `LoadLibrary` 的参数就好了，缺点是编程实现上也是比较繁琐，同时代码量也比直接 P/Invoke 要多不少。

第三种办法，也是本文想推荐的一种方法，是使用 `SetDllDirectory` 这个 Win32 API，动态更改 `DllImport` 的搜索路径，代码类似下面这样：

```csharp
public unsafe class NativeApi
{
    private const string DllName = "testdll";

    public static void LoadX86()
    {
        SetDllDirectory(Path.Combine(AssemblyUtil.ExecutablePath, "x86"));
    }

    public static void LoadX64()
    {
        SetDllDirectory(Path.Combine(AssemblyUtil.ExecutablePath, "x64"));
    }
    
    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern bool SetDllDirectory(string lpPathName);
}
```

这样只需要调用 `LoadX86` 或者 `LoadX64` 方法，就可以动态切换两个不同的 Native DLL 了。这个办法有下面几个需要注意的点：

1. 对 `SetDllDirectory` 必须在调用 `DllImport` 修饰的方法之前，`SetDllDirectory` 的作用是指导 `DllImport` 去找对应的 DLL，因此需要首先调用。
2. `SetDllDirectory` 设置的路径，优先级仍然低于可执行文件所在目录，也就是说如果可执行文件当前目录有一个 `testdll.dll`，通过设置 `SetDllDirectory` 试图去加载其它目录下同名的 `testdll.dll` 是没有用处的。
3. 这个方法并不完全适用于 Win32 C++ 程序，因为 C++ 的 DLL 默认并不是 Delay-Loaded。`SetDllDirectory` 只能影响那些采用 Delay-Loaded Linking 以及使用 `LoadLibrary` 加载的 DLL。对于 C# 来说，默认 DLL 就是 Delay-Loaded，`DllImport` 也不例外，因此这个方法可以直接使用。

有关 `SetDllDirectory` 的更多细节，可以查阅 [MSDN 文档](https://msdn.microsoft.com/en-us/library/windows/desktop/ms686203(v=vs.85).aspx)。

#### 参考资料：

* https://blogs.msdn.microsoft.com/junfeng/2004/07/14/dynamic-pinvoke/
* https://stackoverflow.com/a/2864714/3562486
* https://msdn.microsoft.com/en-us/library/151kt790.aspx?f=255&MSPPError=-2147217396
