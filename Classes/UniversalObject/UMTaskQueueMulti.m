//
//  UMTaskQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMTaskQueueMulti.h"
#import "UMTaskQueue.h"
#import "UMBackgrounderWithQueues.h"
#import "UMQueueMulti.h"
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
                                       queues:(UMQueueMulti *)xqueues
{
    return [self initWithNumberOfThreads:workerThreadCount
                                    name:n
                           enableLogging:enableLog
                                  queues:xqueues
                                   debug:NO
                               hardLimit:0];
}

- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                                       queues:(UMQueueMulti *)xqueues
                                        debug:(BOOL)xdebug
                                    hardLimit:(NSUInteger)hardLimit
{
    self = [super init];
    if(self)
    {
        self.name = n;
        self.enableLogging = enableLog;
        _multiQueue = xqueues;
        workerThreads = [[NSMutableArray alloc]init];
        _debug = xdebug;
        xqueues.hardLimit = hardLimit;
        int i;
        self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        self.workSleeper.debug = xdebug;
        [self.workSleeper prepare];
        for(i=0;i<workerThreadCount;i++)
        {
            NSString *newName = [NSString stringWithFormat:@"%@[%d]",n,i];
            UMBackgrounderWithQueues *bg = [[UMBackgrounderWithQueues alloc]initWithSharedQueues:_multiQueue
                                                                                            name:newName workSleeper:workSleeper];
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
    return [self initWithNumberOfThreads:workerThreadCount
                                    name:n
                           enableLogging:enableLog
                          numberOfQueues:queueCount
                                   debug:NO
                               hardLimit:0];
}

- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                               numberOfQueues:(int)queueCount
                                        debug:(BOOL)debug
                                    hardLimit:(NSUInteger)hardLimit
{
    NSAssert(workerThreadCount>0,@"you must have at least one workerThread for UMTaskQueueMulti");
    self = [super init];
    if(self)
    {
        self.name = n;
        self.enableLogging = enableLog;
        _multiQueue = [[UMQueueMulti alloc]initWithQueueCount:queueCount];
        _multiQueue.hardLimit = hardLimit;

        workerThreads = [[NSMutableArray alloc]init];
        int i;
        self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
        [self.workSleeper prepare];
        for(i=0;i<workerThreadCount;i++)
        {
            NSString *newName = [NSString stringWithFormat:@"%@[%d]",n,i];
            UMBackgrounderWithQueues *bg = [[UMBackgrounderWithQueues alloc]initWithSharedQueues:_multiQueue
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
    if(enableLogging)
    {
        task.enableLogging = YES;
    }
    [_multiQueue append:task forQueueNumber:nr];
    [workSleeper wakeUp];
}

- (NSUInteger)count
{
    return [_multiQueue count];;
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

- (NSDictionary *)status
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"worker-threads"] = @(workerThreads.count);
    dict[@"worker-threads-busy"] = @(_multiQueue.workInProgress);
    dict[@"queues"] = _multiQueue.status;
    return dict;
}

- (NSDictionary *)statusByObjectType
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"worker-threads"] = @(workerThreads.count);
    dict[@"worker-threads-busy"] = @(_multiQueue.workInProgress);
    dict[@"queues"] = _multiQueue.statusByObjectType;
    return dict;
}
@end
