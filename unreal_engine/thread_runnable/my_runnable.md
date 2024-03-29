<details>

<summary>MyRunnable.h</summary>

```cpp
#pragma once

#include "Runnable.h"
#include "SingleThreadRunnable.h"

class FMyRunnable
    : protected FRunnable
    , protected FSingleThreadRunnable
{
public:
    FMyRunnable(const TCHAR* InName);
    ~FMyRunnable();

    /**
     * 两次线程循环之间的最小执行间隔（秒）
     */
    static const float MIN_INTERVAL;
    /**
     * 两次线程循环之间的执行间隔（秒）
     * 原则上它不能小于 MIN_INTERVAL，以免子线程占用过多资源
     */
    float Interval;

protected:
    // Begin FRunnable
    virtual bool Init() override;
    virtual uint32 Run() override;
    virtual void Stop() override;
    virtual void Exit() override;
    // End FRunnable

    // Begin FSingleThreadRunnable
    virtual FSingleThreadRunnable* GetSingleThreadInterface() override;
    virtual void Tick() override;
    // End FSingleThreadRunnable

private:
    /** 线程主体函数 */
    void Loop();
    /** 计算子线程的运行时间 */
    double GetElapsed() const;

    /** 绑定的子线程 */
    class FRunnableThread* Thread;
    /** 子线程名称 */
    const FString Name;
    /** 子线程是否正在运行 */
    bool bRunning;
    /** 子线程的启动时间 */
    double StartTime;
};
```

</details>


<details>

<summary>MyRunnable.cpp</summary>

```cpp
#include "MyRunnable.h"
#include "RunnableThread.h"
#include "PlatformAffinity.h"
#include "PlatformProcess.h"
#include "PlatformTime.h"

// 请根据实际需要进行调整
const float FMyRunnable::MIN_INTERVAL = 0.1f;

FMyRunnable::FMyRunnable(const TCHAR* const InName)
    : Interval(MIN_INTERVAL)
    , Thread(FRunnableThread::Create(this, Name))
    , Name(InName)
    , bRunning(false)
    , StartTime(0.0)
{

}

FMyRunnable::~FMyRunnable()
{
    if (Thread)
    {
        Thread->Kill();
        // Thread 需要手动回收内存
        delete Thread;
        Thread = nullptr;
    }
}

void FMyRunnable::Loop()
{
    // Todo...
}

double FMyRunnable::GetElapsed() const
{
    return bRunning ? FPlatformTime::Seconds() - StartTime : 0.0;
}

// Begin FRunnable
bool FMyRunnable::Init()
{
    // 线程启动时的处理
    UE_LOG(Log, TEXT("%s: %s Init"), ANSI_TO_TCHAR(__FUNCTION__), *Name);
    bRunning = true
    StartTime = FPlatformTime::Seconds();
    return true;
}

uint32 FMyRunnable::Run()
{
    // 线程主体函数的执行
    UE_LOG(Log, TEXT("%s: %s Run starts, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
    while (bRunning)
    {
        UE_LOG(Log, TEXT("%s: %s Run loops, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
        Loop();
        FPlatformProcess::Sleep(Interval);
    }
    UE_LOG(Log, TEXT("%s: %s Run ends, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
    return 0u;
}

void FMyRunnable::Stop()
{
    // 线程强制中止时的处理，通过 Thread->Kill() 触发
    UE_LOG(Log, TEXT("%s: %s Stop, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
    bRunning = false;
}

void FMyRunnable::Exit()
{
    // 线程结束时的处理，既可以是线程主体函数正常执行完毕，也可以是线程强制中止
    UE_LOG(Log, TEXT("%s: %s Exit, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
}
// End FRunnable

// Begin FSingleThreadRunnable
FSingleThreadRunnable* FMyRunnable::GetSingleThreadInterface()
{
    return this;
}

void FMyRunnable::Tick()
{
    // 模拟线程主体函数的执行
    UE_LOG(Log, TEXT("%s: %s Tick starts, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
    while (bRunning)
    {
        UE_LOG(Log, TEXT("%s: %s Tick loops, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
        Loop();
        // 因为不是真正意义上的多线程，所以不需要调用 FPlatformProcess::Sleep
    }
    UE_LOG(Log, TEXT("%s: %s Tick ends, %lfs"), ANSI_TO_TCHAR(__FUNCTION__), *Name, GetElapsed());
}
// End FSingleThreadRunnable
```

</details>
