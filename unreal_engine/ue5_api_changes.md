# UE5 API 变更记录

以下是将引擎版本从 4\.27 升级至 5\.0 和 5\.1 时遇到的 API 变更，并不涵盖所有的 API 变更。


## UObjectBaseUtility 类

`UObjectBaseUtility` 的声明请见 UObjectBaseUtility\.h。

+ `MarkPendingKill` 函数

    从 UE5\.0 开始被 `MarkAsGarbage` 函数所替代。

    ```c++
    UObject* const Object;
    #if ENGINE_MAJOR_VERSION >= 5
        Object->MarkAsGarbage();
    #else
        Object->MarkPendingKill();
    #endif
    ```

+ `ClearPendingKill` 函数

    从 UE5\.0 被 `ClearGarbage` 函数所替代。

    ```c++
    UObject* const Object;
    #if ENGINE_MAJOR_VERSION >= 5
        Object->ClearGarbage();
    #else
        Object->ClearPendingKill();
    #endif
    ```

+ `IsPendingKill` 函数

    从 UE5\.0 被全局函数 `IsValid` 或者 `GetValid` 所替代。这两个函数的定义请见 Object\.h。

    根据引擎的注释，除了以上两个函数外，还可以使用全局函数 `IsValidChecked`，功能类似于 `IsValid`。然而我们并不建议使用该函数，因为该函数内部存在断言，如果待检查的对象为空就会导致断言失败，从而引起崩溃。

    ```c++
    UObject* const Object;
    #if ENGINE_MAJOR_VERSION >= 5
        // 或通过 GetValid(Object) 进行检查，Object 有效时返回 Object，反之返回空指针
        const bool bValid = IsValid(Object);
    #else
        const bool bValid = Object->IsPendingKill();
    #endif
    ```


## UEditorLevelLibrary 类

`UEditorLevelLibrary` 的声明请见 EditorLevelLibrary\.h。

从 UE5\.0 开始，`UEditorLevelLibrary` 中的蓝图函数被移至各个 Subsystem 类中，这里举几个例子： 

+ `GetEditorWorld` 和 `GetGameWorld` 函数

    被移至 `UUnrealEditorSubsystem` 类中，请见 UnrealEditorSubsystem\.h。

    ```c++
    // 以 GetEditorWorld 和 GetGameWorld 为例

    #if ENGINE_MAJOR_VERSION >= 5
        UWorld* EditorWorld = nullptr;
        UWorld* GameWorld = nullptr;
        if (UUnrealEditorSubsystem* const Subsystem = GEditor->GetEditorSubsystem<UUnrealEditorSubsystem>())
        {
            EditorWorld = Subsystem->GetEditorWorld();
            GameWorld = Subsystem->GetGameWorld();
        }
    #else
        UWorld* const EditorWorld = UEditorLevelLibrary::GetEditorWorld();
        UWorld* const GameWorld = UEditorLevelLibrary::GetGameWorld();
    #endif
    ```

+ `LoadLevel` 函数

    被移至 `ULevelEditorSubsystem` 类中，请见 LevelEditorSubsystem\.h。


## UNiagaraEmitter 类

`UNiagaraEmitter` 的声明请见 NiagaraEmitter\.h。

+ `GetRenderers` 函数

    从 UE5\.1 开始，该函数被迁移到 `FVersionedNiagaraEmitterData` 结构体中。后者是 UE5\.1 新增的类型，在 `FNiagaraEmitterInstance` 类中可以通过 `GetCachedEmitterData` 函数来返回。

    `FVersionedNiagaraEmitterData` 的声明请见 NiagaraEmitter\.h，`FNiagaraEmitterInstance` 的声明请见 NiagaraEmitterInstance\.h。

    ```c++
    const TSharedRef<FNiagaraEmitterInstance> Instance;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        if (FVersionedNiagaraEmitterData* const EmitterData = Instance->GetCachedEmitterData())
        // 或者：
        // if (FVersionedNiagaraEmitterData* const EmitterData = Instance->GetCachedEmitter().GetEmitterData())
        {
            const TArray<UNiagaraRendererProperties*>& Renderers = EmitterData->GetRenderers();
        }
    #else
        if (UNiagaraEmitter* const Emitter = Instance->GetCachedEmitter())
        {
            const TArray<UNiagaraRendererProperties*>& Renderers = Emitter->GetRenderers();
        }
    #endif
    ```

+ `SimTarget` 属性

    从 UE5\.1 开始，该属性被迁移到 `FVersionedNiagaraEmitterData` 结构体中。

+ `bLocalSpace` 属性

    从 UE5\.1 开始，该属性被迁移到 `FVersionedNiagaraEmitterData` 结构体中。


## USkinnedMeshComponent 类

`USkinnedMeshComponent` 的声明请见 SkinnedMeshComponent\.h。

