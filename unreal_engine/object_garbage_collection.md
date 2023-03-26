# 对象的垃圾回收

对象的垃圾回收（Garbage Collection），以下简称【GC】。


## 强制垃圾回收的实现原理

引擎每帧都会检测是否需要进行 GC，`UEngine` 的成员属性 `TimeSinceLastPendingKillPurge` 记录上一次 GC 至今的时间间隔，当它大于或者等于成员函数 `GetTimeBetweenGarbageCollectionPasses` 的返回值时，就会执行一次 GC，然后将 `TimeSinceLastPendingKillPurge` 清零。其中，`GetTimeBetweenGarbageCollectionPasses` 返回两次 GC 之间的时间间隔，默认是60秒。强制 GC 的原理就是将 `TimeSinceLastPendingKillPurge` 设置为一个大于 `GetTimeBetweenGarbageCollectionPasses` 返回值的值，从而让引擎在下一帧执行一次 GC。

```cpp
/** UnrealEngine.cpp */

void UEngine::ForceGarbageCollection(bool bForcePurge)
{
    /**
     * 如此一来，TimeSinceLastPendingKillPurge 必然大于 GetTimeBetweenGarbageCollectionPasses 的返回值
     */
    TimeSinceLastPendingKillPurge = 1.0f + GetTimeBetweenGarbageCollectionPasses();
    bFullPurgeTriggered = bFullPurgeTriggered || bForcePurge;
}
```


## 引擎垃圾回收的流程

引擎每帧都会调用 `UEngine` 的成员函数 `ConditionalCollectGarbage` 检查是否需要进行 GC，这也是 GC 流程的入口。

```cpp
/** LevelTick.cpp */

void UWorld::Tick(ELevelTick TickType, float DeltaSeconds)
{
    // ...
    GEngine->ConditionalCollectGarbage();
    // ...
}
```

核心处理位于函数 `CollectGarbageInternal`，引擎源码为 GarbageCollection\.cpp。

通常，对 `GUnreachableObjects` 中的所有不可达对象都执行过一次 `ConditionalBeginDestroy` 后，就可以调用 `IncrementalDestroyGarbage` 执行 `ConditionalFinishDestroy` 了。垃圾回收具有分帧控制，除非是强制执行完全清理，否则如果在限定时间内无法对 `GUnreachableObjects` 都执行过 `ConditionalBeginDestroy`，就先不调用 `IncrementalDestroyGarbage`。

在 `UnhashUnreachableObjects` 函数中执行 `ConditionalBeginDestroy`；在 `IncrementalDestroyGarbage` 函数中执行 `ConditionalFinishDestroy`。


## 相关的引擎源码

+ FastReferenceCollector\.h

+ GarbageCollection\.h 和 GarbageCollection\.cpp

+ UnrealEngine\.cpp
