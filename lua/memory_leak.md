# Lua 内存泄漏


## 内存泄漏的关注对象

参与 Lua 垃圾回收的对象（下称 GC 对象）类型都应该被我们关注，包括 `table`，`function`，`userdata`，`thread` 和 `string`。其中泄漏情况普遍出现在前三者上。


## 什么是内存泄漏

我们认为的 Lua 内存泄漏有两种情况：

+ GC 对象引用残留，即我们认为它变为不可达（Unreachable）的状态，实际却相反并始终占用内存。

+ 容器中的内容（不限 GC 对象，可以是 `number`，`boolean` 等类型的值）未被及时清理，使得容器的内存占用越来越大。

第二种情况在项目中出现的频率较低，因为大部分开发者对于容器对象都会有一定的维护意识，而且 Lua 的容器类型只有 `table` 这一种，姑且可以视为第一种泄漏情况的一个分支。因此我们需要重点关注第一种泄漏情况。

根据Lua的设计，如果一个GC对象仍然存在引用，那么它的引用链的根节点必然为常驻内容，有以下三种情况（可以是三者之一，三者之二或皆有）：

+ 全局表，包括 `_G` 和 `_G` 的元表。

+ C 注册表，即 `debug.getregistry()` 的返回值。

+ 当前上下文，通常是 Lua 层的入口文件。

这也意味着，如果我们需要确定一个 GC 对象是否残留引用，我们可以从以上三种情况出发，自顶向下逐层追溯，检查是否能够找到目标的 GC 对象。


## 常见的泄漏情况

根据以往的项目经验，常见的 Lua 内存泄漏情况主要有以下两种：

+ 没有及时清理 GC 对象的引用

    ```lua
    function LoginControl:Init()
        -- 自行增加了 LoginView 的引用，可能没有及时清理
        self._loginView = UIMgr.Instance:GetView("LoginView")
    end

    function LoginServerListSubView:OnShow()
        local listData = LoginModel.Instance:GetServerListData()
        for index, itemData in ipairs(listData) do
            -- 自行增加了若干 LoginServerListItem 的引用，可能没有及时清理
            self._serverListItems[index] = LoginServerListItem.New(itemData)
        end
    end
    ```

    解决方案：

    + 在设计底层的 Mgr 类型时，**不建议提供将缓存的对象直接暴露给上层的接口**，例如 `UIMgr.GetView`。这种接口除了会增加内存泄漏的机会之外，还不可靠，例如界面在加载时或者尚未加载过，它的返回值都会为空。如果必须要对缓存对象进行访问，建议采用一些间接的做法，例如事件或者 RPC

        ```lua
        -- 类似 RPC 的做法
        function UIMgr:CallViewFunc(viewName, funcName, ...)
            local view = self._views[viewName]
            local func = view and view[funcName]
            if func then
                func(view, ...)
            end
        end

        function LoginControl:SetDefaultAccountName()
            UIMgr.Instance:CallViewFunc("ViewName", "SetAccount", LoginModel.Instance:GetDefaultAccountName())
        end

        function LoginView:SetAccount(accountName)
            -- Do something...
        end
        ```

    + 在设计底层的基类时，可以提供默认的析构函数，主动将一些 GC 对象的引用置空，不必让上层考虑内存泄漏的问题

        ```lua
        -- 做法不唯一，需要结合实际情况
        function ViewBase:Dtor()
            for k, _ in pairs(self) do
                self[k] = nil
            end
        end
        ```

+ 通过函数闭包进行引用

    ```lua
    function LoginServerListSubView:Init()
        local listData = LoginModel.Instance:GetServerListData()
        for index, item in ipairs(self.__serverListItems) do
            -- 创建了若干闭包，闭包对 listData 进行引用
            item:SetClickCallback(function()
                self:_OnServerListItemClicked(index, listData[index])
            end)
        end
    end

    function LoginServerListSubView:_OnServerListItemClicked(index, itemData)
        -- Do something...
    end
    ```

    解决方案：

    + **尽可能用成员函数代替闭包**。除了内存泄漏的问题，这也是出于效率上的考虑。例如对于上述示例中的情况，可以将 `_OnServerListItemClicked` 作为 `LoginServerListItem` 类的成员函数，而不是 `LoginServerListSubView` 的成员函数，在初始化时传入所需的参数，这样就不必构建闭包了，例如：

        ```lua
        function LoginServerListSubView:Init()
            local listData = LoginModel.Instance:GetServerListData()
            for index, item in ipairs(self.__serverListItems) do
                item:Init(index, listData[index])
            end
        end

        function LoginServerListItem:Init(index, itemData)
            self._index = index
            self._itemData = itemData
        end

        function LoginServerListItem:_OnServerListItemClicked()
            -- Do something...
        end
        ```