+ `SetSkeletalMesh` 函数

    从 UE5\.1 开始被 `SetSkinnedAssetAndUpdate` 函数所替代。这对于派生类 `USkeletalMeshComponent` 也有影响。

    在派生类 `USkeletalMeshComponent` 中，`SetSkeletalMesh` 仍然可用，但是不再作为蓝图函数。

    ```c++
    USkinnedMeshComponent* const SkinnedMeshComponent;
    USkeletalMeshComponent* const SkeletalMeshComponent;
    USkeletalMesh* const SkeletalMesh;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // 参数类型是 USkinnedAsset，但是因为 USkeletalMesh 是 USkinnedAsset 的派生类，所以可以直接传递
        SkinnedMeshComponent->SetSkinnedAssetAndUpdate(SkeletalMesh);

        // 蓝图函数调用，与 SetSkeletalMesh 等价
        SkeletalMeshComponent->SetSkinnedAssetAndUpdate(SkeletalMesh);
        // 非蓝图函数调用，与 SetSkinnedAssetAndUpdate 等价
        SkeletalMeshComponent->SetSkeletalMesh(SkeletalMesh);
    #else
        // 蓝图函数调用
        SkinnedMeshComponent->SetSkeletalMesh(SkeletalMesh);

        // 蓝图函数调用
        SkeletalMeshComponent->SetSkeletalMesh(SkeletalMesh);
    #endif
    ```


## UObject 类

`UObject` 的声明请见 Object\.h。

+ `PreSave` 函数

    从 UE5\.0 开始，参数类型发生变化。

    ```c++
    #if ENGINE_MAJOR_VERSION >= 5
        virtual void PreSave(const class ITargetPlatform* TargetPlatform);
    #else
        virtual void PreSave(FObjectPreSaveContext SaveContext);
    #endif
    ```


## UUserWidget 类

`UUserWidget` 的声明请见 UserWidget\.h。

+ `DuplicateAndInitializeFromWidgetTree` 函数

    从 UE5\.1 开始，参数列表发生变化，相比旧版本多了一步合并子控件的操作。

    ```c++
    UUserWidget* const UserWidget;
    UWidgetTree* const WidgetTree;
    // 需要额外合并的子控件，如果没有留空即可
    const TMap<FName, UWidget*> NamedSlotContentToMerge;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        UserWidget->DuplicateAndInitializeFromWidgetTree(WidgetTree, NamedSlotContentToMerge);
    #else
        UserWidget->DuplicateAndInitializeFromWidgetTree(WidgetTree);
    #endif
    ```


## UDataTable 类

`UDataTable` 的声明请见 DataTable\.h。

+ `GetRowStructName` 函数

    从 UE5\.1 开始被 `GetRowStructPathName` 函数所替代。

    ```c++
    UDataTable* const DataTable;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const FString& PathName = DataTable->GetRowStructPathName().ToString();
    #else
        const FString& PathName = DataTable->GetRowStructName().ToString();
    #endif
    ```


## UKismetTextLibrary 类

`UKismetTextLibrary` 的声明请见 KismetTextLibrary\.h。

+ `Conv_FloatToText` 函数

    从 UE5\.1 开始被 `Conv_DoubleToText` 函数所替代，后者是从 UE5\.0 开始新增的函数。

    ```c++
    #if ENGINE_MAJOR_VERSION >= 5
        // 接收双精度浮点数
        const FText& Text = UKismetTextLibrary::Conv_DoubleToText(100.0, ERoundingMode::HalfToEven);
    #else
        // 接收单精度浮点数
        const FText& Text = UKismetTextLibrary::Conv_FloatToText(100.0f, ERoundingMode::HalfToEven);
    #endif
    ```


## UTexture2DArray 类

`UTexture2DArray` 的声明请见 Texture2DArray\.h。

+ `InvadiateTextureSource` 函数

    从 UE5\.1 开始，该函数的命名被更正为 `InvalidateTextureSource`。

    ```c++
    UTexture2DArray* const Array;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        Array->InvalidateTextureSource();
    #else
        Array->InvadiateTextureSource();
    #endif
    ```


## UMaterial 类

`UMaterial` 的声明请见 Source/Runtime/Engine/Classes/Materials/Material\.h。

+ `EditorComments`，`Expressions`，`ExpressionExecBegin`，`ExpressionExecEnd` 和 `ExpressionCollection` 属性

    从 UE5\.1 开始，这些属性被对应的 Get 函数所替代。例如 `Expressions` 属性改为通过 `GetExpressions` 函数来访问。

    ```c++
    // 以 Expressions 属性为例

    UMaterial* const Material;
    #if WITH_EDITORONLY_DATA
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const TArray<TObjectPtr<UMaterialExpression>>& Expressions = Material->GetExpressions();
    #else
        const TArray<TObjectPtr<UMaterialExpression>>& Expressions = Material->Expressions;
    #endif
    #endif
    ```

+ `ParameterGroupData`，`ExpressionCollection`，`BaseColor`，`Metallic`，`Specular`，`Roughness`，`Anisotropy`，`Normal`，`Tangent`，`EmissiveColor`，`Opacity`，`OpacityMask`，`WorldPositionOffset`，`SubsurfaceColor`，`ClearCoat`，`ClearCoatRoughness`，`AmbientOcclusion`，`Refraction`，`CustomizedUVs`，`MaterialAttributes`，`PixelDepthOffset`，`ShadingModelFromMaterialExpression` 和 `FrontMaterial` 属性

    从 UE5\.1 开始，这些属性被迁移至 `UMaterialEditorOnlyData` 结构体中。后者是 UE5\.1 新增的类型，在 `UMaterial` 中可以通过 `GetEditorOnlyData` 函数来访问。

    ```c++
    // 以 ParameterGroupData 属性为例

    UMaterial* const Material;
    #if WITH_EDITORONLY_DATA
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        if (UMaterialEditorOnlyData* const MaterialData = Material->GetEditorOnlyData())
        {
            const TArray<FParameterGroupData>& ParameterGroupData = MaterialData->ParameterGroupData;
        }
    #else
        {
            const TArray<FParameterGroupData>& ParameterGroupData = Material->ParameterGroupData;
        }
    #endif
    #endif
    ```


