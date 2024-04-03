# PSO 缓存


## 原理和构建方式

请见以下参考资料：

+ [官方文档](https://dev.epicgames.com/documentation/zh-cn/unreal-engine/optimizing-rendering-with-pso-caches-in-unreal-engine?application_version=5.1)

+ [第三方参考](https://imzlp.com/posts/24336/)


## 问题记录

https://udn.unrealengine.com/s/feed/0D5QP000009GTin0AG

### 1. 自动化构建 PSO 缓存的思路

首先，打包和打补丁可以通过脚本执行 UAT 命令行的方式进行，不需要使用 ProjectLauncher。在此基础上加入 PSO 缓存的构建，就可以实现 PSO 缓存构建和打包/打补丁的一体化了。

通过脚本执行的关键步骤如下：

1. 检查工程是否包含 \.rec\.upipelinecache 文件，这是在运行工程时收集得到的原始 PSO 缓存文件，如果没有这些文件就没有必要构建稳定的 PSO 缓存了

2. 执行 UAT 命令行，完成一次 Cook 操作，目的是更新 \.shk 文件（着色器密钥文件）

3. 执行 ShaderPipelineCacheTools 命令行，整合 \.shk 和 \.rec\.upipelinecache 文件，生成 \.spc 文件，然后 **提交到 Build/\{Platform\}/PipelineCaches/ 目录下**

4. 执行 UAT 命令行，完成一次打包或者打补丁操作；其中包含 Cook 操作，引擎会自动将 Build/\{Platform\}/PipelineCaches/ 目录下的 \.spc 文件转换为 \.stable\.upipelinecache 文件（稳定的 PSO 缓存文件），然后将 \.stable\.upipelinecache 文件放入 PAK 内

### 2. .shk 文件的更新

### 3. .stable.upipelinecache 文件的加载策略

### 4. .stable.upipelinecache 文件的增量更新
