# 对象的生命周期

对象即 `UObject` 类的实例，以下统称为【对象】。


## 生命周期相关的标签

在引擎源码 ObjectMacros\.h 中定义的枚举类型 `EInternalObjectFlags`，用于表示对象内部使用的标签，其中与对象生命周期相关的标签有如下：

+ `Unreachable`

    对象没有被引用（不可达）

    `Unreachable` 标签无法手动添加，也不建议手动移除，它是在垃圾回收时，引擎自动为对象添加的一种标签。在进行垃圾回收的过程中，引擎首先会为所有没有 `RootSet` 标签的对象都添加 `Unreachable` 标签，然后逐个分析引用关系，将被引用对象的 `Unreachable` 标签移除，最后销毁仍然具有 `Unreachable` 标签，即没有被引用的对象。

    与 `PendingKill` 标签的区别在于，具有 `Unreachable` 标签的对象对于游戏逻辑而言很可能依然是有效的，但是它即将会在垃圾回收时被销毁。如果想保留这些对象，就可以为它们添加 `RootSet` 标签。

    `Unreachable` 标签相关接口的使用示例如下，这些接口都可以由 `UObject` 的派生类继承：

    ```cpp
    UObject* MyObject;
    /**
     * 移除 Unreachable 标签
     * 可能会与垃圾回收产生冲突，不建议在游戏逻辑中使用
     * @return 如果对象具有 Unreachable 标签，就返回 true，说明移除成功；反之返回 false，说明移除失败
     */
    bool bSuccessful = MyObject->ThisThreadAtomicallyClearedRFUnreachable();
    /**
     * 检查是否具有 Unreachable 标签
     * @return 如果对象具有 Unreachable 标签，就返回 true；反之返回 false
     */
    bool bUnreachable = MyObject->IsUnreachable();
    /**
     * IsPendingKill 和 IsUnreachable 的并集
     * @return 如果对象具有 PendingKill 或者 Unreachable 标签，就返回 true；反之返回 false
     */
    bool bPendingKillOrUnreachable = MyObject->IsPendingKillOrUnreachable();
    ```

+ `PendingKill`

    对象要求被强制销毁

    具有 `PendingKill` 标签的对象，即使被引用，在垃圾回收时也会被销毁，因为引擎为其添加 `Unreachable` 标签后就不会再移除。对于游戏中需要尽快销毁的对象，可以使用为它们添加 `PendingKill` 标签的做法，例如 `AActor` 类的成员函数 `Destroy`，内部就使用了这种做法。

    `PendingKill` 标签相关接口的使用示例如下，这些接口都可以由 `UObject` 的派生类继承：

    ```cpp
    UObject* MyObject;
    /**
     * 添加 PendingKill 标签
     */
    MyObject->MarkPendingKill();
    /**
     * 移除 PendingKill 标签
     */
    MyObject->ClearPendingKill();
    /**
     * 检查是否具有 PendingKill 标签
     * @return 如果对象具有 PendingKill 标签，就返回 true；反之返回 false
     */
    bool bPendingKill = MyObject->IsPendingKill();
    /**
     * IsPendingKill 和 IsUnreachable 的并集
     * @return 如果对象具有 PendingKill 或者 Unreachable 标签，就返回 true；反之返回 false
     */
    bool bPendingKillOrUnreachable = MyObject->IsPendingKillOrUnreachable();
    ```

