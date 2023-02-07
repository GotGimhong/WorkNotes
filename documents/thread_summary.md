# 多线程的概述

多线程的本质是启用**子线程**，在子线程中执行一个开销较大的**线程主体函数**，依次分担游戏线程（主线程）的压力。


## 多线程的支持

判断当前平台是否支持多线程可以通过引擎接口 `FPlatformProcess::SupportsMultithreading()` 查询。


## 多线程的使用方式

多线程有三种使用方式：**并发执行**，**异步任务**和**自定义子线程**，这三种方式都可以实现异步调用。

### 并发/分布式执行

调用 `ParallelFor` 接口，让引擎将主体函数分配到一个子线程当中，使主体函数并发执行若干次。

`ParallelFor` 接口的声明请见引擎 Core 模块的 ParallelFor.h 文件。

示例：

```c++
/**
 * 并发执行主体函数5次
 *
 * @param Num   并发执行的次数
 * @param Body  主体函数，参数 Index 表示执行次数的序号
 * @param Flags 并发标记，对应枚举类型 EParallelForFlags
 */
ParallelFor(5, [](int32 Index) -> void
    {
        // 主体函数
        // To do...
    },
    EParallelForFlags::None
);
```

引擎会自动分配子线程，并且必然将第一次执行分配到**主线程**当中。如果不希望阻塞主线程，就不建议使用这种方式。

### 异步任务

调用 `AsyncTask` 接口，从引擎的线程池当中选择一个线程来执行主体函数。

`AsyncTask` 接口的声明请见引擎 Core 模块的 Async.h 文件。

示例：

```c++
/**
 * 选择任意一个线程来执行主体函数
 *
 * @param Thread    指定的线程，对应枚举类型 ENamedThreads::Type
 * @param Function  主体函数
 */
AsyncTask(ENamedThreads::AnyThread, []() -> void
    {
        // 主体函数
        // To do...
    }
);
```

在 `ENamedThreads::Type` 当中，可以选择主线程，即 `ENamedThreads::Type::GameThread`，如果不希望阻塞主线程，就应该避免选择 `ENamedThreads::Type::GameThread`。

### 自定义子线程

创建一个 `FRunnable` 类的子类，配合 `FRunnableThread` 类，实现自定义的子线程。

示例：

```c++
class FMyRunnable : public FRunnable
{
public:
    FMyRunnable()
    {
        Thread = FRunnableThread::Create(this, TEXT("MyRunnable"));
    }
    ~FMyRunnable()
    {
        Thread->Kill(true);
        delete Thread;
    }

protected:
    /** 子线程开始运行时的处理，只有在返回 true 的时候子线程才会真正运行 */
    virtual bool Init() override;
    /** 子线程循环 */
    virtual uint32 Run() override;
    /** 子线程结束运行时的处理 */
    virtual void Exit() override;
    /** 子线程被终止时的处理，通过 FRunnableThread::Kill 触发 */
    virtual void Stop() override;

private:
    FRunnableThread* Thread;
};
```

相较于 [异步任务](#异步任务) ，这种方式可以更加灵活地指定子线程的行为，例如子线程的生命周期和挂起时间，但是需要自行做好子线程的维护，以免出现内存泄漏和线程冲突等问题。完整说明请见 [多线程的定制](thread_runnable.md) 。


## 线程冲突

### 线程冲突的原理

在不同的线程中，应当避免访问来自同一个内存地址的数据。例如在线程 A 和 B 的主体函数中，同时访问或者修改了一个静态变量，那么 A 和 B 很可能就会出现线程冲突。

线程冲突通常可以归结为 [生产者-消费者问题](https://en.wikipedia.org/wiki/Producer–consumer_problem) ，即一部分线程（生产者）向一个内存地址写入或修改数据，另一部分线程（消费者）从该内存地址读取数据。这个问题的应对策略，一是控制线程的数目，通常情况下消费者线程应该有且只有一个，二是避免让一个线程既作为生产者又作为消费者。

### 线程安全的数据类型

线程冲突的第一个解决方法，就是使用引擎提供的线程安全的数据类型。例如使用智能指针类型 `TSharedPtr` 和 `TWeakPtr` 包装数据，或者使用容器类型 `TQueue`，`TLockFreePointerListLIFO`，`TLockFreePointerListFIFO`，`TLockFreePointerListUnordered` 和 `TClosableLockFreePointerListUnorderedSingleConsumer`。以 `TQueue` 为例，它有 多生产者单消费者（MPSC） 和 单生产者单消费者（SPSC） 两种模式，其中 `Enqueue` 属于生产者接口，`Dequeue`，`Pop` 和 `IsEmpty` 属于消费者接口。尽管 `TQueue` 是线程安全的类型，但是它只能保证在不同的生产者线程和消费者线程之间不会出现线程冲突。如果让一个线程同时作为生产者和消费者，就会引起新的线程冲突。

### 锁机制

线程冲突的第二个解决方法，就是使用 锁机制 ，即“加锁”。引擎提供了 `FCriticalSection` 和 `FScopeLock` 两个类型用于实现锁机制。

#### FCriticalSection

`FCriticalSection` 类型可以理解为信号量，或者互斥锁。它提供了 `Lock` 和 `Unlock` 两个接口，分别用于加锁（递增信号量）和解锁（递减信号量），在这两个接口调用之间的代码块是线程安全的。示例如下：

```c++
// 信号量/互斥锁
static FCriticalSection Mutex;

int ThreadLoop()
{
    {
        // 代码块1: 非线程安全
    }
    Mutex.Lock();
    {
        // 代码块2: 线程安全
    }
    Mutex.Unlock();
    {
        // 代码块3: 非线程安全
    }
    return 0;
}
```

请注意（以下使用“信号量”进行表述）：

+ 信号量必须能够在线程之间共享，因此通常会被声明为静态变量或者静态的类成员变量

+ `Lock` 和 `Unlock` 的调用必须成对出现，如果两者的调用不匹配，并且 `Lock` 的调用次数多于 `Unlock`，就会导致死锁

#### FScopeLock

`FScopeLock` 是 `FCriticalSection` 的一个派生类型。它不提供任何接口，直接让其作用域处于线程安全的状态，原理是 `FScopeLock` 在构造函数中调用 `Lock`，在析构函数中调用 `Unlock`。示例如下：

```c++
// 信号量/互斥锁
static FCriticalSection Mutex;

int ThreadLoop1()
{
    {
        // 代码块1: 非线程安全
    }
    {
        const FScopeLock Lock(&Mutex);
        // 代码块2: 线程安全
    }
    {
        // 代码块3: 非线程安全
    }
    return 0;
}

int ThreadLoop2()
{
    {
        // 代码块1: 非线程安全
    }
    const FScopeLock* const Lock = new FScopeLock(&Mutex);
    {
        // 代码块2: 线程安全
    }
    delete Lock;
    {
        // 代码块3: 非线程安全
    }
    return 0;
}
```

直接使用 `FCriticalSection` 和使用 `FScopeLock` 在效果上是等价的，因此使用 `FScopeLock` 时同样需要考虑 `Lock` 和 `Unlock` 接口调用的匹配，如果使用动态分配堆内存的方式实例化 `FScopeLock` 却没有及时释放内存，就会导致死锁。
