//
//  UMTaskQueueMulti.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"

/*!
 @class UMTaskQueueMulti
 @brief UMTaskQueueMulti is an object to deal with background queues
 It holds a bunch of UMBackgrounderWithQueue objecs which share a
 common queue where you can stuff UMTask objects into. In comparison to UMTaskQueue
 a UMTaskQueueMulti has multiple priority queues instead of only one queue.

 */

@class UMQueueMulti;
@class UMBackgrounderWithQueue;
@class UMTask;
@class UMSleeper;
@class UMThrougputCounter;

@interface UMTaskQueueMulti : UMObject
{
    BOOL            enableLogging;
    NSString        *name;
    UMQueueMulti    *_multiQueue;
    UMSleeper       *workSleeper;
    NSMutableArray  *workerThreads; /* UMBackgrounderWithQueues objects */
    BOOL            _debug;
    UMThrougputCounter *throughput;
}

@property (strong) NSString     *name;
@property (strong) UMSleeper    *workSleeper;
@property (assign) BOOL         enableLogging;
@property (assign) BOOL         debug;
@property (strong)  UMQueueMulti    *multiQueue;



- (UMTaskQueueMulti *)init;
- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                               numberOfQueues:(int)queueCount;

- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                               numberOfQueues:(int)queueCount
                                        debug:(BOOL)debug
                                    hardLimit:(NSUInteger)hardLimit;


- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                                       queues:(UMQueueMulti *)xqueues;

- (UMTaskQueueMulti *)initWithNumberOfThreads:(int)workerThreadCount
                                         name:(NSString *)n
                                enableLogging:(BOOL)enableLog
                                       queues:(UMQueueMulti *)xqueues
                                        debug:(BOOL)xdebug
                                    hardLimit:(NSUInteger)hardLimit;

- (void)queueTask:(UMTask *)task toQueueNumber:(int)nr;

- (void)start;
- (void)shutdown;
- (NSUInteger)count;
- (NSDictionary *)status;

@end
