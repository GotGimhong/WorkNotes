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


## 改进方案

经过沟通，Epic 官方人员建议修改引擎源码，为控件动画的默认帧率增加一个配置项。因此核心问题就是 **如何增加这个配置项** 。

可以留意到，三处硬编码分别来自于引擎的 MovieScene，UMG 和 UMGEditor 模块
