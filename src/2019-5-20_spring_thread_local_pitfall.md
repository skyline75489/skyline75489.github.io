Spring 中使用自定义的 ThreadLocal 存储导致的坑
============================================

Spring 中有时候我们需要存储一些和 Request 相关联的变量，例如用户的登陆有关信息等，它的生命周期和 Request 相同。一个容易想到的实现办法是使用 ThreadLocal：

```java
public class SecurityContextHolder {
    private static final ThreadLocal<SecurityContext> securityContext = new ThreadLocal<SecurityContext>();

    public static void set(SecurityContext context) {
        securityContext.set(context);
    }

    public static SecurityContext get() {
        return securityContext.get();
    }

    public static void clear() {
        securityContext.remove();
    }
}
```

使用一个自定义的 HandlerInterceptor 将有关信息注入进去：

```java
@Slf4j
@Component
public class RequestInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws
            Exception {
        try {
        
            SecurityContextHolder.set(retrieveRequestContext(request));
        } catch (Exception ex) {
            log.warn("读取请求信息失败", ex);
        }

        return true;
    }

    @Override
    public void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler, @Nullable
            ModelAndView modelAndView) throws Exception {
        SecurityContextHolder.clear();
}
```

通过这样，我们就可以在 Controller 中直接使用这个 context，很方便的获取到有关用户的信息：

```java
@Slf4j
@RestController
class Controller {
  public Result get() {
     long userId = SecurityContextHolder.get().getUserId();
     // ...
  }
}
```

这个方法也是很多博客中使用的。然而这个方法却存在着一个很隐蔽的坑：`HandlerInterceptor` 的 `postHandle` 并不总是会调用。

当 Controller 中出现 Exception：

```java
@Slf4j
@RestController
class Controller {
  public Result get() {
     long userId = SecurityContextHolder.get().getUserId();
     // ...
     
     throw new RuntimeException();
  }
}
```

或者在 `HandlerInterceptor` 的 `preHandle` 中出现 Exception：

```java
@Slf4j
@Component
public class RequestInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws
            Exception {
        try {
        
            SecurityContextHolder.set(retrieveRequestContext(request));
        } catch (Exception ex) {
            log.warn("读取请求信息失败", ex);
        }

        // ...
        throw new RuntimeException();
        //...
        return true;
    }
}
```

这些情况下，`postHandle` 并不会调用。这就导致了 ThreadLocal 变量不能被清理。

在平常的 Java 环境中，ThreadLocal 变量随着 Thread 本身的销毁，是可以被销毁掉的。但 Spring 由于采用了线程池的设计，响应请求的线程可能会一直常驻，这就导致了变量一直不能被 GC 回收。更糟糕的是，这个没有被正确回收的变量，由于线程池对线程的复用，可能会串到别的 Request 当中，进而直接导致代码逻辑的错误。

为了解决这个问题，我们可以使用 Spring 自带的 `RequestContextHolder`，它背后的原理也是 ThreadLocal，不过它总会被更底层的 Servlet 的 Filter 清理掉，因此不存在泄露的问题。

下面是一个使用 `RequestContextHolder` 重写的例子：

```java
public class SecurityContextHolder {

    private static final String SECURITY_CONTEXT_ATTRIBUTES = "SECURITY_CONTEXT";

    public static void setContext(SecurityContext context) {
        RequestContextHolder.currentRequestAttributes().setAttribute(
                SECURITY_CONTEXT_ATTRIBUTES,
                context,
                RequestAttributes.SCOPE_REQUEST);
    }

    public static SecurityContext get() {
        return (SecurityContext)RequestContextHolder.currentRequestAttributes()
                .getAttribute(SECURITY_CONTEXT_ATTRIBUTES, RequestAttributes.SCOPE_REQUEST);
    }
}
```


除了使用 `RequestContextHolder` 还可以使用 Request Scope 的 Bean，或者使用 `ThreadLocalTargetSource`，原理上是类似的。

需要时刻注意 ThreadLocal 相当于线程内部的 static 变量，是一个非常容易产生泄露的点，因此使用 ThreadLocal 应该额外小心。


