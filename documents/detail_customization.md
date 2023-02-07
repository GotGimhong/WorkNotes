# 蓝图细节面板的定制


## 概述

在一个蓝图的细节面板（Details）中，会按照类别展示蓝图类包含的蓝图属性。这些蓝图属性的展示是可以定制的，它分为**蓝图类定制（Class Customization）**和**属性类型定制（Property Type Customization）**两种方式。


## 蓝图类定制

蓝图类定制针对的是蓝图类，通常用于**定制蓝图类中的某个蓝图属性**的展示，例如 `UImage` 中的蓝图属性 `ColorAndOpacity`。

它的原理是在细节面板对应的 Slate 控件绘制时插入定制的处理。细节面板是一个**树型结构**，第一层叶子节点是属性的类别，第二层叶子节点是属性本身，绘制过程以**自顶向下**的方式执行。因为引擎提供了默认的绘制实现，所以我们关注需要定制的属性即可，其他的属性交由引擎绘制。

它的核心是实现一个 `IDetailCustomization` 的派生类，重写虚函数 `CustomizeDetails`。这个虚函数有两个重载版本，其中一个引擎提供了默认的实现，我们重写另一个纯虚函数即可（详见引擎源码 IDetailCustomization\.h）。示例如下：

```c++
// 假设需要定制的蓝图类为 UMyBPObj

void FMyBPObjCustomization::CustomizeDetails(IDetailLayoutBuilder& DetailLayout)
{
    // 【可选】获取当前打开的蓝图对象。取决于定制操作是否依赖蓝图对象中的某些数据，如无需要可以跳过
    TArray<TWeakObjectPtr<UObject>> Objects;
    DetailLayout.GetObjectsBeginCustomized(Objects);
    // Objects 通常只有一个元素，即当前打开的蓝图对象，暂未测试出 Objects 长度不为1的情况
    if (UMyBPObj* const Obj = Objects.Num() > 0 ? Cast<UMyBPObj> (Objects[0].Get()) : nullptr)
    {
        // Do something...
    }

    // 加入定制内容
    AddCustomDetails(DetailLayout);
}

void FMyBPObjCustomization::AddCustomDetails(IDetailLayoutBuilder& DetailLayout)
{
    // 目标属性的所属类别
    const FName PropertyCategory = ...;
    // 目标属性的名称
    const FName PropertyName = ...;

    // DetailLayout 是整个细节面板的绘制器，相当于根节点，我们首先要获取到目标属性所属类别的绘制器，即第一层叶子节点
    // 请注意，如果目标属性在定义时没有提供类别，引擎会取它所属蓝图类的显示名称（DisplayName）作为默认类别名称，例如蓝图类 UMyBPObj 的默认类别名称为"My BP Obj"
    IDetailCategoryBuilder& PropertyCategory = DetailLayout.EditProperty(PropertyCategory);
    // 在获取目标属性的绘制器，即第二层叶子节点之前，首先要获取目标属性的句柄
    const TSharedPtr<IPropertyHandle> PropertyHandle = DetailLayout.GetProperty(PropertyName);
    // 获取目标属性的绘制器
    IDetailPropertyRow& PropertyRow = PropertyCategory.AddProperty(PropertyHandle);
    // 目标属性名称部分的 Slate 控件
    TSharedPtr<SWidget> NameWidget;
    // 目标属性主体部分的 Slate 控件
    TSharedPtr<SWidget> ValueWidget;
    FDetailWidgetRow WidgetRow;
    // 获取引擎原本为目标属性提供的默认 Slate 控件
    PropertyRow.GetDefaultWidgets(NameWidget, ValueWidget, WidgetRow);
    PropertyRow.CustomWidget()
        .NameContent()
        [
            // 创建名称部分的定制 Slate 控件，不过通常不需要定制，使用默认的控件即可
            NameWidget.ToSharedRef()
        ]
        .ValueContent()
        // 设置主体部分的宽高，可以采用默认值，也可以自定义
        .MinDesiredWidth(WidgetRow.ValueWidget.MinWidget)
        .MaxDesiredWidth(WidgetRow.ValueWidget.MaxWidget)
        [
            // （关键）创建主体部分的定制 Slate 控件
            // Do something...
        ];
}
```

完整示例可以参考引擎源码 ListViewBaseDetails\.h 和 ListViewBaseDetails\.cpp，它对 `UListView` 类的蓝图属性 `EntryWidgetClass` 进行定制，目的是实现列表项蓝图类的筛选。

需要注意，蓝图类定制仅限在蓝图类中定义的蓝图属性，不包括**从基类中继承**的蓝图属性。示例如下：

```c++
UCLASS()
class UMyBPObjBase : public UObject
{
    GENERATED_UCLASS_BODY()

protected:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MyBPObjBase")
    int32 X;
}

UCLASS()
class UMyBPObj : public UMyBPObjBase
{
    GENERATED_UCLASS_BODY()

protected:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MyBPObj")
    int32 Y;
};

// UMyBPObj 的蓝图类定制
void FMyBPObjCustomization::CustomizeDetails(IDetailLayoutBuilder& DetailLayout)
{
    // 失败：从 UMyBPObj 的蓝图类定制中获取继承自 UMyBPObjBase 的蓝图属性 X
    {
        IDetailCategoryBuilder& PropertyCategory = DetailLayout.EditProperty(TEXT("MyBPObjBase"));
        // PropertyHandle 无效
        const TSharedPtr<IPropertyHandle> PropertyHandle = DetailLayout.GetProperty(TEXT("X"));
    }
    // 成功：从 UMyBPObj 的蓝图类定制中获取自身的蓝图属性 Y
    {
        IDetailCategoryBuilder& PropertyCategory = DetailLayout.EditProperty(TEXT("MyBPObj"));
        // PropertyHandle 有效
        const TSharedPtr<IPropertyHandle> PropertyHandle = DetailLayout.GetProperty(TEXT("Y"));
    }
}
```

