在 Java 中获取泛型中的具体类型
==========================

众所周知，Java 的泛型是通过一种叫做“类型擦除”的技术实现的。因此在 Runtime 的时候，理论上所有的泛型具体类型都应该被擦除掉了。但实际上并不是所有的类型信息都丢失了，Java 仍然可以通过反射的方法在 Runtime 拿到泛型的具体类型。本文就将探讨几种具体情况。

> 对“类型擦除”还不是很了解的同学，可以看一下[这篇文章](https://blog.csdn.net/caihaijiang/article/details/6403349)。

#### 泛型的实现类

例如我们有一个泛型类：

```java
class GenericBase<T> {
}
```

同时，我们有一个类继承了它，并且提供了具体的泛型类型：

```java
class Concrete extends GenericBase<String> {
}
```

此时我们是可以通过反射拿到 Concrete 对应的 T 的类型的：

```java
public class GenericTest {
    @Test
    public void testGeneric1() {
        val type = GenericTypeResolver.resolveTypeArgument(Concrete.class, GenericBase.class);
        Assert.assertEquals("java.lang.String", type.getTypeName());
    }
}
```

这里的 `GenericTypeResolver` 是 Spring 提供了一个工具类。它的底层使用了 Java 的反射，到最底层使用了 JVM 的一个方法 `getGenericSuperclass`。这个方法是一个 native 方法，它通过读取 `.class` 字节码文件当中的 `Signature` 段来获取泛型的类型信息。

> 注意这里“字节码”和 JVM 的区别。字节码是文件，字节码中存储了泛型的有关信息。JVM 是 Runtime 环境。JVM 中所有的类型仍然是被擦除掉的，两者并不冲突。

这种方法的局限在于，必须要实现具体的类型，如果在继承类当中继续使用泛型：

```java
class Concrete<String> extends GenericBase<String> {
}
```

那么这种方法就无法获取 `String` 这个类型了。

#### Field 和 Method Parameter

和前面的思路类似，Java 的字节码层面，类的 Field 和 Method Parameter & Return Type 也是有签名信息的，通过这些签名信息我们可以拿到具体的泛型类型：

```java
public class GenericTest {

    // Field
    List<String> aList;

    @Test
    public void testGenericField() throws NoSuchFieldException {
        java.lang.reflect.Field field = getClass().getDeclaredField("aList");
        val t = ResolvableType.forField(field);
        Assert.assertEquals("java.lang.String", t.getGeneric(0).getType().getTypeName());
    }

    // Method Parameter & Return Type
    public List<Integer> methodWithGenericParameter(List<String> aList) {
        return new ArrayList<>();
    }

    @Test
    public void testGenericMethodParameter() {
        val method = Arrays.stream(getClass().getDeclaredMethods())
                .filter(x -> "methodWithGenericParameter".equals(x.getName()))
                .findAny()
                .get();

        val t = ResolvableType.forMethodParameter(method, 0);
        Assert.assertEquals("java.lang.String", t.getGeneric(0).getType().getTypeName());
    }

    @Test
    public void testGenericReturnType() {
        val method = Arrays.stream(getClass().getDeclaredMethods())
                .filter(x -> "methodWithGenericParameter".equals(x.getName()))
                .findAny()
                .get();

        val t = ResolvableType.forMethodReturnType(method);
        Assert.assertEquals("java.lang.Integer", t.getGeneric(0).getType().getTypeName());
    }
}
```

这里我们使用了 Spring 的 `ResolvableType` 这个工具类。Spring 利用它实现了部分泛型的 Autowired 功能。

同样的，这些方法的局限也显而易见，他们能够 work 的核心在于，字节码层面存储了有关的签名。在 JVM 的 Runtime 层面，类型信息仍然是不可能被拿到的：

```java
public void testGenericInstance() {
    // 这里 aList 当中的 String 类型是无法获取的
    List<String> aList = new ArrayList<>();
}
```

#### 总结

JVM 的类型擦除机制对获取泛型类型上造成了一些限制，但 Java 的反射机制仍然提供了一些特定条件下获取泛型类型的可能性。通过这些工具，我们可以更好的利用 Java 的泛型功能。

#### 参考资料

* https://stackoverflow.com/a/9202329/3562486
* https://stackoverflow.com/questions/42874197/getgenericsuperclass-in-java-how-does-it-work
* https://spring.io/blog/2013/12/03/spring-framework-4-0-and-java-generics