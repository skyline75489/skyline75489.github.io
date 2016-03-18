浅析 iOS 应用网络层设计
====================

移动端开发当中网络层已经成为不可或缺的一部分了，本文尝试着总结一些在 iOS 开发中常见的网络层架构的设计方法和技巧，辅以示例性质的代码，希望能给读者一些启发和帮助。

**注：**这里我们讨论的网络层是基于 HTTP 协议的，不考虑基于其他协议的情况。

### 概述

网络层本身来看是很简单的一层，最开始接触 iOS 开发的同学几乎都在 Controller 里写过类似这样的代码：

```objectivec
AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
[manager GET:@"http://example.com/resources.json" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"JSON: %@", responseObject);
    // 对数据进行处理
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
}];
```

这段代码是从 AFNetworking 2.0 的文档里抄过来的。这样的代码工作起来完全是没有问题的，只不过这种写法的可维护性太差。具体体现在：

1. 地址是写死的字符串，对于一个应用来说，网络请求的地址通常是统一而且具有规律的。如果大量的请求都用这种写法，那么想要统一进行修改的话就变得很困难。
2. 没有统一的请求和响应过滤机制。通常客户端开发当中需要对于请求和响应进行一些处理，例如在请求中加入验证字段（如 Token），以验证请求的合法性。
3. 对 AFNetworking 产生了强依赖，如果要进行网络库的替换，成本会非常高。

随着应用复杂程度的增加，上面这种在控制层直接对网络请求层进行交互的方式，会产生越来越多的问题。因此有必要通过单独的一层把控制层（业务层）和网络请求层隔离开来，这一层我们暂时把它叫做“网络封装层”。

围绕网络封装层，可以展开很多的内容有很多。

### 底层网络库的选择

网络封装层，故名思议是要对下层的网络请求库再次进行封装。如果你想从头自己写底层网络请求库的话，当然也是可以的，不过我们这里主要考虑使用第三方库的情况。下层网络库当中鼎鼎大名的 AFNetworking，几乎已经 iOS 开发必备了。然而 AFNetworking 当前也产生了 2.0 和 3.0 两个大版本直接的分裂。目前 AFNetworking 2.0 官方已经不再提供支持了，其所依赖的 NSURLConnection 系列类也已经被苹果废弃了，意味着苹果官方也不再推荐。因此 AFNetworking 3.0 版本是目前开发的首选（需要兼容旧版本 iOS 的情况下除外）。

尽管 AFNetworking 对外提供的 API 变化不大，这里我们还是需要注意一下 AFNetworking 3.0 和 2.0 版本架构上的一个主要变化，因为这会影响到我们后续的封装层的设计：

> AFN3 以 Session 为中心，AFN2 以 Operation 为中心。

这种区别来源与它们下层的依赖，AFN3 依赖的较新的 NSURLSession API，AFN2 依赖于 NSURLConnection 和 NSOperation。

Session 提供了一个较为中心的管理机制，可以通过配置 NSURLSessionConfiguration 来控制一系列请求。而 Operation 则提供了较为分散的管理方法，不同的 Operation 之间没有太大的联系，可以独自进行配置。

### 封装层的架构风格

同上面的请求层类似，常见的封装层架构设计也有两种，中心化和分散化（在 casatwy 老师的文章里被称为集约型和离散型）。

#### 中心化设计

中心化的设计通常使用一个独立的类来处理所有的网络请求，其中不同的请求可以通过不同的传参来区分：

```objectivec
NSDictionary *params = @{/*参数*/};
[JLGithubApi requestApi:JLGithubUserApi params:params success:^(NSURLSessionTask *task, id responseObject) {
    NSLog(@"JSON: %@", responseObject);
} failure:^(NSURLSessionTask *operation, NSError *error) {
    NSLog(@"Error: %@", error);
}];]
```

另外一种方式，也可以封装通过不同的函数来对网络操作进行区分，进一步降低上层的调用成本：

```objectivec
/**
JLGithubApi.h
*/

/**
*	获取用户信息
*/
- (NSURLSessionTask *)getUserInfo:(NSString*)userId success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

/**
*	获取仓库信息
*/
- (NSURLSessionTask *)getRepoInfo:(NSString*)repoId success:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;
```

进一步地，我们还可以利用 OC 的 category 特性，来对于不同的业务进行分离，形成诸如下面这样诸多的 category:

* JLGithubApi+Repo.h
* JLGithubApi+User.h
* JLGithubApi+Search.h
* ...

注意到我们这里采用的是 NSURLSession 系列 API（AFN 3.0），因为 NSURLSession 本身就是基于 Session 的中心化的管理，我们可以很方便的对于所有使用 `JLGithubApi` 发出的请求进行统一处理：

```objectivec
- (void)configureManagerIfNeeded {
    if ([JLGithubUser currentUserToken]) {
        [self updateManagerConfigurationUsingToken:[JLGithubUser currentUserToken]];
    }
}

- (void)updateManagerConfigurationUsingToken:(NSString *)token {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.HTTPAdditionalHeaders = @{@"Token": token};
    // 注意这里只能新建一个 manager，修改旧的是没用的
    // 这是 NSURLSession 的设计，详见 NSURLSession 官方文档
    _manager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString: kApiBaseURL] sessionConfiguration:config];
}
```

