//
//  UMTaskQueue.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"


/*!
 @class UMTaskQueue
 @brief UMTaskQueue is an object to deal with background queues
 It holds a bunch of UMBackgrounderWithQueue objecs which share a
 common queue where you can stuff UMTaskQueueTask objects into.

 */

@class UMQueueSingle;
@class UMBackgrounderWithQueue;
@class UMTaskQueueTask;
@class UMSleeper;

@interface UMTaskQueue : UMObject
{
    BOOL            _enableLogging;
    NSString        *_name;
    UMQueueSingle         *_mainQueue;
    UMSleeper       *_workSleeper;
    NSMutableArray  *_workerThreads; /* UMBackgrounderWithQueue objects */
}

@property (strong) NSString     *name;
@property (strong) UMSleeper    *workSleeper;
@property (assign) BOOL         enableLogging;

- (UMTaskQueue *)init;
- (UMTaskQueue *)initWithNumberOfThreads:(NSUInteger)workerThreadCount name:(NSString *)n enableLogging:(BOOL)enableLog;
- (void)queueTask:(UMTaskQueueTask *)task;

- (void)start;
- (void)shutdown;
- (NSUInteger)count;

@end

int ulib_cpu_count(void);
