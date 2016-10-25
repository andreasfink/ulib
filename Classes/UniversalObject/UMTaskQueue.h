//
//  UMTaskQueue.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMObject.h"


/*

 UMTaskQueue is an object to deal with background queues
 It holds a bunch of UMBackgrounderWithQueue objecs which share a
 common queue where you can stuff UMBackgroundTask objects into.

 */

@class UMQueue;
@class UMBackgrounderWithQueue;
@class UMTask;
@class UMSleeper;

@interface UMTaskQueue : UMObject
{
    BOOL            enableLogging;
    NSString        *name;
    UMQueue         *mainQueue;
    UMSleeper       *workSleeper;
    NSMutableArray  *workerThreads; /* UMBackgrounderWithQueue objects */
}

@property (strong) NSString     *name;
@property (strong) UMSleeper    *workSleeper;
@property (assign) BOOL         enableLogging;

- (UMTaskQueue *)init;
- (UMTaskQueue *)initWithNumberOfThreads:(int)workerThreadCount name:(NSString *)n enableLogging:(BOOL)enableLog;
- (void)queueTask:(UMTask *)task;

- (void)start;
- (void)shutdown;


@end

int ulib_cpu_count(void);