通过类似这样的方式，我们可以给所有的请求加入 token 头部，以通过服务器端的验证。

采用中心化的设计一个很优秀的例子是 [Moya](https://github.com/Moya/Moya/blob/master/docs/Examples.md) 这个 Swift 库，其底层依赖于 [Alamofire](https://github.com/Alamofire/Alamofire)（即 AFN 3.0 的 Swift 版）。它利用 Swift 强大的枚举类型，实现了很优雅的 API 设计：

```swift
// API 配置
enum GitHub {
    case Zen
    case UserProfile(String)
}

extension GitHub: TargetType {
    var baseURL: NSURL { return NSURL(string: "https://api.github.com")! }
    var path: String {
        switch self {
        case .Zen:
            return "/zen"
        case .UserProfile(let name):
            return "/users/\(name.URLEscapedString)"
        }
    }
    var method: Moya.Method {
        // all requests in this example will use GET.  Usually you would switch
        // on the enum, like we did in `var path: String`
        return .GET
    }
    var parameters: [String: AnyObject]? {
        return nil
    }
}

// 调用 
provider.request(.Zen) { result in
    switch result {
    case let .Success(moyaResponse):
        let data = moyaResponse.data
        let statusCode = moyaResponse.statusCode
        // ...
    case .Failure(error):
        // ...
    }
}
```

#### 分散化设计

分散化的设计可以认为是参考了设计模式当中的[命令模式](http://blog.csdn.net/zhengzhb/article/details/7550895)，把不同的网络请求全部都封装成类：

```objectivec
JLGithubUserRequest *req = [JLGithubUserRequest alloc] initWithUser:currentUser];
[req startWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"JSON: %@", responseObject);
} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
}];
```

采用分散化设计的一个开源例子是 [YTKNetwork](https://github.com/yuantiku/YTKNetwork)，在对网络层进行封装的基础之上，还加入了缓存，批量请求发送等功能。

不出意料，YTKNetwork 基于 AFN 的 2.0 版本，以 Operation 为中心的请求控制和 YTK 基于类的设计衔接很自然。可以想象，如果要升级依赖到 AFN 3.0 版本，一些设计上的东西就要重新考虑了（见[这个 issue](https://github.com/yuantiku/YTKNetwork/issues/133)）。

同样考虑上面的请求的 Token 问题，如果使用分散化的设计（在这里以 YTKNetwork为例），比较好的解决办法就是创建基类，在基类里进行统一的控制：

```objectivec
@interface JLGithubBaseRequest : YTKRequest

@end

@implementation JLGithubBaseRequest

- (NSDictionary *)requestHeaderFieldValueDictionary
{
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:[super requestHeaderFieldValueDictionary]];
    [headers setObject:[NSString stringWithFormat:@"Token %@", [JLGithubUser currentUserToken]] forKey:@"Authorization"];
    return headers;
}
```

### 设计选择？

上面提到的中心化和分散化的两种设计，有着很鲜明的区别。以我目前浅薄的经验看，根据业务量的不同，可以大致这样进行选择：

* 请求数量在 10 种以下：随便选
* 10 - 100：中心化更加方便
* \>100：分散化是必然的趋势

这种选择主要是取决于这两种设计在下面几个方面的区别：

#### 实现的复杂度

很明显，中心化的设计对于编码的要求要低一些，一方面是因为没有了基类和各种继承关系，所需要的源代码文件就要少很多，另一方面分散化的设计当中，每一个请求类的 URL，参数等等都需要单独处理，也显得很啰嗦。

#### 灵活性

分散化的设计在灵活性上是要强出很多的，通过不同的基类和继承关系，可以构建出不同系列的请求。例如我们也一些请求是 Token 验证的，有一些是 Cookie 验证的（通常和 H5 结合的部分），那么通过两个不同的请求基类就可以实现。如果使用中心化的设计，这种情况就会显得比较棘手。

#### 模块化

中心化的设计实现了层次之间的解耦，但是没有实现横向的模块化。假设我们有不同的人在开发不同的业务，中心化的设计很可能会导致大家都要去修改同一个文件。而分散化的设计则完全避免了这一点，对于不同的业务来说，修改的文件不会是同一个，互相之间不会产生依赖，在此基础上可以很方便地对于代码进行模块化的分割。

### 总结

设计从来都是只有最好，没有更好。网络层作为 App 开发当中十分核心的一部分，有必要去根据业务场景去精心设计，不断打磨。如果对文章内容有疑问的话，欢迎邮件骚扰 :) 。

**参考资料**：

* http://casatwy.com/iosying-yong-jia-gou-tan-wang-luo-ceng-she-ji-fang-an.html
* http://blog.cnbluebox.com/blog/2015/05/07/architecture-ios-1/
* https://github.com/changjianfeishui/XBBusinessManager