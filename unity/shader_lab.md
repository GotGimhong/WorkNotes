# ShaderLab


## 代码格式

```java
Shader "MyShader" {
    Properties {
        _MyTexture ("My Texture", 2D) = "white" { }
        // place other properties here, such as colors or vectors.
    }
    SubShader {
        // place the shader code here for your:
        // - surface shader,
        // - vertex and program shader, or
        // - fixed function shader
    }
    SubShader {
        // a simpler version of the subshader above goes here.
        // this version is for supporting older graphics cards.
    }
    Fallback "Diffuse"
}
```


## 常见关键字

+ Shader

    在每个着色器文件的首行，用于指定着色器的名称，可以通过添加斜杠字符（/）来控制着色器在材质面板中出现的位置。以下代码示例，表示着色器的名称为 MyShader，位于材质面板着色器下拉菜单的 Custom 类别中。

    ```java
    Shader "Custom/MyShader"
    ```

+ Properties

    用于指定着色器文件包含的属性列表。在属性列表中声明的属性会在材质面板上显示，以便开发者调整。属性的声明格式如下：

    `{属性名称} (“{属性显示名称}”, 属性类型) = {默认值}`

    属性名称需要以下划线（_）开头。属性类型有 `Int`，`Float`，`Range`，`Color`，`Vector`，`2D`，`Cube` 和 `3D`。以下代码示例，表示声明一个 `2D` 类型的变量 _MyTexture，在材质面板上的显示名称为 Texture，默认值为全白（RGBA 四个通道都为1）。

    ```java
    _MyTexture ("Texture", 2D) = "white" {}
    ```

+ SubShader

    用于定义一个语义块，描述具体的着色器行为。一个着色器文件中至少会有一个 SubShader。当一个着色器文件运行时，引擎会扫描所有的 SubShader，并选择第一个能够在当前设备上运行的 SubShader，如果都不支持，则会选择 Fallback 指定的着色器。通过在一个着色器文件中定义多个 SubShader 的做法，可以达到适配不同设备的目的，例如在低端设备上选用复杂度较低的 SubShader 以保证游戏的正常运行，在高端设备上选用复杂度较高的 SubShader 以保证更好的渲染效果。

+ Fallback

    用于指定作为保底的着色器。当一个着色器文件中定义的 SubShader 都不能在当前设备上运行时，引擎就会选用保底的着色器。

    以下代码示例，表示使用引擎内置的漫反射着色器作为保底。

    ```java
    Fallback "diffuse"
    ```

    以下代码示例，则表示不提供保底方案，当 SubShader 无法正常运行时，渲染效果就会出现异常，例如出现（粉）红色。

    ```java
    Fallback Off
    ```

    正确设置并选择合适的保底着色器是十分有必要的，首先应尽可能选用引擎内置的，或其他复杂度低的着色器，确保在低端设备上也能生效；另外在引擎的内置着色器中，通常还会包含通用的阴影投射 Pass，设置好 Fallback 也就意味着我们不需要自行实现一个阴影投射 Pass。

+ Pass

    用于定义一个语义块，描述 SubShader 中的一个完整渲染流程。一个 SubShader 中可以定义多个 Pass，但是 Pass 数目过多会导致渲染性能下降。

    在 Pass 语义块中，有如下专用的关键字：

    + Name

        用于指定 Pass 的名称。以下代码示例，表示将 Pass 的名称设置为 MyPass。

        ```java
        Name "MyPass"
        ```

    + UsePass

        用于复用在其他着色器中定义的 Pass。注意 Pass 的名称需要使用大写，以下代码示例，表示复用着色器 MyShader 中定义的 MyPass。

        ```java
        UsePass "MyShader/MYPASS"
        ```

    + GrabPass

        用于捕获当前屏幕的图像，并绘制在一个 `2D` 类型的纹理中，以便后续的 Pass访问。以下代码示例，表示抓取当前屏幕的图像，然后绘制到属性 _GrabTexture 当中，如此后续的 Pass 就可以通过属性 _GrabTexture 来获取目标物体渲染前的屏幕图像，从而实现一些复杂的渲染效果，例如折射和玻璃效果。

        ```java
        GrabPass "_GrabTexture"
        ```

