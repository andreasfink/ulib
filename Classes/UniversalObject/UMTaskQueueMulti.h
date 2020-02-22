//
//  UMTaskQueueMulti.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"
#import "UMQueueMulti.h"
#import "UMThroughputCounter.h"

/*!
 @class UMTaskQueueMulti
 @brief UMTaskQueueMulti is an object to deal with background queues
 It holds a bunch of UMBackgrounderWithQueue objecs which share a
 common queue where you can stuff UMTask objects into. In comparison to UMTaskQueue
 a UMTaskQueueMulti has multiple priority queues instead of only one queue.

 */

@class UMBackgrounderWithQueue;
@class UMTask;
@class UMSleeper;
@class UMThroughputCounter;
@interface UMTaskQueueMulti : UMObject
{
    BOOL            _enableLogging;
    NSString        *_name;
    UMQueueMulti    *_multiQueue;
    UMSleeper       *_workSleeper;
    NSMutableArray  *_workerThreads; /* UMBackgrounderWithQueues objects */
    BOOL            _debug;
    UMThroughputCounter *_throughput;
}

@property (assign) BOOL         	enableLogging;
@property (strong) NSString     	*name;
@property (strong) UMQueueMulti     *multiQueue;
@property (strong) UMSleeper    	*workSleeper;
@property (assign) BOOL        		debug;



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
- (NSDictionary *)statusByObjectType;

@end
