Dispatch Source Timer 的使用以及注意事项
=====================================

Dispatch Source Timer 是一种与 Dispatch Queue 结合使用的定时器。当需要在后台 queue 中定期执行任务的时候，使用 Dispatch Source Timer 要比使用 NSTimer 更加自然，也更加高效（无需在 main queue 和后台 queue 之前切换）。

### 创建 Timer

Dispatch Source Timer 首先其实是 Dispatch Source 的一种，关于 Dispatch Source 的内容在这里就不再赘述了。下面是苹果官方文档里给出的创建 Dispatch Timer 的代码：

```objectivec
dispatch_source_t CreateDispatchTimer(uint64_t interval,
              uint64_t leeway,
              dispatch_queue_t queue,
              dispatch_block_t block)
{
   dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
   if (timer)
   {
      dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), interval, leeway);
      dispatch_source_set_event_handler(timer, block);
      dispatch_resume(timer);
   }
   return timer;
}
```

有几个地方需要注意：

1. Dispatch Source Timer 是间隔定时器，也就是说每隔一段时间间隔定时器就会触发。在 NSTimer 中要做到同样的效果需要手动把 repeat 设置为 YES。
2. `dispatch_source_set_timer` 中第二个参数，当我们使用` dispatch_time` 或者 `DISPATCH_TIME_NOW` 时，系统会使用默认时钟来进行计时。然而当系统休眠的时候，默认时钟是不走的，也就会导致计时器停止。使用 `dispatch_walltime` 可以让计时器按照真实时间间隔进行计时。
3. `dispatch_source_set_timer` 的第四个参数 `leeway` 指的是一个期望的容忍时间，将它设置为 1 秒，意味着系统有可能在定时器时间到达的前 1 秒或者后 1 秒才真正触发定时器。推荐在调用时设置一个合理的 leeway 值。同时，就算指定 leeway 值为 0，系统也是无法保证完全精确的触发时间，只是会尽可能满足这个需求。
4. `dispatch_source_set_event_handler` 这个函数在执行完之后，block 会立马执行一遍，后面隔一定时间间隔再执行一次。这也是和 NSTimer 之间的一个显著区别。

### 停止 Timer 

停止 Dispatch Timer 有两种方法，一种是使用 `dispatch_suspend`，另外一种是使用 `dispatch_source_cancel`。

`dispatch_suspend` 严格上只是把 Timer 暂时挂起，它和 `dispatch_resume` 是一个平衡调用，两者分别会减少和增加 dispatch 对象的挂起计数。当这个计数大于 0 的时候，Timer 就会执行。在挂起期间，产生的事件会积累起来，等到 resume 的时候会融合为一个事件发送。需要注意的是，dispatch source 并没有提供 API 用于检测 source 本身的挂起计数，也就是外部不能得知一个 source 当前是不是挂起状态。

`dispatch_source_cancel` 则是真正意义上的取消 Timer。被取消之后如果想再次执行 Timer，只能重新创建新的 Timer。这个过程类似于对 NSTimer 执行 `invalidate`。

另外一个很重要的注意事项，`dispatch_suspend` 之后的 Timer，是不能被释放的！下面的代码会引起崩溃：

```objectivec
- (void)stopTimer
{
    dispatch_suspend(_timer);
    _timer = nil; // EXC_BAD_INSTRUCTION 崩溃
}
```

因此使用 `dispatch_suspend` 时，Timer 本身的实例需要一直保持。使用 `dispatch_source_cancel` 则没有这个限制：

```objectivec
- (void)stopTimer
{
    dispatch_source_cancel(_timer);
    _timer = nil; // OK
}
```