## UWidget 类

`UWidget` 的声明请见 Widget\.h。

+ `Visibility` 属性

    从 UE5\.1 开始不再支持直接访问，被 `GetVisibility` 和 `SetVisibility` 函数所替代。因为 `GetVisibility` 和 `SetVisibility` 在 UE4 和 UE5 中都有提供，所以不需要做版本兼容。


## UTextBlock 类

`UTextBlock` 的声明请见 TextBlock\.h。

+ `Font` 属性

    从 UE5\.1 开始不再支持直接访问，被 `GetFont` 和 `SetFont` 函数所替代。

    ```c++
    UTextBlock* const TextBlock;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const FSlateFontInfo& Font = TextBlock->GetFont();
        TextBlock->SetFont(Font);
    #else
        const FSlateFontInfo& Font = TextBlock->Font;
        TextBlock->Font = Font;
    #endif
    ```


## UPackage 类

`UPackage` 的声明请见 Package\.h。

+ `FileName` 属性

    从 UE5\.0 开始被 `GetLoadedPath` 函数所替代。

    ```c++
    UPackage* const Package;
    #if ENGINE_MAJOR_VERSION >= 5
        const FName& FileName = Package->FileName;
    #else
        const FPackagePath& PackagePath = Package->GetLoadedPath();
    #endif
    ```

+ `SavePackage` 函数

    从 UE5\.0 开始增加了含有 `FSavePackageArgs` 类型参数的重载，并要求改用这个重载。`FSavePackageArgs` 的声明请见 SavePackage\.h。

    ```c++
    UPackage* const Package;
    UObject* const ObjectToSave;
    const TCHAR* const FileName;
    const EObjectFlags TopLevelFlags;
    FOutputDevice* const Error;
    const bool bForceByteSwapping;
    const bool bWarnOfLongFilename;
    const uint32 SaveFlags;
    #if ENGINE_MAJOR_VERSION >= 5
        FSavePackageArgs SaveArgs;
        SaveArgs.TopLevelFlags = TopLevelFlags;
        SaveArgs.Error = Error;
        SaveArgs.bForceByteSwapping = bForceByteSwapping;
        SaveArgs.bWarnOfLongFilename = bWarnOfLongFilename;
        SaveArgs.SaveFlags = SaveFlags;
        UPackage::SavePackage(Package, ObjectToSave, Filename, SaveArgs);
    #else
        UPackage::SavePackage(Package, ObjectToSave, TopLevelFlags, Filename, Error, nullptr, bForceByteSwapping, bWarnOfLongFilename, SaveFlags);
    #endif
    ```


## UEditableText 类

`UEditableText` 的声明请见 EditableText\.h。

+ `HintText` 属性

    从 UE5\.1 开始不再支持直接访问，被 `GetHintText` 和 `SetHintText` 函数所替代。

    ```c++
    UEditableText* const EditableText;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const FText& HintText = EditableText->GetHintText();
        EditableText->SetHintText(HintText);
    #else
        const FText& HintText = EditableText->HintText;
        EditableText->HintText =HintText;
    #endif
    ```


## UTexture 类

`UTexture` 的声明请见 Source/Runtime/Engine/Classes/Engine/Texture\.h。

+ `bDitherMipMapAlpha` 属性

    从 UE5\.1 开始被移除，引擎没有指明替代的属性或函数。

    ```c++
    // 只能在 UE5.0 或以下的版本中访问该属性
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION < 1 || ENGINE_MAJOR_VERSION < 5
        UTexture* const Texture;
        const bool bDitherMipMapAlpha = !!Texture->bDitherMipMapAlpha;
    #endif
    ```


## UAbilityTask 类

`UAbilityTask` 的声明请见 AbilityTask\.h。

+ `Ability` 属性

    从 UE5\.1 开始，`Ability` 的类型从 `UGameplayAbility*` 变为 `TObjectPtr<UGameplayAbility>`。

    ```c++
    UAbilityTask* const AbilityTask;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        UGameplayAbility* const Ability = AbilityTask->Ability.Get();
    #else
        UGameplayAbility* const Ability = AbilityTask->Ability;
    #endif
    ```

+ `AbilitySystemComponent`

    从 UE5\.1 开始，`AbilitySystemComponent` 的类型从 `UAbilitySystemComponent*` 变为 `TWeakObjectPtr<UAbilitySystemComponent>`。

    ```c++
    UAbilityTask* const AbilityTask;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        UAbilitySystemComponent* const ASC = AbilityTask->AbilitySystemComponent.Get();
    #else
        UAbilitySystemComponent* const ASC = AbilityTask->AbilitySystemComponent;
    #endif
    ```


## UMultiLineEditableTextBox 类

`UMultiLineEditableTextBox` 的声明请见 MultiLineEditableTextBox\.h。

+ `TextStyle` 属性

    从 UE5\.1 开始被废弃，其功能被整合在 `WidgetStyle` 属性中。

    ```c++
    UMultiLineEditableTextBox* const TextBox;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const FTextBlockStyle& TextStyle = TextBox->WidgetStyle.TextStyle;
        TextBox->WidgetStyle.TextStyle = TextStyle;
    #else
        const FTextBlockStyle& TextStyle = TextBox->TextStyle;
        TextBox->TextStyle = TextStyle;
    #endif
    ```


## SMultiLineEditableTextBox 类

`SMultiLineEditableTextBox` 的声明请见 SMultiLineEditableTextBox\.h。

