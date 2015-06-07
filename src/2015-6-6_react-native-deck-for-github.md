React Native 开发中遇到的一些坑（持续更新）
=====================================

最近尝试使用 React Native 开发了一些小项目（[Sunshine](https://github.com/skyline75489/Sunshine-React-Native) 和 [Deck](https://github.com/skyline75489/Deck)），体会到了 React Native 开发的强大之处，例如使用 flexbox 布局让 Layout 变得分外简单，更新程序不用重启模拟器，大大提高了开发效率等等。由于 React Native 尚未发布 1.0 版本，本身还并不是很成熟，在开发过程中也遇到了一些坑，在这里记录一下。

1. 升级 React Native 导致程序无法启动
    
    在从 0.4.1 版本向 0.4.2 升级的过程中，不管是使用 `npm update` 还是重新 `npm install` 都会报 `failed to parse query: unknown expression term 'dirname'` 导致 packager 无法启动，重新用 `react-native init` 创建新项目也不行。我向 React Native 官方提了 [issue](https://github.com/facebook/react-native/issues/1213)，也没有得到好的答复，反倒是路过的群众在 issue 下面提出了解决办法——重新安装 watchman:
       
    ```nohighlight
    brew uninstall watchman
    brew install --HEAD watchman
    ```
   
    亲测可行（不愧是高手在民间），看 issue 里官方的意思看样子也不打算再管这个问题了，有解决方案就得了。
   
    最近想从 0.4.4 升级到 0.5.0，不出意外也崩溃了，报找不到 `docblock.js` ，目前还没有找到解决办法，只能继续用 0.4.4 了。
   
2. props 的可变性问题

    在 `render` 方法中不能改变 props 或者 states，例如下面的代码：
    
    ```javascript
    module.exports = React.createClass({
	  handlePress: function() {
	    this.setProps({
	      id: '1',
	    });
	  }, 
	  render: function() {
	    return (
          <View>
            <TouchableOpacity onPress={this.handlePress}>
              <Text>Activity</Text>
            </TouchableOpacity>
          </View>
	    );
	  }
	});
	```

    当点击时，会报
    
    ```nohighlight   
    Error: Invariant Violation: setProps(...): 
    Cannot update during an existing state transition (such as within `render`). 
    Render methods should be a pure function of props and state.
    ```

    大体意思就是在 render 这种需要 props 和 state 进行渲染的方法中，不能再对 props 和 state 进行更新。我的理解是，React 会在 props 和 state 改变的时候调用 render 进行 DOM diff 然后渲染，如果在渲染过程中再对 props 和 state 进行更改，就陷入死循环了。
    
    
3. onPress 属性的正确使用姿势
    
    在 [EventRow.js](https://github.com/skyline75489/Deck/blob/master/App/Components/EventRow.js#L50) 中，当用户点击仓库名或者用户名时，如果使用下面的代码：
    
    ```javascript
    var action = <View style={styles.action}>
                   <Text>{actionDescription}</Text>
                   <TouchableOpacity onPress={this.goToUser(this.props.data.name)}><Text>data.payload.member.login</Text></TouchableOpacity>
                 <Text> to </Text>
    ```
    
    点击时同样会报
    
    ```nohighlight
    Error: Invariant Violation: setState(...): Cannot update ...
    ```
    
    因为 onPress 应该传递进一个函数，在点击的时候执行，而不是传递函数的返回值。上面的写法等于是在渲染的时候执行了 `this.goToUser`，会导致 state 改变。正确的写法是使用匿名函数封装：
    
    ```javascript
    <TouchableOpacity onPress={()=>{
      this.goToUser(this.props.data.name)
     }}>
    </TouchableOpacity>
    ```
    
    
    
4. Navigator 的 pop 方法灵异的行为

    在 [Deck](https://github.com/skyline75489/Deck)，只在 Dashboard 中进行操作，View 的 push 和 pop 都没有问题。如果进入次级 View 中，再点击 Me 进行 Tab 切换，再次回到 Dashboard 之后会发现 Back 按钮不好用了，更诡异的是，用拖拽的方式还能够正常返回。更更诡异的是，对 Me 这个 Tab 做相同的操作不会出现问题，更更更诡异的是，如果不是切换到 Me，而是切换到另两个 Tab，也不会出现问题。。。
    
    其实在点按仓库名或者用户名之后，底部的 Tab 导航应该是隐藏的，可惜这个功能现在还没有实现，有人已经提了 [issue](https://github.com/facebook/react-native/issues/1489)。
    
5. AlertIOS 导致高 CPU 占用

    在 [这里](https://github.com/skyline75489/Deck/blob/master/App/Components/RepoDetail.js#L197) 有一行 AlertIOS 弹出的消息，在我测试的过程中不知道为什么会导致程序 CPU 占用率飙涨到 100%，整个应用近乎卡死。任务监视器显示有一个 `backboardd` 进程在狂消耗 CPU，搜索了半天也没有解决方案。
    
6. 文档不完善

    React Native 的文档现在基本处于半残状态，现有的文档内容都比较少，也缺少例子，很难看懂，像 Navigator 控件，直接看文档基本是看不懂的。还有些内容文档上根本就没有，例如 ActionSheetIOS 和 AdSupport。