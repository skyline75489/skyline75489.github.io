j,z和fasd——Shell目录跳转工具
==========================

经常在命令行下工作的人应该都会遇到过这种情况，需要在几个目录直接来回跳转，不停的cd，效率很低，有的时候还容易进入错的目录。虽然有pushd和popd这样的命令存在，但是还是不能做到随心所欲的跳转。于是一些目录跳转工具就被发明出来了。它们的基本原理是，在每次cd的时候记录当前的路径，将这些路径按照cd进入的次数排序，也就是学习你经常使用的目录。在学习一段时间之后，基本上可以通过前几个字母就能区分出你想进入的目录了，然后就可以输入前几个字母直接进行跳转，而不需要各种cd。

这类工具中最早的应该是大名鼎鼎的[autojump](http://linux.cn/article-3401-1.html)，因为它的快捷命令是j，所以大家也都习惯性地称其为j。[autojump](http://linux.cn/article-3401-1.html)使用Python编写，对于Bash和Shell的支持都比较好。但是可能是因为是Python写的吧，有的时候会感觉反应有些慢。

有了j之后，又有了[z](https://github.com/rupa/z)。[z](https://github.com/rupa/z)的介绍就是"更好的j"。它的功能和j基本是相同的，不过它使用Shell脚本编写，更加简洁，基本上不会拖慢终端的响应速度。我比较喜欢简洁的，现在看来Github上大部分人也是, [z](https://github.com/rupa/z)得到了3000+的star，超越了它的前辈[autojump](http://linux.cn/article-3401-1.html)。

然后人们还不满足，于是又有了大杀器[Fasd](https://github.com/clvv/fasd)，[Fasd](https://github.com/clvv/fasd)不光会记录目录，还会记录文件，也就是说它可以做到快捷打开某个深层目录的文件。[Fasd](https://github.com/clvv/fasd)还可以通过配置，实现更加高级的功能。[Fasd](https://github.com/clvv/fasd)与Zsh的结合也非常好，可以使用tab灵活的在几个目录中选择。可能是由于[Fasd](https://github.com/clvv/fasd)太强大了，虽然它使用Shell脚本写的，但是在使用的时候还是会感觉拖慢了终端的速度，特别是在执行ls -l的时候，会感觉输出明显慢了一拍。

三个工具各有各的特点，人们在追求命令行工作的效率上真的是永无止境的。如果有新的，更好的工具出现，欢迎告诉我。
