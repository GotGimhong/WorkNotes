# 项目在 Mac 系统上的使用


## 项目的构建

在 uproject 文件的右键菜单中，生成 Xcode 项目，启动游戏，与切换引擎版本，这三个功能都依赖 UE4EditorServices.app。然而引擎安装完成后首次运行 UE4EditorServices.app 时，可能会提示没有权限，即使使用 `chmod +x` 为其添加执行权限也无法解决这个问题。

我们可以采用另一种解决方法，步骤如下：

1. 右键 UE4EditorServices.app，选择显示包内容。

2. 找到 Content/MacOS/UE4EditorServices。如无意外这个文件的图标是那种空白文件的图标，表明它属于不可执行的文件，然而它是 UE4EditorServices.app 的核心，因此需要将它变为可执行文件。

3. 启动终端，输入 `chmod +x`，然后将 Content/MacOS/UE4EditorServices 拖入，执行命令。

4. 命令执行完成后，可以发现 Content/MacOS/UE4EditorServices 的图标变成了可执行文件的图标，UE4EditorServices.app 也恢复执行权限了。

> 在 Engine/Binaries/Mac 目录下，除了 UE4EditorServices.app 之外，UnrealCEFSubProcess.app 和 UnrealSync.app 可能也有同样的问题，可以使用相同的方法解决。

使用 uproject 文件右键菜单的生成 Xcode 项目功能是更新项目代码的最简便做法，类似 Windows 中的生成解决方案。当然也可以使用命令行脚本的方式，不过填入的**路径参数必须为绝对路径**，否则会提示找不到 uproject 文件。命令如下：

```shell
$ cd "/Users/{用户根目录}/../{引擎根目录}/Engine/Build/BatchFiles/Mac"
$ sh "/Users/{用户根目录}/../{引擎根目录}/Engine/Build/BatchFiles/Mac/GenerateProjectFiles.sh" -project="/Users/{用户根目录}/../{项目根目录}/{项目名称}.uproject" -game
```

示例：

```shell
$ cd "/Users/a4399/CustomEngine/customengine/Engine/Build/BatchFiles/Mac"
$ sh "/Users/a4399/CustomEngine/customengine/Engine/Build/BatchFiles/Mac/GenerateProjectFiles.sh" -project="/Users/a4399/UE4/MyProject/MyProject.uproject" -game
```


## 问题排查记录

### 编译可能会因为代码编码的问题而失败

请确保所有代码的编码为 **UTF-8**。

### 头文件包含

Mac 和 iOS 上 C++ 的编译检查通常会比较严格，另外包含的头文件中不能出现反斜杠（'\\'）。

### 提示模块循环依赖

报错信息如下：

```
exit with code 5 ，Error : Action graph contains cycle!
```

请检查是否存在两个模块在 build.cs 中相互依赖的情况。因为引擎不允许模块之间互相依赖——如果模块 A 依赖模块 B，模块 B 又依赖模块 A，那么说明这两个模块的设计存在耦合问题。从原理上讲，如果模块 A 和 B 互相依赖，那么在生成动态链接库的时候会先跳转到模块 B，尝试引入模块 B 的信息，在这个过程中又要跳转回到模块 A，从而形成死循环。这就类似头文件互相包含的情形。

### 项目编译后在启动编辑器的过程中出现崩溃

如果更换过 Xcode 版本，在项目编译后可能会在启动编辑器的过程中出现崩溃。建议在 Xcode 中先清理一次项目的编译内容，再执行编译。

## 参考资料

+ [执行 .app 文件提示没有运行权限的解决方法](https://zhuanlan.zhihu.com/p/90691938)

+ [生成 Xcode 项目的方法](https://answers.unrealengine.com/questions/22749/view.html)