## 示例代码

### 引用链入口的访问

```lua
-- 全局表
local entry = _G
local entryMt = getmetatable(_G)

-- C注册表
local entry = debug.getregistry()

-- 当前上下文
-- debug.getlocal(level, local):
-- - 参数level为调用栈序号, 1表示当前函数调用栈(上下文)
-- - 参数local为调用栈内局部变量的序号
-- - 返回局部变量的名称和值
local index = 1
while true do
    local entryName, entry = debug.getlocal(1, index)
    if not entryName then
        break
    end
    index = index + 1
end
```

### 引用的检查

```lua
function FindRef(entry, targetObj)
    local foundTable = {}
    local queue = {}
    table.insert(queue, entry, 1)
    while #queue > 0 do
        local obj = table.remove(queue, 1)
        foundTable[obj] = true
        if obj == targetObj then
            return true
        elseif type(obj) == "table" then
            -- table索引形式
            for key, value in pairs(obj) do
                if not foundTable[key] then
                    table.insert(queue, key, 1)
                end
                if not foundTable[value] then
                    table.insert(queue, value, 1)
                end
            end
        elseif type(obj) == "function" then
            -- upvalue，例如被function类型以闭包形式捕获的变量
            -- debug.getupvalue(f, up):
            -- - 参数f为函数对象
            -- - 参数up为函数对象捕获的upvalue序号
            -- - 返回upvalue的名称和值
            local index = 1
            while true do
                local name, value = debug.getupvalue(obj, index)
                if not name then
                    break
                end
                if not foundTable[value] then
                    table.insert(queue, value, 1)
                end
                index = index + 1
            end
        end
    end
    return false
end
```


## 弱引用表的使用

Lua 存在弱引用表的设计，它提供弱 引用键（Key） 和 弱引用值（Value） ，用于以弱引用方式引用 **可被回收的 GC 对象** （这里的可被回收是指能够自动从弱引用表中移除）。这种方式不会真正增加引用计数， **当某个 GC 对象除弱引用外没有其他的引用，它仍然可以被回收** 。

例如一个可被回收的 GC 对象，当它以弱引用的方式被引用时，如果它的所有强引用数目为0，那么它在弱引用表中的 **所有键值对** （可能存在多个弱引用）都会被移除；而对于一个不可回收的 GC 对象，即使它的所有强引用数目为0，它在弱引用表中的键值对也不会被移除。

需要注意，除了常规类型，如 `number` 和 `boolean` 之外，弱引用对于 `string` 类型（尽管它属于 GC 对象类型）也是无效的，因为弱引用只对 **具备显式构造方法** 的 GC 对象（即可被回收的 GC 对象）有效。因此可被回收的 GC 对象类型有 `table`，`function`，`userdata` 和 `thread`。

我们可以利用弱引用表的特性，对创建过的 GC 对象进行跟踪，检查它们是否出现了泄漏的情况。原则上，它们既可以作为弱引用键，也可以作为弱引用值，为了便于索引，我们通常将它们作为弱引用键。示例如下：

```lua
RefChecker = {}

function RefChecker:Init()
    -- 通过设置元方法 __mode 让 self._weakRefs 成为弱引用表:
    -- __mode = "k" 表示使用弱引用键
    -- __mode = "v" 表示使用弱引用值
    -- __mode = "kv" 表示键值都为弱引用
    self._weakRefs = setmetatable({}, { __mode = "k" })
end

function RefChecker:Reset()
    self._weakRefs = nil
end

function RefChecker:Print()
    print("Obj list:")
    for obj, _ in pairs(self._weakRefs) do
        print(tostring(obj))
    end
end

function RefChecker:Register(obj)
    self._weakRefs[obj] = true
end

-- 通常不会用到，仅作调试用途，因为正常情况下 GC 对象没有被引用时，它的弱引用会被自动移除
function RefChecker:Unregister(obj)
    self._weakRefs[obj] = nil
end
```


## 参考资料

+ https://zhuanlan.zhihu.com/p/45000232

+ https://blog.csdn.net/yxtxiaotian/article/details/51475856

+ https://www.lua.org/manual/5.3/
