# SObjectTableRow 类触摸事件的问题

截至 UE5\.3，所有 Slate 层基类是 `SObjectTableRow` 的类型（在 UMG 层是继承了接口类 `IUserObjectListEntry` 的 `UUserWidget` 类派生类），例如 ListView，TileView 和 TreeView 控件的 Entry 类型，都存在这样的问题——UMG 层的 `OnTouchStarted` 函数无法被调用。

这个问题的原因是 `SObjectTableRow` 类重写了 `OnTouchStarted` 函数，只处理拖拽，没有调用父类 `SObjectWidget` 的 `OnTouchStarted` 函数，导致触摸事件无法传递至 UMG 层。关键源码如下：

```cpp
// SObjectTableRow.h

// ...

template <typename ItemTYpe>
class SObjectTableRow : public SObjectWidget, public IObjectTableRow
{
    // ...

    virtual FReply OnTouchStarted(const FGeometry& MyGeometry, const FPointerEvent& InTouchEvent) override
    {
        //TODO: FReply Reply = SObjectWidget::OnTouchStarted(MyGeometry, InTouchEvent);
        bProcessingSelectionTouch = true;

        return FReply::Handled();
    }

    // ...
}

// ...
```

我们对此与 Epic 做了沟通，官方表示引擎目前没有一个通用的方法来判断拖拽应该由 UMG 层的 `UUserWidget` 类还是由 Slate 层的 `SObjectTableRow` 类来处理，为了确保后者能够处理拖拽从而采用了这种临时的写法。

至于解决方法，官方表示最简单的方法是实现一个 `SObjectTableRow` 类的派生类，并重写 `OnTouchStarted` 函数。如果打算从引擎源码入手，修改 `SObjectTableRow` 类 `OnTouchStarted` 函数的实现，可以参考以下代码：

```cpp
virtual FReply OnTouchStarted(const FGeometry& MyGeometry, const FPointerEvent& InTouchEvent) override
{
    // 如果 UUserWidget 类处理了拖拽，就不再让 SObjectTableRow 类处理拖拽
    {
        const FReply& Reply = SObjectWidget::OnTouchStarted(MyGeometry, InTouchEvent);
        if (Reply.IsEventHandled() && Reply.GetDetectDragRequest().IsValid())
        {
            return Reply;
        }
    }
    /**
     * 如果 UUserWidget 类没有处理拖拽，或者没有监听触摸事件，就丢弃 UUserWidget 类返回的处理结果；
       由 SObjectTableRow 类处理拖拽并返回处理结果
     */
    bProcessingSelectionTouch = true;
    return FReply::Handled()
        .DetectDrag(SharedThis(this), EKeys::LeftMouseButton);
}
```
