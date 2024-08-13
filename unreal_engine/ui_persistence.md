# UI 的自动销毁和常驻

从 5\.4 版本开始，引擎增加了在切换场景（World）时自动销毁 UI 的机制，同时支持 UI 常驻，允许某些挂载到视窗（Viewport）下的 UserWidget 在切换场景时保留，源码请见 GameViewportSubsystem\.cpp，`UGameViewportSubsystem::HandleRemoveWorld` 函数：

```cpp
// GameViewportSubsystem.cpp

void UGameViewportSubsystem::HandleRemoveWorld(UWorld* InWorld)
{
    // 在切换 World 的时候，收集需要销毁的 UserWidget
    TArray<UWidget*, TInlineAllocator<16>> WidgetsToRemove;
    for (FViewportWidgetList::TIterator Itt = ViewportWidgets.CreateIterator(); Itt; ++Itt)
    {
        if (UWidget* Widget = Itt.Key().ResolveObjectPtr())
        {
            // 销毁属于当前 World，且没有标记为常驻的 UserWidget
            if (Itt.Value().Slot.bAutoRemoveOnWorldRemoved && InWorld == Widget->GetWorld())
            {
                WidgetsToRemove.Add(Widget);
            }
        }
        else
        {
            Itt.RemoveCurrent();
        }
    }
    // 销毁收集到的 UserWidget
    for (UWidget* Widget : WidgetsToRemove)
    {
        Widget->RemoveFromParent();
    }
}
```

UserWidget 是否常驻，通过 `FGameViewportWidgetSlot` 类的 `bAutoRemoveOnWorldRemoved` 属性进行标注，默认非常驻。源码请见 GameViewportSubsystem\.h：

```cpp
// GameViewportSubsystem.h

USTRUCT(BlueprintType)
struct FGameViewportWidgetSlot
{
    GENERATED_BODY()

    // ...

    // 为 true 表示非常驻，为 false 表示常驻
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "User Interface")
    bool bAutoRemoveOnWorldRemoved = true;
}
```

修改 UserWidget 常驻状态的做法是通过 `UGameViewportSubsystem` 类单例找到 UserWidget 对应的 `FGameViewportWidgetSlot` 类型对象，然后修改 `bAutoRemoveOnWorldRemoved` 属性，示例如下：

```cpp
/**
 * @param   UserWidget  已经挂载至 Viewport 的 UserWidget
 * @param   bPersistent UserWidget 是否常驻
 */
void SetUserWidgetPersistent(UUserWidget* const UserWidget, const bool bPersistent)
{
    // 获取当前 Viewport 下的 World，也可以通过 UserWidget->GetWorld() 获取
    const FWorldContext* const WorldContext = GEngine ? GEngine->GetWorldContextFromGameViewport(GEngine->GameViewport) : nullptr;
    if (UGameViewportSubsystem* const Subsystem = WorldContext ? UGameViewportSubsystem::Get(WorldContext->World()) : nullptr)
    {
        FGameViewportWidgetSlot ViewportSlot = Subsystem->GetWidgetSlot(UserWidget);
        // FGameViewportWidgetSlot::bAutoRemoveOnWorldRemoved 的含义与 bPersistent 相反
        if (ViewportSlot.bAutoRemoveOnWorldRemoved == bPersistent)
        {
            ViewportSlot.bAutoRemoveOnWorldRemoved = !bPersistent;
            Subsystem->SetWidgetSlot(UserWidget, ViewportSlot);
        }
    }
}
```