+ `TextStyle` 属性

    从 UE5\.2 开始被废弃。其功能被整合在 `Style` 属性中。

    ```c++
    const TSharedRef<SMultiLineEditableTextBox> TextBox;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const FTextBlockStyle& TextStyle = TextBox->Style.TextStyle;
        TextBox->Style.TextStyle = TextStyle;
    #else
        const FTextBlockStyle& TextStyle = TextBox->TextStyle;
        TextBox->TextStyle = TextStyle;
    #endif
    ```


## SOverlay 类

`SOverlay` 的声明请见 SOverlay\.h。

+ `ZOrder` 属性

    从 UE5\.0 开始不再支持直接访问，被 `SetZOrder` 和 `GetZOrder` 函数所替代。

    ```c++
    const TSharedRef<SOverlay> Overlay;
    #if ENGINE_MAJOR_VERSION >= 5
        // Get
        const int32 ZOrder = Overlay->ZOrder;
        // Set
        Overlay->ZOrder = ZOrder;
    #else
        // Get
        const int32 ZOrder = Overlay->GetZOrder();
        // Set
        Overlay->SetZOrder(ZOrder);
    #endif
    ```


## IAssetRegistry 类

`IAssetRegistry` 的声明请见 IAssetRegistry\.h。

+ `GetAssetByObjectPath` 函数

    从 UE5\.1 开始，参数类型发生变化。

    ```c++
    const FString ObjectPath;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const FAssetData& AssetData = IAssetRegistry::Get()->GetAssetByObjectPath(FSoftObjectPath(ObjectPath));
    #else
        const FAssetData& AssetData = IAssetRegistry::Get()->GetAssetByObjectPath(FName(ObjectPath));
    #endif
    ```


## IUnloadedBlueprintData 类

`IUnloadedBlueprintData` 的声明请见 ClassViewerFilter\.h。

+ `GetClassPath` 函数

    从 UE5\.1 开始被 `GetClassPathName` 函数所替代。

    ```c++
    const TSharedRef<IUnloadedBlueprintData> BlueprintData;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // 从 UE5.1 开始，引擎要求避免使用 FName 作为路径变量的类型
        const FString& ClassPath = BlueprintData->GetClassPathName().ToString();
    #else
        const FString& ClassPath = BlueprintData->GetClassPath().ToString();
    #endif
    ```


## IStructViewerFilter 类

`IStructViewerFilter` 的声明请见 StructViewerFilter\.h。

+ `IsUnloadedStructAllowed` 函数

    从 UE5\.1 开始，参数列表发生变化。`InStructPath` 参数的类型从 `FName` 变为 `const FSoftObjectPath&`。

    ```c++
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        virtual bool IsUnloadedStructAllowed(const FStructViewerInitializationOptions& InInitOptions, const FSoftObjectPath& InStructPath, TSharedRef<class FStructViewerFilterFuncs> InFilterFuncs);
    #else
        virtual bool IsUnloadedStructAllowed(const FStructViewerInitializationOptions& InInitOptions, FName InStructPath, TSharedRef<class FStructViewerFilterFuncs> InFilterFuncs);
    #endif
    ```


## IEditableTextProperty

`IEditableTextProperty` 的声明请见 STextPropertyEditableTextBox\.h。

+ `RequestRefresh` 函数

    从 UE5\.1 开始被移除。此前这个函数只在 `IEditableTextProperty` 的 `Tick` 函数中被调用，而在 UE5\.1 中 `Tick` 函数也被移除。

    ```c++
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION < 1 || ENGINE_MAJOR_VERSION < 5
        virtual void RequestRefresh() override;
    #endif
    ```


## 共享指针类

各种共享指针类的声明请见 SharedPointer\.h。

从 UE5\.1 开始，`TSharedRef`，`TSharedPtr`，`TWeakPtr` 和 `TSharedFromThis` 类相关的函数大部分带有 `[[nodiscard]]` 属性，这是一种 C\+\+17 标准下的语法，调用带有这种属性的函数时，其返回值不应该被丢弃，否则会出现编译警告或者错误。

```c++
// 以 TSharedRef 为例

TSharedRef<SWidget> WidgetRef;
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
    // 丢弃返回值的写法，会出现编译警告或者错误
    WidgetRef.Get();
    // 规范的写法
    SWidget& Widget = WidgetRef.Get();
#else
    // 丢弃返回值的写法，可以正常通过编译
    WidgetRef.Get();
    // 规范的写法
    SWidget& Widget = WidgetRef.Get();
#endif
```


## 容器类

从 UE5\.0 开始，`TArray`，`TList`，`TSet` 和 `TMap` 这四种常用的泛型容器类型增加了判断容器是否为空的函数 `IsEmpty`。

```c++
const TArray<uint8> Array;
const TList<uint8> List;
const TSet<uint8> Set;
const TMap<uint8, uint8> Map;
#if ENGINE_MAJOR_VERSION >= 5
    if (Array.IsEmpty())
    {
        // 数组为空
    }
    if (List.IsEmpty())
    {
        // 链表为空
    }
    if (Set.IsEmpty())
    {
        // 集合为空
    }
    if (Map.IsEmpty())
    {
        // 字典为空
    }
#else
    if (Array.Num() <= 0)
    {
        // 数组为空
    }
    if (List.Num() <= 0)
    {
        // 链表为空
    }
    if (Set.Num() <= 0)
    {
        // 集合为空
    }
    if (Map.Num() <= 0)
    {
        // 字典为空
    }
#endif
```


