# 资产的访问


## 资产的扫描

引擎提供了 `UObjectLibrary` 类型，用于扫描特定类型的资产。常用的接口是 `LoadAssetDataFromPath` 和 `LoadAssetDataFromPaths` ，这两个接口可以获取资产的必要信息，以 `FAssetData` 类型返回，并不会真正将资产加载到内存。

示例：

```cpp
/**
 * 创建一个专用于扫描控件蓝图的库
 *
 * @param InBaseClass             资产类型
 * @param bInHasBlueprintClasses  是否包含 InBaseClass 子类的资产
 * @param bInUseWeak              是否以弱引用形式引用资产
 */
UObjectLibrary* const Library = UObjectLibrary::CreateLibrary(UWidgetBlueprint::StaticClass(), true, true);

/**
 * 资产目录
 * 以项目的 Content 目录作为根目录，格式是 "/Game/aa/bb/cc"
 */
const FString AssetDirectory;
// 递归扫描 AssetDirectory 下的资产
Library->LoadAssetDataFromPath(AssetDirectory);

TArray<FAssetData> AssetDatas;
// 获取扫描得到的资产信息
Library->GetAssetDataList(AssetDatas);
for (const FAssetData& AssetData : AssetDatas)
{
    // 资产的名称，不含路径信息
    const FName& AssetName = AssetData.AssetName;
    // 资产的路径，格式是 "/Game/aa/bb/cc/asset.asset" ，可用于加载资产
    const FSoftObjectPath& AssetPath = AssetData.ToSoftObjectPath();
    // ...
}
```


## 单个资产的访问

如果需要指定访问某个资产的信息，例如判断资产是否存在，可以使用 `IAssetRegistry` 类的 `GetAssetByObjectPath` 接口。

示例：

```cpp
// 资产路径，以项目的 Content 目录作为根目录，格式是 "/Game/aa/bb/cc/asset.asset"
const FString AssetPath;

/**
 * 获取资产信息
 * 注意 GetAssetByObjectPath 的参数列表从 UE5.1 开始有所变化
 */
IAssetRegistry& AssetRegistry = FModuleManager::GetModuleChecked<FAssetRegistryModule>(FName(TEXT("AssetRegistry"))).Get();
#if ENGINE_MAJOR_VERSION == 5 && ENGINE_MINOR_VERSION >= 1 || ENGINE_MAJOR_VERSION > 5
const FAssetData& AssetData = AssetRegistry.GetAssetByObjectPath(FSoftObjectPath(AssetPath));
#else
const FAssetData& AssetData = AssetRegistry.GetAssetByObjectPath(FName(AssetPath));
#endif

// 通过资产信息的有效性来判断资产是否存在
const bool bIsAssetExisted = AssetData.IsValid();
```