在 SubShader 和 Pass 中，可以根据需要定义渲染状态（RenderSetup）和标签（Tags）。定义在 SubShader 中的渲染状态和标签会作用于其下所有的 Pass，定义在 Pass 中的渲染状态和标签则只作用于当前 Pass。

渲染状态通用于 SubShader 和 Pass，有如下：

+ Cull

    用于设置剔除模式，代码示例如下。

    ```java
    Cull Back // 表示剔除片元正面的渲染
    Cull Front // 表示剔除片元背面的渲染
    Cull Off // 表示关闭剔除功能
    ```

    例如在 SubShader 中设置 `Cull Back`，其中某个 Pass 需要剔除正面，可以单独设置 `Cull Front`，又或者其中某个 Pass 不需要剔除，可以单独设置 `Cull Off`。

+ ZTest

    用于设置深度测试所使用的方法，通过比较当前片元与对应深度缓冲区中的深度值进行实现。可用的参数有 `Less`，`Greater`，`LEqual`，`GEqual`，`Equal`，`NotEqual` 和 `Always`。以下代码示例，表示当前片元的深度值小于等于深度缓冲区中的深度值时，深度测试通过且被渲染至屏幕中，实现近处物体遮挡远处物体的效果，这也是默认的深度测试方法。

    ```java
    ZTest LEqual
    ```

+ ZWrite

    用于设置深度写入的开关，代码示例如下。

    ```java
    ZWrite On // 表示开启深度写入
    ZWrite Off // 表示关闭深度写入
    ```

    注意在渲染半透明物体时，需要关闭深度写入，因为开启深度写入后，在深度测试中会将远处物体剔除（被完全遮挡），导致无法实现透过近处的半透明物体看到远处物体的效果。

+ Blend

    用于开关和设置颜色混合模式，代码示例如下。

    ```java
    Blend Off // 关闭颜色混合
    Blend SrcFactor DstFactor [, SrcFactorA DstFactorA] // 开启并设置颜色混合
    ```

    颜色混合的做法是让当前片元产生的（源）颜色，与对应颜色缓冲区中的（目标）颜色，两者各自乘上一个因子后相加，然后将求和结果更新至颜色缓冲区。其中 SrcFactor 为源颜色 RGB 通道的因子，DstFactor 为目标颜色 RGB 通道的因子，SrcFactorA 为源颜色 Alpha 通道的因子，DstFactorA 为目标颜色 Alpha 通道的因子，若不提供 SrcFactorA 和 DstFactorA，那么 RGB 和 Alpha 通道统一使用 SrcFactor 和 DstFactor。

    可用的颜色混合因子有 `One`，`Zero`，`SrcColor`，`SrcAlpha`，`DstColor`，`DstAlpha`，`OneMinusSrcColor`，`OneMinusSrcAlpha`，`OneMinusDstColor` 和 `OneMinusDstAlpha`。以下代码示例，表示根据源颜色的透明度进行插值，即常规的透明度混合方式。

    ```java
    Blend SrcAlpha OneMinusSrcAlpha
    ```

+ BlendOp

    配合 Blend 的使用，用于设置特殊的颜色混合模式。参数有`Add`，`Sub`，`RevSub`，`Min` 和 `Max`。以下代码示例，表示用于源颜色减去目标颜色得到混合结果，与常规的求和方式相反。

    ```java
    BlendOp Sub
    Blend SrcFactor DstFactor
    ```

