//
//  UMTaskQueue.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMTaskQueue.h"
#import "UMBackgrounderWithQueue.h"
#import "UMQueue.h"
#import "UMSleeper.h"
#import "UMTask.h"
#import "UMFileTrackingMacros.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <string.h>

@implementation UMTaskQueue
@synthesize name;
@synthesize workSleeper;
@synthesize enableLogging;

- (UMTaskQueue *)init
{
    /* default number of threads is twice the number of CPU cores */
    /* this allows long running jobs to run while smaller shorter jobs can run in parallel */
    return [self initWithNumberOfThreads:ulib_cpu_count() * 2 name:@"UMBackgroundQueue" enableLogging:NO];
}

- (UMTaskQueue *)initWithNumberOfThreads:(int)workerThreadCount name:(NSString *)n enableLogging:(BOOL)enableLog
{
    self = [super init];
    if(self)
    {
        self.name = n;
        self.enableLogging = enableLog;
        mainQueue = [[UMQueue alloc]init];
        workerThreads = [[NSMutableArray alloc]init];
        int i;
        self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [self.workSleeper prepare];
        for(i=0;i<workerThreadCount;i++)
        {
            NSString *newName = [NSString stringWithFormat:@"%@[%d]",n,i];
            UMBackgrounderWithQueue *bg = [[UMBackgrounderWithQueue alloc]initWithSharedQueue:mainQueue name:newName workSleeper:workSleeper];
            bg.enableLogging = self.enableLogging;
            [workerThreads addObject:bg];
        }
    }
    return self;
}

- (void)queueTask:(UMTask *)task
{
    @autoreleasepool
    {
        if(enableLogging)
        {
            task.enableLogging = YES;
        }
        [mainQueue append:task];
        [workSleeper wakeUp];
    }
    
}

- (void)start
{
    @autoreleasepool
    {
        for(UMBackgrounderWithQueue *bg in workerThreads)
        {
            [bg startBackgroundTask];
        }
    }
}

- (void)shutdown
{
    @autoreleasepool
    {
        
        for(UMBackgrounderWithQueue *bg in workerThreads)
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
    }
    TRACK_FILE_FCLOSE(f);
    fclose(f);
    if(cpu_count <= 0)
    {
        return 5;
    }
    g_cpu_count = cpu_count;
    return cpu_count;
}
#endif

