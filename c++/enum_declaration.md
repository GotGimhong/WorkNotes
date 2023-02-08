# 枚举类型的声明方式


C++11 提供了两种枚举类型的声明方式，一种是声明为枚举类（enum class），另一种是在命名空间下采用 C 语言的写法进行声明，示例如下：

```c++
// 声明为枚举类
enum class EMyEnumA
{
	A,
	B,
	C
};

// 在命名空间下使用 C 语言枚举类型的声明方式
namespace EMyEnumB
{
	enum Type
	{
		C,
		D,
		E
	};
}
```

前者将枚举值的作用域（Scope）限定在枚举类本身，后者将枚举类型 `Type` 及其枚举值限定在命名空间中。它们都解决了枚举值冲突的问题，例如以上的例子，尽管两者都包含枚举值 `A`，`B` 和 `C`，但是它们并不会存在冲突。如果使用旧方式进行声明，就要考虑枚举值冲突的问题了：

```c++
enum EMyEnumA
{
	A,
	B,
	C
};

enum EMyEnumB
{
	C,
	D,
	E
}
```

在以上例子中，`EMyEnumA` 和 `EMyEnumB` 都采用 C 语言的写法进行声明，且都包含枚举值 `C`。在这种情况下，枚举值 `A`，`B`，`C`，`D` 和 `E` 的作用域为全局，因此编译时会出现“枚举值 `C` 重复定义”的错误。

两种声明方式访问枚举值的做法是相同的，但是它们的类型却不相同，前者的类型为枚举类本身，后者则是命名空间下的枚举类型，而非命名空间本身，示例如下：

```c++
EMyEnumA enumA = EMyEnumA::C;
EMyEnumB::Type enumB = EMyEnumB::C;
```

两种声明方式在使用上的区别主要在于与整数类型之间的类型转换。其中方式一不支持隐式类型转换，需要手动进行强制类型转换；方式二本质上使用了 C 语言的声明方式，这种方式支持隐式类型转换，所以方式二也支持将枚举值隐式转换为整数类型。示例如下：

```c++
// 编译失败：无法进行隐式类型转换
unsigned int valueA = EMyEnumA::C;
// 编译成功
unsigned int valueB = static_cast<unsigned int>(EMyEnumA::C);
// 编译成功
unsigned int valueC = EMyEnumB::C;
// 编译成功
unsigned int valueD = static_cast<unsigned int>(EMyEnumB::C);
```