## FTransform2D 类

`FTransform2D` 类的声明请见 TransformCalculus2D\.h。

从 UE5\.1 开始，`FTransform2D` 重定向至 `FTransform2f` 类，而不再是单独实现的类。


## FSimpleSlot 类

`FSimpleSlot` 的声明请见 Children\.h。

从 UE5\.0 开始被 `FSingleWidgetChildrenWithBasicLayoutSlot` 类所替代。注意引擎的注释是错的，并不存在 `FSingleWidgetChildrenWithSimpleSlot` 类。

```c++
#if ENGINE_MAJOR_VERSION >= 5
    FSingleWidgetChildrenWithBasicLayoutSlot Slot;
#else
    FSimpleSlot Slot;
#endif
```


## FEditorStyle 类

`FEditorStyle` 的声明请见 EditorStyleSet\.h。

从 UE5\.0 开始，`FEditorStyle` 类中除 `ResetToDefault` 外的所有公开函数，全部可以改为通过 `FAppStyle` 类来调用，从 UE5\.1 开始要求必须通过 `FAppStyle` 类来调用。

```c++
// 获取样式数据的单例
#if ENGINE_MAJOR_VERSION >= 5
    const ISlateStyle& Style = FAppStyle::Get();
#else
    const ISlateStyle& Style = FEditorStyle::Get();
#endif
```


## FSlateApplication 类

`FSlateApplication` 的声明请见 SlateApplication\.h。

+ `OnTouchStarted` 函数

    从 UE5\.1 开始参数列表发生变化，`ControllerId` 参数被移除，取而代之的是一个 `FPlatformUserId` 类型的参数 `PlatformUserId` 和一个 `FInputDeviceId` 类型的参数 `DeviceId`。`FPlatformUserId` 和 `FInputDeviceId` 结构体的声明请见 CoreMiscDefines\.h。

    ```c++
    FSlateApplication& Application = FSlateApplication::Get();
    const TSharedPtr<FGenericWindow> Window;
    const FVector2D TouchPoint;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        /**
        * 直至 UE5.2，第5个参数 PlatformUserId 在 OnTouchStarted 函数中并没有引用，无法得知它的作用，因此可以传递一个任意的 FPlatformUserId
        * 第6个参数 DeviceId 替代了 UE5.0 及之前版本的 ControllerId 参数，需要通过原本的 ControllerId 参数来构建一个 FInputDeviceId 进行传递
        */
        if (Application.OnTouchStarted(Window, TouchPoint, 1.0f, 0, FPlatformUserId::CreateFromInternalId(0), FInputDeviceId::CreateFromInternalId(0)))
        {
            // 触摸事件开始
        }
    #else
        if (Application.OnTouchStarted(Window, TouchPoint, 1.0f, 0, 0))
        {
            // 触摸事件开始
        }
    #endif
    ```

+ `OnTouchEnded` 函数

    变化同 `OnTouchStarted` 函数。

+ `OnControllerAnalog` 函数

    变化同 `OnTouchStarted` 函数


## FNiagaraEmitterInstance 类

`FNiagaraEmitterInstance` 的声明请见 NiagaraEmitterInstance\.h。

+ `GetCachedEmitter` 函数

    从 UE5\.1 开始，返回值的类型从 `UNiagaraEmitter*` 变为 `FVersionedNiagaraEmitter`。后者是 UE5\.1 新增的类型，声明请见 NiagaraTypes\.h。

    ```c++
    const TSharedRef<FNiagaraEmitterInstance> Instance;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        UNiagaraEmitter* const Emitter = Instance->GetCachedEmitter().Emitter;
    #else
        UNiagaraEmitter* const Emitter = Instance->GetCachedEmitter();
    #endif
    ```


## FSlateFontCache 类

`FSlateFontCache` 的声明请见 FontCache\.h。

+ `GetOverflowEllipsisText` 函数

    该函数从 UE5\.0 开始新增，从 UE5\.1 开始被 `ShapeOverflowEllipsisText` 函数所替代。按照引擎的注释，替代者是 `FShapedTextCache` 类的 `FindOrAddOverflowEllipsisText` 函数，然而这个函数与 `GetOverflowEllipsisText` 的差异过大，因此建议使用 `ShapeOverflowEllipsisText` 函数。

    ```c++
    #if ENGINE_MAJOR_VERSION >= 5
        FSlateFontCache FontCache;
        const FSlateFontInfo FontInfo;
        const float FontScale;
    #if ENGINE_MINOR_VERSION >= 1
        const FShapedGlyphSequencePtr& TextPtr = FontCache.ShapeOverflowEllipsisText(FontInfo, FontScale);
    #else
        const FShapedGlyphSequencePtr& TextPtr = FontCache.GetOverflowEllipsisText(FontInfo, FontScale);
    #endif
    #endif
    ```


## FKismetCompilerContext 类

`FKismetCompilerContext` 的声明请见 KismetCompiler\.h。

+ `OnPostCDOCompiled` 函数

    从 UE5\.1 开始，参数列表发生变化。

    ```c++
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        virtual void OnPostCDOCompiled(const UObject::FPostCDOCompiledContext& Context);
    #else
        virtual void OnPostCDOCompiled();
    #endif
    ```


## 蓝图结构体

