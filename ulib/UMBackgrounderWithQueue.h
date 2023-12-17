//
//  UMBackgrounderWithQueue.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMBackgrounder.h>

/*!
 @class UMBackgrounderWithQueue
 @brief UMBackgrounderWithQueue is an object to run tasks from a single queue.

 The queue can be unique to one background thread or multiple background
 threads can share the same queue.  This is useful if run on multi CPU machines 
 so work items would be stuffed into the queue and picked off the queue.

 To have a proper task queue to throw work objects to it you should use UMTaskQueue
 which instantiates a certain amount of UMBackgrounderWithQueueObject attached
 to a single queue which you then can stuff UMTaskQueueTask objects into to get executed.

*/

@class UMQueueSingle;
@class UMSleeper;

@interface UMBackgrounderWithQueue : UMBackgrounder
{
    UMQueueSingle *_queue;
    BOOL    _sharedQueue;
}

@property(strong)     UMQueueSingle   *queue;
@property(assign)     BOOL      sharedQueue;

- (UMBackgrounderWithQueue *)initWithName:(NSString *)n;
- (UMBackgrounderWithQueue *)initWithSharedQueue:(UMQueueSingle *)queue
                                            name:(NSString *)name
                                     workSleeper:(UMSleeper *)ws;

@end
