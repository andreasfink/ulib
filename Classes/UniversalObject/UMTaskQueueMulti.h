//
//  UMTaskQueueMulti.h
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

@interface UMTaskQueueMulti : UMObject
{
    BOOL            enableLogging;
    NSString        *name;
    NSArray         *queues;
    UMSleeper       *workSleeper;
    NSMutableArray  *workerThreads; /* UMBackgrounderWithQueues objects */
}

@property (strong) NSString     *name;
@property (strong) UMSleeper    *workSleeper;
@property (assign) BOOL         enableLogging;

- (UMTaskQueueMulti *)init;
- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                               numberOfQueues:(int)queueCount;

- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                                       queues:(NSArray *)xqueues;

- (void)queueTask:(UMTask *)task toQueueNumber:(int)nr;

- (void)start;
- (void)shutdown;

@end
