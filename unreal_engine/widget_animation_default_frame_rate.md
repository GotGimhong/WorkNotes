# 控件动画的默认帧率


## 实现方式

控件动画（Widget Animation）的默认帧率是 20fps，这是通过硬编码的方式实现的，出处如下：

+ MovieScene\.cpp 中，`UMovieScene` 类的 `Serialize` 函数

    通过该函数得知，在低版本的序列化流程中，除了控件动画之外，角色动画，关卡动画等动画的默认帧率也是通过硬编码的方式设置的。

    ```cpp
    void UMovieScene::Serialize(FArchive& Ar)
    {
        // ...
    #if WITH_EDITORONLY_DATA
        if (Ar.CustomVer(FSequencerObjectVersion::GUID) < FSequencerObjectVersion::FloatToIntConversion)
        {
            // ...
            {
                UObject* Outer = GetOuter();
                if (Outer && Outer->GetClass()->GetFName() == "WidgetAnimation")
                {
                    // 控件动画的默认帧率被设置为 20fps
                    DisplayRate = FFrameRate(20, 1);
                }
                else if (Outer && Outer->GetClass()->GetFName() == "ActorSequence")
                {
                    // 角色动画的默认帧率被设置为 10fps
                    DisplayRate = FFrameRate(10, 1);
                }
                else
                {
                    // 其他动画，例如关卡动画，默认帧率被设置为 30fps
                    DisplayRate = FFrameRate(30, 1);
                }
            }
        }
    #endif
    }
    ```

+ WidgetAnimation\.cpp 中，`UWidgetAnimation` 类的 `GetNullAnimation` 函数

    该函数设置了控件动画空模板（即在控件动画编辑器中，未选中任何控件动画时所显示的内容）的默认帧率。

    ```cpp
    UWidgetAnimation* UWidgetAnimation::GetNullAnimation()
    {
        static UWidgetAnimation* NullAnimation = nullptr;
        if (!NullAnimation)
        {
            // ...
            // 控件动画空模板的默认帧率被设置为 20fps
            NullAnimation->MovieScene->SetDisplayRate(FFrameRate(20, 1));
        }
        return NullAnimation;
    }
    ```

+ AnimationTabSummoner\.cpp 中，`SUMGAnimationList` 类的 `OnNewAnimationClicked` 函数

    该函数设置了新建的控件动画的默认帧率。

    ```cpp
	FReply OnNewAnimationClicked()
	{
        // ...
		// 新建控件动画的默认帧率被设置为 20fps
		NewAnimation->MovieScene->SetDisplayRate(FFrameRate(20, 1));
        // ...
		return FReply::Handled();
	}
    ```

> 直至 UE5.3，默认帧率仍然采用这种硬编码的写法


## 改进方案

经过沟通，Epic 官方人员建议修改引擎源码，为控件动画的默认帧率增加一个配置项。因此核心问题就是 **如何增加这个配置项** 。

可以留意到，三处硬编码分别来自于引擎的 MovieScene，UMG 和 UMGEditor 模块，其中 **MovieScene 模块被后两者所依赖** 。由此可知，在 MovieScene 模块中增加这个配置项，对于引擎源码的改动是最小的。具体做法是在 MovieScene 模块中增加一个 `UDeveloperSettings` 类的派生类，在其中增加配置项，示例如下：

```cpp
UCLASS(Config = Engine, DefaultConfig)
class MOVIESCENE_API UMovieSceneSettings : public UDeveloperSettings
{
    GENERATED_BODY()

public:
    /**
     * 控件动画的默认帧率
     * 可以使用 FIntVector2 类型表示 FFrameRate 类型，其中 X 和 Y 分别对应 Numerator 和 Denominator
     */
    UPROPERTY(Config, EditAnywhere)
    FIntVector2 WidgetAnimationDefaultFrameRate;

    /**
     * 角色动画的默认帧率
     * 按需添加，以替换 UMovieScene 类 Serialize 函数中的硬编码
     */
    UPROPERTY(Config, EditAnywhere)
    FIntVector2 ActorSequenceDefaultFrameRate;

    /**
     * 关卡动画的默认帧率
     * 按需添加，以替换 UMovieScene 类 Serialize 函数中的硬编码
     */
    UPROPERTY(Config, EditAnywhere)
    FIntVector2 LevelSequenceDefaultFrameRate;
};
```

编译后，在 项目设置（Project Settings） 中就可以找到以上三个配置项，从而灵活调整控件动画和其他动画的默认帧率了。