从 UE5\.0 开始，引擎要求必须为蓝图结构体中的蓝图属性赋予初始值。如果一个蓝图属性没有被赋予初始值，并且它的类型不是对象类型，或者是不含默认构造函数的对象类型，那么引擎在启动后就会在控制台中输出错误。输出的错误是以蓝图属性为单位的，每当检查到一条没有被赋予初始值的蓝图属性，就会输出一条错误。

示例：

```c++
USTRUCT()
struct MYPROJECT_API FMyBPStruct
{
    GENERATED_USTRUCT_BODY()

    // 有错误，引擎在控制台中输出 "LogClass: Error: FloatProperty FMyBPStruct::FloatValue is not initialized properly. Module:MyProject File:Public/MyBPStruct.h"
    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    float FloatValue;

    // 没有错误，IntValue 的初始值是 0
    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    int32 IntValue = 0;

    // 没有错误，FName 类型含有默认构造函数，初始值是 NAME_None
    UPROPERTY(BlueprintReadWrite, EditAnywhere)
    FName NameValue;
};
```

赋予初始值的方式有以下两种：

+ 声明时指定初始值

    ```c++
    USTRUCT()
    struct MYPROJECT_API FMyBPStruct
    {
        GENERATED_USTRUCT_BODY()

        // 声明 FloatValue 时指定初始值是 0
        UPROPERTY(BlueprintReadWrite, EditAnywhere)
        float FloatValue = 0.0f;
    };
    ```

+ 定义构造函数

    ```c++
    USTRUCT()
    struct MYPROJECT_API FMyBPStruct
    {
        GENERATED_USTRUCT_BODY()

        UPROPERTY(BlueprintReadWrite, EditAnywhere)
        float FloatValue;

        // 通过构造函数指定 FloatValue 的初始值是 0
        FMyBPStruct()
            : FloatValue(0.0f)
        {

        }
    };
    ```

对于所属类型含有默认构造函数的蓝图属性，例如 `FName` 和 `FString`，尽管原则上不需要赋予它们初始值，但还是建议赋予它们初始值。一是和其他蓝图属性保持写法上的统一，二是提升代码的可读性，让其他开发人员更加明确各个蓝图属性被赋予的初始值。


## FSoftObjectPath 结构体

`FSoftObjectPath` 的声明请见 SoftObjectPath\.h。

+ 构造函数

    从 UE5\.1 开始废弃了以 `FName` 类型作为路径参数的构造函数重载。

    ```c++
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION < 1 || ENGINE_MAJOR_VERSION < 5
        const FName AssetPath;
        // 重载版本1
        const FSoftObjectPath Path1(AsstPath);

        const FName AssetPathName;
        const FString SubPathString;
        // 重载版本2
        const FSoftObjectPath Path2(AssetPathName, SubPathString);
    #endif
    ```

+ `GetAssetPathName` 函数

    从 UE5\.1 开始被 `GetAssetPath` 函数所替代。

    ```c++
    const FSoftObjectPath Path;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        const FString& PathName = Path.GetAssetPath().ToString();
    #else
        const FString& PathName = Path.GetAssetPathName().ToString();
    #endif
    ```

+ `SetAssetPathName` 函数

    从 UE5\.1 开始被 `SetAssetPath` 函数所替代。

    注意直至 UE5\.2，`FSoftObjectPath` 实际上都尚未提供 `SetAssetPath` 函数，意味着仍然需要使用 `SetAssetPathName` 函数。


## FPreviewPlatformInfo 结构体

`FPreviewPlatformInfo` 的声明请见 EditorEngine\.h。

+ 构造函数

    从 UE5\.1 开始，参数列表发生变化，增加了一个 `EShaderPlatform` 类型的参数 `InShaderPlatform` 和一个 `FName` 类型的参数 `InShaderPlatformName`。

    ```c++
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // 参数 InDeviceProfileName，InbPreviewFeatureLevelActive 和 InShaderPlatformName 分别使用默认值 NAME_None，false 和 NAME_None
        const FPreviewPlatformInfo Info(ERHIFeatureLevel::ES3_1, EShaderPlatform::SP_VULKAN_ES3_1_ANDROID, TEXT("Android"), TEXT("GLSL_ES3_1_ANDROID"));
    #else
        // 参数 InDeviceProfileName 和 InbPreviewFeatureLevelActive 分别使用默认值 NAME_None 和 false
        const FPreviewPlatformInfo Info(ERHIFeatureLevel::ES3_1, TEXT("Android"), TEXT("GLSL_ES3_1_ANDROID"));
    #endif
    ```


## FAssetData 结构体

`FAssetData` 的声明请见 Source/Runtime/CoreUObject/Public/AssetRegistry/AssetData\.h。

+ `AssetClass` 属性

    从 UE5\.1 开始被 `AssetClassPath` 属性所替代，类型是 `FTopLevelAssetPath`。`FTopLevelAssetPath` 的声明请见 TopLevelAssetPath\.h。

    ```c++
    const FAssetData AssetData;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // 从 UE5.1 开始，引擎要求避免使用 FName 作为路径变量的类型
        const FName& AssetClassName = AssetData.AssetClassPath.GetAssetName();
    #else
        const FString& AssetClassName = AssetData.AssetClass;
    #endif
    ```

+ `ObjectPath` 属性

    从 UE5\.1 开始被 `GetSoftObjectPath` 函数或者是 `GetObjectPathString` 函数所替代。

    ```c++
    const FAssetData AssetData;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // 或通过 AssetData.GetSoftObjectPath() 得到一个 FSoftObjectPath 类型的变量
        const FString& ObjectPath = AssetData.GetObjectPathString();
    #else
        const FString& ObjectPath = AssetData.ObjectPath;
    #endif
    ```


