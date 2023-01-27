# 软链接在 Mac 系统上的构建

如果需要在 Mac 系统上以外链方式将某个目录接入到项目中，可以采用类似在 Windows 系统上构建软链接的做法。在 Windows 上使用的命令是 `mklink`，而在 Mac 上使用的命令是 `ln`，此外填入的**路径参数必须为绝对路径**，否则构建出来的软链接是无效的。命令如下：

```shell
$ ln -s {源目录} {目标目录}
```

示例：

```shell
$ ln -s "/Users/a4399/UE4/alba/Source/Framework" "/Users/a4399/UE4/MyProject/Source/Framework"
$ ln -s "/Users/a4399/UE4/alba/Plugins/Independent/UnLua" "/Users/a4399/UE4/MyProject/Plugins/UnLua"
```


## 参考资料

+ [Mac 上的 ln 命令](http://www.wuliaole.com/2017/02/18/symlink_on_mac_os/)