如果不希望在派生类的细节面板中显示继承而来的蓝图属性，需要在基类的蓝图类定制中处理。示例如下：

```c++
// UMyBPObjBase 的蓝图类定制
void FMyBPObjBaseCustomization::CustomizeDetails(IDetailLayoutBuilder& DetailLayout)
{
    TArray<TWeakObjectPtr<UObject>> Objects;
    DetailLayout.GetObjectsBeginCustomized(Objects);
    for (const TWeakObjectPtr<UObject>& Obj : Objects)
    {
        if (Obj.IsValid() && Obj->IsA<UMyBPObj>())
        {
            IDetailCategoryBuilder& PropertyCategory = DetailLayout.EditProperty(TEXT("MyBPObjBase"));
            // PropertyHandle 有效
            const TSharedPtr<IPropertyHandle> PropertyHandle = DetailLayout.GetProperty(TEXT("X"));
            PropertyCategory.AddProperty(PropertyHandle).Visibility(EVisibility::Collapsed);
        }
    }
}
```


## 属性类型定制

属性类型定制针对的是可以作为蓝图属性的类型，通常用于定制蓝图结构体的展示，例如 `FSlateBrush`。

它的原理跟蓝图类定制是类似的，一个属性类型可以视为一个**树型结构**，叶子节点是它的蓝图属性，绘制过程以**自顶向下**的方式执行。

它和蓝图类定制的不同之处在于针对的对象不同。例如引擎为 `FSlateBrush` 类型定制了细节面板，那么对于所有使用到 `FSlateBrush` 类型蓝图属性的蓝图类（不限于 `UImage` 类），它们的细节面板中都会用上这种定制。再例如 `UImage` 和 `UTextBlock` 类都有 `ColorAndOpacity` 属性，假如我们通过定制 `UImage` 蓝图类的方式定制 `ColorAndOpacity` 属性的展示，那么这个定制仅限在 `UImage` 类的细节面板中生效，而不会应用到 `UTextBlock` 类的细节面板中。

它的核心是实现一个 `IPropertyTypeCustomization` 的派生类，重写虚函数 `CustomizeHeader` 和 `CustomizeChildren` （详见引擎源码 IPropertyTypeCustomization\.h）。示例如下：

```c++
// 假设需要定制的属性类型为 FMyProp

// 定制 FMyProp 的名称部分，与蓝图类定制中 NameContent 和 NameWidget 的处理相似，通常不需要定制，使用默认方式即可
void FMyPropCustomization::CustomizeHeader(const TSharedRef<IPropertyHandle>& PropertyHandle, FDetailWidgetRow& HeaderRow, IPropertyTypeCustomizationUtils& CustomizationUtils)
{
    // 使用引擎提供的默认 Slate 控件
	HeaderRow
        .NameContent()
        [
            PropertyHandle->CreatePropertyNameWidget()
        ]
        .ValueContent();
}

// 定制 FMyProp 的主体部分，与蓝图类定制中 ValueContent 和 ValueWidget 的处理相似，属于关键部分
void FMyPropCustomization::CustomizeChildren(const TSharedRef<IPropertyHandle> PropertyHandle, FDetailChildrenBuilder& PropertyBuilder, IPropertyTypeCustomizationUtils& CustomizationUtils)
{
    // 【可选】获取当前打开的蓝图对象。取决于定制操作是否依赖蓝图对象中的某些数据，如无需要可以跳过
    TArray<UObject*> Outers;
    PropertyHandle->GetOuterObjects(Outers);
    for (UObject* const Obj : Outers)
    {
        // Do something...
    }

    // 加入定制内容
    AddCustomDetails(PropertyHandle, PropertyBuilder, CustomizationUtils);
}

void FMyPropCustomization::AddCustomDetails(const TSharedRef<IPropertyHandle> ParentHandle, FDetailChildrenBuilder& ParentBuilder, IPropertyTypeCustomizationUtils& CustomizationUtils)
{
    // ParentHandle 是整个 FMyProp 的绘制器，相当于根节点，我们需要获取到目标属性的绘制器，即叶子节点
    // 请注意，对于 FMyProp 中不需要定制的蓝图属性，我们也需要执行到"获取目标属性的绘制器"这一步，否则这些蓝图属性将会丢失。因此以下代码块可以理解为一个循环语句的主体，执行次数等于 FMyProp 中的蓝图属性数目
    {
        // 目标属性的名称
        const FName ChildName = ...;
        // 获取目标属性的句柄
        const TSharedPtr<IPropertyHandle> ChildHandle = ParentHandle>GetChildHandle(ChildName);
        // 获取目标属性的绘制器
        IDetailPropertyRow& childRow = ParentBuilder.AddProperty(ChildHandle.ToSharedRef());

        // （关键）接下来与蓝图类定制中定制一个蓝图属性 Slate 控件的做法相同
    }
}
```

完整示例可以参考引擎源码 SlateBrushCustomization\.h 和 SlateBrushCustomization\.cpp，它对 `FSlateBrush` 类型进行定制，实现了九宫格属性隐藏等功能。