+ Tags

    相较于渲染状态，SubShader 和 Pass 支持的标签类型则有所不同，不过它们都会通过关键字 Tags 定义一个语义块，包含所需的标签键值对。

    SubShader 支持的标签类型如下：

    + Queue

        用于控制渲染顺序，指定目标物体所属的渲染队列。引擎预定义的渲染队列有 `Background`，`Geometry`，`AlphaTest`，`Transparent` 与 `Overlay`，它们的索引号分别为1000，2000，2450，3000和4000。索引号越小，目标物体越早被渲染。

        以下代码示例，表示目标物体会作为背景内容尽早被渲染。

        ```java
        "Queue"="Background"
        ```

        以下代码示例，表示使用索引号比 `Geometry` 大1的自定义渲染队列。

        ```java
        "Queue"="Geometry+1"
        ```

    + RenderType

        用于指定物体的渲染类别。引擎默认提供的类别有 `Opaque`，`Transparent`，`TransparentCutout`，`Background`，`Overlay`，`TreeOpaque`，`TreeTransparentCutout`，`TreeBillboard`，`Grass` 和 `GrassBillboard`。以下代码示例，表示将目标物体作为草地进行渲染。

        ```java
        "RenderType"="Grass"
        ```

        渲染类别仅作为一种内部的约定，对于渲染效果没有影响，主要作用在于配合引擎 Camera 类型的 SetReplacementShader 接口，实现着色器的批量替换。以下代码示例，可以将摄像机 camera 下渲染的着色器与 MyShader 两者的 RenderType 进行比对，相同时替换为 MyShader，否则不再渲染。

        ```java
        camera.SetReplacementShader("MyShader", "RenderType");
        ```

    + DisableBatching

        用于设置批处理的禁用方式。禁用方式有 `True`，`False` 和 `LODFading` 三种。以下代码示例，表示当 LOD 淡化启用时禁用批处理。

        ```java
        "DisableBatching"="LODFading"
        ```

        禁用批处理主要解决 DrawCall 合批时，某些进行对象空间顶点变形的着色器失效的问题。

    + ForceNoShadowCasting

        用于关闭阴影投射。以下代码示例，表示关闭目标物体的阴影投射，即便是通过 UsePass 从其他着色器中复用的阴影投射通道也不会生效。

        ```java
        "ForceNoShadowCasting"="False"
        ```

    + IgnoreProjector

        用于设置是否会受到投影的影响。以下代码示例，表示目标物体的渲染不会受到引擎 Projector 组件的影响。

        ```java
        "IgnoreProjector"="True"
        ```

    + CanUseSpriteAtlas

        用于设置着色器对于图集贴图的影响。如果着色器应用于图集贴图资源，需要将该标签设置为 `False`，如此着色器就会失效，避免对图集的使用产生干扰。

    + PreviewType

        用于设置着色器在材质面板中的预览效果。以下代码示例，表示着色器在材质面板中以天空盒的形式进行预览。

        ```java
        "PreviewType"="Skybox"
        ```

    Pass支持的标签类型如下：

    + LightMode

        用于定义 Pass 在渲染流水线中的角色。标签值有 `Always`，`ForwardBase`，`ForwardAdd`，`Deferred`，`ShadowCaster`，`MotionVectors`，`PrepassBase`，`PrepassFinal`，`Vertex`，`VertexLMRGBM` 和 `VertexLM`。以下代码示例，表示 Pass 在前向渲染中使用，并且应用环境光，主方向光，顶点/SH 光源和光照贴图。

        ```java
        "LightMode"="ForwardBase"
        ```

    + RequireOptions

        用于指示渲染 Pass 时需要满足的外部条件。目前引擎提供的选项为`SoftVegetation`，表示仅当 Quality 窗口中开启了 Soft Vegetation 时才会渲染当前的 Pass。

+ CGPROGRAM

    用于标记着色器中 CG/HLSL 代码片段的开始，与 ENDCG 成对出现。

+ ENDCG

    用于标记着色器中 CG/HLSL 代码片段的结束，与 CGPROGRAM 成对出现。

+ surface

    用于指定表面着色器函数与光照模型。以下代码示例，表示指定函数 `surf` 作为表面着色器函数，使用的光照模型为 Lambert。

    ```java
    #pragma surface surf Lambert
    ```

+ vertex

    用于指定顶点着色器函数。以下代码示例，表示指定函数 `vert` 作为顶点着色器函数。

    ```java
    #pragma vertex vert
    ```

+ fragment

    用于指定片元着色器函数。以下代码示例，表示指定函数 `frag` 作为片元着色器函数。

    ```java
    #pragma fragment frag
    ```