+ `RootSet`

    对象处于常驻状态

    具有 `RootSet` 标签的对象，即使没有被引用，也不会受到垃圾回收的影响，因为引擎不会为具有 `RootSet` 标签的对象添加 `Unreachable` 标签。对于游戏中具有较长生命周期的对象，可以通过 `AddToRoot` 让它们处于常驻状态，类似 Unity 中的 `DontDestroyOnLoad`。

    `RootSet` 和 `PendingKill` 这两个标签原则上是互斥的，具有 `RootSet` 标签的对象不能再添加 `PendingKill` 标签，具有 `PendingKill` 标签的对象也不应该再添加 `RootSet` 标签。如果尝试为一个具有 `RootSet` 标签的对象添加 `PendingKill` 标签，就会触发错误（请见 `MarkPendingKill` 函数的实现）；如果尝试为一个具有 `PendingKill` 标签的对象添加 `RootSet` 标签，就会让该对象无法被销毁，因为 `RootSet` 标签的优先级高于 `PendingKill` 标签，虽然不会触发错误，但是在游戏逻辑上可能会让人困扰，因此不建议这种做法。相关的引擎源码如下：

    ```cpp
    /** UObjectBaseUtility.h */

    class COREUOBJECT_API UObjectBaseUtility : public UObjectBase
    {
        // ...
        FORCEINLINE void AddToRoot()
	    {
		    GUObjectArray.IndexToObject(InternalIndex)->SetRootSet();
	    }
        // ...
        FORCEINLINE void MarkPendingKill()
	    {
            /** 如果对象具有 RootSet 标签，就会触发断言错误 */
		    check(!IsRooted());
		    GUObjectArray.IndexToObject(InternalIndex)->SetPendingKill();
	    }
        // ...
    }
    ```

    `RootSet` 标签相关接口的使用示例如下，这些接口都可以由 `UObject` 的派生类继承：

    ```cpp
    UObject* MyObject;
    /**
     * 添加 RootSet 标签
     */
    MyObject->AddToRoot();
    /**
     * 移除 RootSet 标签
     */
    MyObject->RemoveFromRoot();
    /**
     * 检查是否具有 RootSet 标签
     * @return 如果对象具有 RootSet 标签，就返回 true；反之返回 false
     */
    bool bRooted = MyObject->IsRooted();
    ```

在引擎源码 ObjectMacros\.h 中定义的枚举类型 `EObjectFlags`，用于表示对象对外公开的标签，其中与对象生命周期相关的标签如下：

+ `RF_BeginDestroyed`

    对象开始进行，或者已经进行过销毁的预处理（Begin Destroy）

    对象销毁的预处理在 `UObject` 类的成员函数 `BeginDestroy` 函数中进行，这个函数是通过另一个成员函数 `ConditionalBeginDestroy` 驱动的；在 `ConditionalBeginDestroy` 函数中，引擎会为对象添加 `RF_BeginDestroy` 标签。`RF_BeginDestroy` 标签一旦添加就不会移除，即使在进行销毁的后处理时，对象依然具有 `RF_BeginDestroy` 标签。

    ```cpp
    /** Obj.cpp */

    bool UObject::ConditionalBeginDestroy()
    {
        // ...
        check(IsValidLowLevel());
        if (!HasAnyFlags(RF_BeginDestroyed))
        {
            SetFlags(RF_BeginDestroyed);
            // ...
            BeginDestroy();
            // ...
            return true;
        }
        else
        {
            return false;
        }
    }
    ```

+ `RF_FinishDestroy`

    对象开始进行销毁的后处理（Finish Destroy）

    和预处理类似，对象销毁的后处理在 `UObject` 类的成员函数 `FinishDestroy` 函数中进行，这个函数是通过另一个成员函数 `ConditionalFinishDestroy` 驱动的；在 `ConditionalFinishDestroy` 函数中，引擎会为对象添加 `RF_FinishDestroy` 标签。

    ```cpp
    /** Obj.cpp */

    bool UObject::ConditionalFinishDestroy()
    {
        check(IsValidLowLevel());
        if (!HasAnyFlags(RF_FinishDestroyed))
        {
            SetFlags(RF_FinishDestroyed);
            // ...
            FinishDestroy();
            // ...
            return true;
        }
        else
        {
            return false;
        }
    }
    ```


## 对象的销毁

对象的销毁分**预处理（Begin Destroy）**和**后处理（Finish Destroy）**两个阶段，它们都是在垃圾回收的过程中进行的。

### 对象销毁的预处理

