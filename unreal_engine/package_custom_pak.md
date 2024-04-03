# 打包时自定义 PAK 文件

## 背景说明

使用 Project Launcher 打包工程时，引擎通常会对工程内的资产进行烘焙（Cook），构建成 PAK 文件，然后放入包内。如果需要将 PAK 文件归档（生成 Release），引擎就会将本次打包产生的 **PAK 文件** ，**AssetRegistry\.bin 文件** 和 **Metadata 目录** 归档，作为一个 Release。然而，如果我们想重新对之前的某一个 Release 进行打包，这个流程就不适用了，此时我们需要设法自定义包内的 PAK 文件。

通常打包流程包含 **构建（Build）** ，**烘焙（Cook）** ，**暂存（Stage）** 和 **打包（Package）** 这几个关键步骤。其中，打包步骤会将暂存步骤中产生的 PAK 文件或散列的资产文件放入包内。由此可知，自定义包内 PAK 文件的关键是 **将暂存目录（Saved/StagedBuilds）下的 PAK 文件替换为我们期望打包的 PAK 文件** 。


## 操作方法

因为 Project Launcher 将暂存和打包两个步骤合并执行，所以我们不能使用 Project Launcher，而是需要自行编写脚本，调用 Unreal Automation Tool 的命令行来打包。以打包 Android 平台为例，关键步骤如下：

1. 调用一次 Unreal Automation Tool 的命令行，完成 **除打包之外** 的步骤

    如果本次打包需要产生 Release，就需要执行 **构建** ，**烘焙** 和 **暂存** 三个步骤，命令行示例如下：

    ```bat
    :: 通过 -skippackage 参数跳过打包步骤
    > D:\UE\Engine\Build\BatchFiles\RunUAT.bat ScriptsForProject=D:\MyProject\MyProject.uproject BuildCookRun -project=D:\MyProject\MyProject.uproject -noP4 -clientconfig=Development -serverconfig=Development -nocompileeditor -unrealexe=D:\UE\Engine\Binaries\Win64\UnrealEditor-Cmd.exe -utf8output -platform=Android -cookflavor=ASTC -build -cook -stage -skippackage
    ```

    如果本次打包不需要产生 Release，就只需要执行 **构建** 步骤，命令行示例如下：

    ```bat
    :: 通过 -skipcook 和 -skipstage 参数跳过烘焙和暂存步骤
    > D:\UE\Engine\Build\BatchFiles\RunUAT.bat ScriptsForProject=D:\MyProject\MyProject.uproject BuildCookRun -project=D:\MyProject\MyProject.uproject -noP4 -clientconfig=Development -serverconfig=Development -nocompileeditor -unrealexe=D:\UE\Engine\Binaries\Win64\UnrealEditor-Cmd.exe -utf8output -platform=Android -cookflavor=ASTC -build -skipcook -skipstage -skippackage
    ```

2. 如果本次打包需要产生 Release，除了引擎在烘焙步骤中产生的内容外，还需要 **手动归档暂存目录（Saved/StagedBuilds）下的内容** ，包括引擎和工程中不放入 PAK 文件内的资产，这些资产需要与 PAK 文件一起放入包内

    暂存目录下的内容示例如下：

    ```
    StagedBuilds/
        Android_ASTC/
            Engine/
                Content/
                    ...
                Extras/
                    ...
            MyProject/
                Content/
                    FMOD/
                        ...
                    Movies/
                        ...
                    Paks/
                        MyProject-Android_ASTC.pak
            Manifest_DebugFiles_Android.txt
            Manifest_NonUFSFiles_Android.txt
            Manifest_UFSFiles_Android.txt
            UECommandLine.txt
    ```

3. 将某次 Release 的内容复制到 **暂存目录（Saved/StagedBuilds）** 下，替换原有的内容，替换后应保持目录结构不变；原则上除了 PAK 文件外，还包括手动归档的，不放入 PAK 文件内的资产

4. 再次调用 Unreal Automation Tool 的命令行，**只执行打包** 步骤

    **请务必在命令行中添加 `-skippak` 参数** ，否则引擎就会在执行打包步骤时，重新将烘焙目录（Saved/Cooked）下的资产构建成 PAK 文件，并且覆盖我们在暂存目录下放置的 PAK 文件。命令行示例如下：

    ```bat
    :: 通过 -skipbuild 参数跳过构建步骤
    :: 通过 -package 参数执行打包步骤
    > D:\UE\Engine\Build\BatchFiles\RunUAT.bat ScriptsForProject=D:\MyProject\MyProject.uproject BuildCookRun -project=D:\MyProject\MyProject.uproject -noP4 -clientconfig=Development -serverconfig=Development -nocompileeditor -unrealexe=D:\UE\Engine\Binaries\Win64\UnrealEditor-Cmd.exe -utf8output -platform=Android -cookflavor=ASTC -skipbuild -skipcook -skipstage -skippak -package
    ```