## FCoreUObjectDelegates 结构体

`FCoreUObjectDelegates` 的声明请见 UObjectGlobals\.h。

+ `OnObjectSaved` 属性

    从 UE5\.0 开始被 `OnObjectPreSaved` 属性所替代。

    ```c++
    // 注意回调的参数列表有所变化
    #if ENGINE_MAJOR_VERSION >= 5
        FDelegateHandle Handle = FCoreUObjectDelegates::OnObjectPreSave.AddLambda([](UObject* const Object, const FObjectPreSaveContext Context) -> void
        {
            // ...
        });
    #else
        FDelegateHandle Handle = FCoreUObjectDelegates::OnObjectSaved.AddLambda([](UObject* const Object) -> void
        {
            // ...
        });
    #endif
    ```


## FKeyChain 结构体

`FKeyChain` 的声明请见 KeyChainUtilities\.h。

+ `MasterEncryptionKey` 属性

    从 UE5\.1 开始不再支持直接访问，需要调用 `GetPrincipalEncryptionKey` 和 `FKeyChainSetPrincipalEncryptionKey` 函数。

    ```c++
    FKeyChain KeyChain;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // Get
        const FNamedAESKey* const Key = KeyChain.GetPrincipalEncryptionKey();
        // Set
        KeyChain.SetPrincipalEncryptionKey(Key);
    #else
        // Get
        const FNamedAESKey* const Key = KeyChain.MasterEncryptionKey;
        // Set
        KeyChain.MasterEncryptionKey = Key;
    #endif
    ```

+ `EncryptionKeys` 属性

    从 UE5\.1 开始不再支持直接访问，需要调用 `GetEncryptionKeys` 和 `SetEncryptionKeys` 函数。

    ```c++
    FKeyChain KeyChain;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // Get
        const TMap<FGuid, FNamedAESKey>& Keys = KeyChain.GetEncryptionKeys();
        // Set
        KeyChain.SetEncryptionKeys(Keys);
    #else
        // Get
        const TMap<FGuid, FNamedAESKey>& Keys = KeyChain.EncryptionKeys;
        // Set
        KeyChain.EncryptionKeys = Keys;
    #endif
    ```

+ `SigningKey` 属性

    从 UE5\.1 开始不再支持直接访问，需要调用 `GetSigningKey` 和 `SetSigningKey` 函数。

    ```c++
    FKeyChain KeyChain;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        // Get
        const FRSAKeyHandle& Key = KeyChain.GetSigningKey();
        // Set
        KeyChain.SetSigningKey(Key);
    #else
        // Get
        const FRSAKeyHandle& Key = KeyChain.SigningKey;
        // Set
        KeyChain.SigningKey = Key;
    #endif
    ```


## FStaticParameterSet 结构体

`FStaticParameterSet` 的声明请见 StaticParameterSet\.h。

+ `StaticSwitchParameters` 属性

    从 UE5\.1 开始被移至 `FStaticParameterSetEditorOnlyData` 结构体中，并且要求在 `WITH_EDITORONLY_DATA` 宏的分支下使用。`FStaticParameterSetEditorOnlyData` 是 UE5\.1 新增的类型，声明请见 StaticParameterSet\.h。

    ```c++
    FStaticParameterSet Set;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
    #if WITH_EDITORONLY_DATA
        TArray<FStaticSwitchParameter>& StaticSwitchParameters = Set.EditorOnly.StaticSwitchParameters;
    #endif
    #else
        TArray<FStaticSwitchParameter>& StaticSwitchParameters = Set.StaticSwitchParameters;
    #endif
    ```

+ `StaticComponentMaskParameters` 属性

    变化同 `StaticSwitchParameters` 属性。

    ```c++
    FStaticParameterSet Set;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
    #if WITH_EDITORONLY_DATA
        TArray<FStaticComponentMaskParameter>& StaticComponentMaskParameters = Set.EditorOnly.StaticComponentMaskParameters;
    #endif
    #else
        TArray<FStaticComponentMaskParameter>& StaticComponentMaskParameters = Set.StaticComponentMaskParameters;
    #endif
    ```

+ `TerrainLayerWeightParameters` 属性

    变化同 `StaticSwitchParameters` 属性。

    ```c++
    FStaticParameterSet Set;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
    #if WITH_EDITORONLY_DATA
        TArray<FStaticTerrainLayerWeightParameter>& TerrainLayerWeightParameters = Set.EditorOnly.TerrainLayerWeightParameters;
    #endif
    #else
        TArray<FStaticTerrainLayerWeightParameter>& TerrainLayerWeightParameters = Set.TerrainLayerWeightParameters;
    #endif
    ```

+ `MaterialLayers` 属性

    从 UE5\.1 开始，类型从 `FMaterialLayersFunctions` 变为 `FMaterialLayersFunctionsRuntimeData`。后者是 UE5\.1 新增的类型，声明请见 MaterialLayersFunctions\.h。

    ```c++
    FStaticParameterSet Set;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        FMaterialLayersFunctionsRuntimeData& MaterialLayers = Set.MaterialLayers;
    #else
        FMaterialLayersFunctions& MaterialLayers = Set.MaterialLayers;
    #endif
    ```


## FARFilter 结构体

`FARFilter` 的声明请见 ARFilter\.h。

