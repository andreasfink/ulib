//
//  UMTaskQueue.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMTaskQueueMulti.h"
#import "UMTaskQueue.h"
#import "UMBackgrounderWithQueues.h"
#import "UMQueue.h"
#import "UMSleeper.h"
#import "UMTask.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#include <string.h>

@implementation UMTaskQueueMulti
@synthesize name;
@synthesize workSleeper;
@synthesize enableLogging;

- (UMTaskQueueMulti *)init
{
    /* default number of threads is twice the number of CPU cores */
    /* this allows long running jobs to run while smaller shorter jobs can run in parallel */
    return [self initWithNumberOfThreads:ulib_cpu_count() * 2 name:@"UMBackgroundQueue" enableLogging:NO numberOfQueues:5];
}


- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                                       queues:(NSArray *)xqueues
{
    self = [super init];
    if(self)
    {
        self.name = n;
        self.enableLogging = enableLog;
        queues = xqueues;
        workerThreads = [[NSMutableArray alloc]init];
        int i;
        self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [self.workSleeper prepare];
        for(i=0;i<workerThreadCount;i++)
        {
            NSString *newName = [NSString stringWithFormat:@"%@[%d]",n,i];
            UMBackgrounderWithQueues *bg = [[UMBackgrounderWithQueues alloc]initWithSharedQueues:queues name:newName workSleeper:workSleeper];
            bg.enableLogging = self.enableLogging;
            [workerThreads addObject:bg];
        }
    }
    return self;
}

- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                               numberOfQueues:(int)queueCount
{
    self = [super init];
    if(self)
    {
        self.name = n;
        self.enableLogging = enableLog;
        NSMutableArray *qarr = [[NSMutableArray alloc]init];
        while(queueCount--)
        {
            [qarr addObject:[[UMQueue alloc]init]];
        }
        queues = qarr;
        workerThreads = [[NSMutableArray alloc]init];
        int i;
        self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [self.workSleeper prepare];
        for(i=0;i<workerThreadCount;i++)
        {
            NSString *newName = [NSString stringWithFormat:@"%@[%d]",n,i];
            UMBackgrounderWithQueues *bg = [[UMBackgrounderWithQueues alloc]initWithSharedQueues:queues
                                                                                           name:newName
                                                                                    workSleeper:workSleeper];
            bg.enableLogging = self.enableLogging;
            [workerThreads addObject:bg];
            [bg startBackgroundTask];
        }
    }
    return self;
}

- (void)queueTask:(UMTask *)task toQueueNumber:(int)nr
{
    if(task==NULL)
    {
        return;
    }
    @autoreleasepool
    {
        if(enableLogging)
        {
            task.enableLogging = YES;
        }
        @synchronized (queues)
        {
            UMQueue *queue = [queues objectAtIndex:nr];
            if(queue)
            {
                [queue append:task];
            }
        }
        [workSleeper wakeUp];
    }
}

- (void)start
{
    for(UMBackgrounderWithQueue *bg in workerThreads)
    {
        [bg startBackgroundTask];
    }
}

- (void)shutdown
{
    for(UMBackgrounderWithQueue *bg in workerThreads)
    {
        [bg shutdownBackgroundTask];
    }
}

@end
