# 引用类型类成员变量的绑定


在比较严格的编译环境，例如 Android 和 iOS 中，可能会出现以下编译错误：

```
binding reference member 'xx' to stack allocated parameter 'yy'
```

原因是在类的构造函数中，将临时变量传递给了引用类型的成员变量，并且前者的生命周期小于后者。示例如下：

```c++
using std::string;

class FObj
{
	// 成员变量 name 属于 std::string 的常引用类型
	const string& name;

	// 成员变量 name 的生命周期与 FObj 实例的生命周期相同；而临时变量 newName 只在 FObj 构造函数的作用域内有效，使得 FObj 的构造函数调用完成后，成员变量 name 的引用丢失
	void FObj(const string newName) : name(newName)
	{

	}
};
```

解决方法是避免将临时变量赋值给引用，具体有两种做法：

+ 改用引用传递的方式

	以上述示例为例：

	```c++
	/**
	 * 旧的做法：
	   void FObj(const string newName) : name(newName)
	   {

	   }
	 *
	 * 新的做法：
	   参数 new 同样为常引用，而非临时创建的变量，可以确保与成员变量 name 的生命周期保持一致
	 */
	void FObj(const string& newName) : name(newName)
	{

	}
	```

+ 改为值传递的方式

	以上述示例为例：

	```c++
	/**
	 * 旧的做法：
	   const string& name;
	 *
	 * 新的做法：
	   成员变量 name 为普通的常量，在构造函数中赋值时会重新分配内存空间，拥有独立的生命周期
	 */
	const string name;
	```

由于 VC++ 编译器的不严谨，将临时变量传递给引用的写法也许可以编译通过，不过在日常开发中，请避免使用这种写法，除非对性能十分敏感，并且确保临时变量的生命周期大于类成员变量。