+ `ClassNames` 属性

    从 UE5\.1 开始被 `ClassPaths` 属性所替代，类型变为 `TArray<FTopLevelAssetPath>`。

    ```c++
    FARFilter Filter;
    #if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
        TArray<FTopLevelAssetPath>& ClassPaths = Filter.ClassPaths;
    #else
        TArray<FName>& ClassNames = Filter.ClassNames;
    #endif
    ```


## IsDefaultSubobject 函数

`IsDefaultSubobject` 的定义请见 UObjectBaseUtility\.cpp。

此前一个对象只要其 Outer 有效，并且 Outer 不是 CDO，该函数就会返回 true。而从 UE5\.1 开始，该函数的实现有所变化——除了满足前面提到的条件外，目标对象还必须不为 CDO，该函数才会返回 true。换言之，这个函数不能再用于判断一个对象是否为 CDO。


## SLATE_SUPPORTS_SLOT 宏

`SLATE_SUPPORTS_SLOT` 的定义请见 DeclarativeSyntaxSupport\.h。

从 UE5\.0 开始被 `SLATE_SLOT_ARGUMENT` 宏所替代。

```c++
#if ENGINE_MAJOR_VERSION >= 5
    SLATE_SUPPORTS_SLOT(FSimpleSlot)
#else
    /**
    * 注意从 UE5.0 开始改用 FSingleWidgetChildrenWithBasicLayoutSlot
    * ChildSlots 是成员变量的名称，可以自行指定
    */
    SLATE_SLOT_ARGUMENT(FSingleWidgetChildrenWithBasicLayoutSlot, ChildSlots)
#endif
```


## ANY_PACKAGE 宏

`ANY_PACKAGE` 的定义请见 ObjectMacros\.h。

从 UE5\.1 开始被废弃。这个宏主要用于 `FindObject` 函数 `Outer` 参数的传递。从 UE5\.1 开始，引擎要求在调用 `FindObject` 函数时应当提供有效的 `Outer` 参数或者待查找对象的完整路径。`FindObject` 函数的声明请见 UObjectGlobals\.h。

```c++
const TCHAR* const ObjectName;
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
    const FName ObjectPathName;
    const FTopLevelAssetPath ObjectPath(ObjectPathName);
    UObject* const Object = FindObject<UObject>(ObjectPath);
    // 如果能够提供有效的 Outer，就可以使用另一个重载: FindObject<UObject>(Outer, ObjectName);
#else
    UObject* const Object = FindObject<UObject>(ANY_PACKAGE, ObjectName);
#endif
```

> `ANY_PACKAGE` 本质上是 `reinterpret<UPackage*>(-1)`，并不等价于 `nullptr`，因此 `FindObject<UObject>(ANY_PACKAGE, ObjectName)` 绝对不能改写为 `FindObject<UObject>(nullptr, ObjectName)`；具体请见 `FindObject` 的实现


## _DebugBreakAndPromptForRemote 宏

`_DebugBreakAndPromptForRemote` 的定义请见 AssertionMacros\.h。

从 UE5\.1 开始被 `UE_DEBUG_BREAK_AND_PROMPT_FOR_REMOTE` 宏所替代。

```c++
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
    UE_DEBUG_BREAK_AND_PROMPT_FOR_REMOTE();
#else
    _DebugBreakAndPromptForRemote();
#endif
```


## UProperty 相关的宏定义

从 UE4\.25 开始，各种蓝图属性类型宏定义的前缀从 'U' 改为 'F'，例如 `UProperty` 改为 `FProperty`。这些宏定义在 DefineUPropertyMacros\.h，作用是将 UnrealTypePrivate\.h 中定义的类型重定向至 UnrealType\.h 中定义的类型。DefineUPropertyMacros\.h 从 UE5\.1 开始被删除，意味着从 UE5\.1 开始，直接访问前缀为 'U' 的蓝图属性类型宏定义会出现编译错误。

```c++
// 以 UProperty 和 FProperty 为例

#if ENGINE_MAJOR_VERSION >= 4 && ENGINE_MINOR_VERSION >= 25
    const FProperty* Property;
#else
    const UProperty* Property;
#endif
```


## AssetRegistryModule.h 文件

从 UE5\.1 开始要求改用 `#include "AssetRegistry/AssetRegistryModule.h"` 而非 `#include "AssetRegistryModule.h"` 的写法来包含这个头文件。请见 Source/Runtime/AssetRegistry/Public/AssetRegistryModule\.h 和 Source/Runtime/AssetRegistry/Public/AssetRegistry/AssetRegistryModule\.h。

实际上，从 UE4 开始，这个头文件就有两份，其中 Source/Runtime/AssetRegistry/Public/AssetRegistryModule\.h 只是为了减小文件包含路径的长度，这个头文件即将被移除，因此需要改为包含 Source/Runtime/AssetRegistry/Public/AssetRegistry/AssetRegistryModule\.h。


## EditorStyleSettings.h 文件

从 UE5\.1 开始，EditorStyleSettings\.h 文件从 EditorStyle 模块的 Public/Classes 目录移至 UnrealEd 模块的 Classes/Settings 目录。

```c++
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
    // 需要依赖 UnrealEd 模块
    #include "Classes/Settings/EditorStyleSettings.h"
#else
    // 需要依赖 EditorStyle 模块
    #include "Classes/EditorStyleSettings.h"
#endif
```

## AssetEditorManager.h

从 UE5\.0 开始，该文件被移除，`FAssetEditorManager` 类也随之被废弃。

```c++
#if ENGINE_MAJOR_VERSION < 5
#include "Toolkits/AssetEditorManager.h"
#endif
```