在 [生命周期相关的标签](#生命周期相关的标签) 中提到，在垃圾回收时，引擎会为所有不具有 `RootSet` 标签的对象添加 `Unreachable` 标签，再经过引用分析，将被引用对象的 `Unreachable` 标签移除。在此之后，引擎就会收集仍然具有 `Unreachable` 标签，即没有被引用的对象，让它们进入销毁的预处理阶段。

预处理阶段由 `UObject` 类的成员函数 `ConditionalBeginDestroy` 驱动，它的主要作用是为对象添加 `RF_BeginDestroy` 标签，调用 `BeginDestroy`，以及添加性能埋点；成员函数 `BeginDestroy` 则实现预处理的核心逻辑，在游戏逻辑中通常也会被重写以添加定制处理。

```cpp
/** Object.h */

class COREUOBJECT_API UObject : public UObjectBaseUtility
{
    // ...
    virtual void BeginDestroy();
    // ...
    bool ConditionalBeginDestroy();
    // ...
};
```

在 `BeginDestroy` 中，预处理的核心逻辑如下（按照先后顺序）：

1. 解除与连接器（Linker Load）之间的关联

    连接器（主要类型有 `FLinker` 和 `FLinkerLoad`）在引擎中用于加载对象或者游戏资源所在的包（Package）。当对象销毁时，它需要解除与包之间的关联，因此也需要解除与连接器之间的关联。

2. 清除名称

    将对象的名称重置为 `NAME_None`。

3. 解除与包（Package）之间的引用

    每一个对象都会有一个与之关联的包（类型为 `UPackage`）。对于可以动态加载的内容，例如蓝图类，包通常是对应的蓝图资源；对于临时对象，包通常是 /Engine/Transient。对象在创建之后，会引用它所在的包，包也相当于是对象的一个 Outer。当对象销毁时，它需要解除与包之间的引用关系。

因为在基类 `UObject` 当中，`BeginDestroy` 实现了预处理的核心逻辑，所以在派生中重写 `BeginDestroy` 时，需要注意两点：

1. 必须遵循里氏替换原则，调用基类的 `BeginDestroy`，否则会导致预处理出错

2. 定制处理建议在调用基类的 `BeginDestroy` 之前完成，否则定制处理可能会出错，或者出现和预期不符的结果

    ```cpp
    void UMyObject::BeginDestroy()
    {
        /** 在调用基类的 BeginDestroy 之前，仍然可以访问对象的名称，关联的连接器和包 */
        /** 示例：输出结果为对象的有效名称 */
        UE_LOG(LogTemp, Display, TEXT("%s"), *GetName());
        // ...
        Super::BeginDestroy();
        /** 在调用基类的 FinishDestroy 之后，不能再访问对象的名称，关联的连接器和包 */
        /** 示例：输出结果为 None */
        UE_LOG(LogTemp, Display, TEXT("%s"), *GetName());
        // ...
    }
    ```

### 对象销毁的后处理

在垃圾回收时收集到的没有被引用的对象，仅当它们**全部**完成销毁的预处理之后，引擎才会让它们进入销毁的后处理阶段。

垃圾回收存在分帧的机制，通常情况下，当引擎收集完所有没有被引用的对象之后，未必能在同一帧内完成这些对象销毁的预处理，因此引擎会在下一帧继续进行对象销毁的预处理，直至所有对象都完成预处理之后，再统一让它们进入后处理阶段。在游戏逻辑中，也可以使用强制垃圾回收，即以阻塞主线程为代价，暂时打破分帧的机制，迫使引擎在一帧内完成一次完整的垃圾回收。

后处理阶段由 `UObject` 类的成员函数 `ConditionalFinishDestroy` 驱动，它的主要作用是为对象添加 `RF_FinishDestroy` 标签，调用 `FinishDestroy`，以及移除对象销毁的事件监听；成员函数 `FinishDestroy` 则实现后处理的核心逻辑，在游戏逻辑中偶尔也会被重写以添加定制处理。

```cpp
/** Object.h */

class COREUOBJECT_API UObject : public UObjectBaseUtility
{
    // ...
    /**
     * 是否能够进行后处理
     * 默认返回 true；对于绝大多数对象而言，完成预处理后都是能够立即进行后处理的，不过对于部分存在异步清理逻辑的对象，例如某些材质对象需要等待渲染线程释放 Shader 资源，就可以通过这个成员函数让它们的后处理暂时挂起
     */
    virtual bool IsReadyForFinishDestroy();
    // ...
    virtual void FinishDestroy();
    // ...
    bool ConditionalFinishDestroy();
    // ...
};
```

在 `FinishDestroy` 中，后处理的核心逻辑是清除蓝图属性。因此，定制处理建议在调用基类的 `FinishDestroy` 之前完成，否则定制处理可能会出错，或者出现和预期不符的结果。

```cpp
void UMyObject::FinishDestroy()
{
    /** 在调用基类的 FinishDestroy 之前，仍然可以访问蓝图属性 */
    // ...
    Super::FinishDestroy();
    /** 在调用基类的 FinishDestroy 之后，不能再访问蓝图属性 */
    // ...
}
```
