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
