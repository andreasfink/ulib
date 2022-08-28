//
//  UMTaskQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMTaskQueue.h"
#import "UMBackgrounderWithQueue.h"
#import "UMQueueSingle.h"
#import "UMSleeper.h"
#import "UMTaskQueueTask.h"
#import "UMFileTrackingMacros.h"
#include <sys/types.h>
#if defined(HAVE_SYS_SYSCTL_H)
#include <sys/sysctl.h>
#endif

#include <string.h>
#import "UMAssert.h"

@implementation UMTaskQueue

- (UMTaskQueue *)init
{
    /* default number of threads is twice the number of CPU cores */
    /* this allows long running jobs to run while smaller shorter jobs can run in parallel */
    int threadCount = ulib_cpu_count() * 2;
    if(threadCount > 8)
    {
        threadCount = 8;
    }
    return [self initWithNumberOfThreads:threadCount name:@"UMBackgroundQueue" enableLogging:NO];
}

- (UMTaskQueue *)initWithNumberOfThreads:(NSUInteger)workerThreadCount
                                    name:(NSString *)n
                           enableLogging:(BOOL)enableLog
{
    UMAssert(n.length > 0,@"UMTaskQueue initWithNumberOfThreads:name:enableLogging: has no name being passed");
    if(workerThreadCount > 8)
    {
        NSLog(@"UMTaskQueue initWithNumberOfThreads=%lu (%@) really want that many?",workerThreadCount,n);
        if(workerThreadCount > 64)
        {
            NSLog(@"UMTaskQueue initWithNumberOfThreads=%lu (%@) limiting to 8?",workerThreadCount,n);
            workerThreadCount = 8;
        }
    }
    self = [super init];
    if(self)
    {
        _name = n;
        _enableLogging = enableLog;
        _mainQueue = [[UMQueueSingle alloc]init];
        _workerThreads = [[NSMutableArray alloc]init];
        int i;
        _workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [_workSleeper prepare];
        for(i=0;i<workerThreadCount;i++)
        {
            NSString *newName = [NSString stringWithFormat:@"%@[%d]",n,i];
            UMBackgrounderWithQueue *bg = [[UMBackgrounderWithQueue alloc]initWithSharedQueue:_mainQueue
                                                                                         name:newName
                                                                                  workSleeper:_workSleeper];
            bg.enableLogging = self.enableLogging;
            [_workerThreads addObject:bg];
        }
    }
    return self;
}

- (void)queueTask:(UMTaskQueueTask *)task
{
    @autoreleasepool
    {
        if(_enableLogging)
        {
            task.enableLogging = YES;
        }
        task.taskQueue = self;
        [_mainQueue append:task];
        [_workSleeper wakeUp];
    }
}

- (void)start
{
    @autoreleasepool
    {
        for(UMBackgrounderWithQueue *bg in _workerThreads)
        {
            [bg startBackgroundTask];
        }
    }
}

- (NSUInteger)count
{
    return [_mainQueue count];
}

- (void)shutdown
{
    @autoreleasepool
    {
        
        for(UMBackgrounderWithQueue *bg in _workerThreads)
        {
            [bg shutdownBackgroundTask];
        }
    }
}

@end

static int g_cpu_count = 0;

#ifdef __APPLE__
int ulib_cpu_count()
{
    if(g_cpu_count)
    {
        return g_cpu_count;
    }
    int cpu_count = 0;
    size_t buflen = sizeof(cpu_count);
    sysctlbyname("hw.ncpu",&cpu_count,&buflen, NULL,0);
    if(cpu_count <= 0)
    {
        return 5;
    }
    g_cpu_count = cpu_count;
    return cpu_count;
}
#endif

#ifdef LINUX
int ulib_cpu_count()
{
    if(g_cpu_count)
    {
        return g_cpu_count;
    }

    char line[256];

    FILE *f = fopen("/proc/cpuinfo","r");
    TRACK_FILE_FOPEN(f,@"/proc/cpuinfo");
    int cpu_count = 0;
    if(f)
    {
        const char processorLine[] = "processor";
        fgets(line, sizeof(line)-1, f);
        if(strncmp(line,processorLine, sizeof(processorLine)) == 0)
        {
            cpu_count++;
        }
        TRACK_FILE_FCLOSE(f);
        fclose(f);
    }
    if(cpu_count <= 0)
    {
        return 5;
    }
    g_cpu_count = cpu_count;
    return cpu_count;
}
#endif

#ifdef FREEBSD
int ulib_cpu_count()
{
    if(g_cpu_count)
    {
        return g_cpu_count;
    }
    int cpu_count = 0;
    size_t buflen = sizeof(cpu_count);
    sysctlbyname("hw.ncpu",&cpu_count,&buflen, NULL,0);
    if(cpu_count <= 0)
    {
        return 5;
    }
    g_cpu_count = cpu_count;
    return cpu_count;
}
#endif

