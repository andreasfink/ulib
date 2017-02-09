//
//  UMBackgrounderWithQueue.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMBackgrounder.h"

@class UMLock;


/*!
 @class UMBackgrounderWithQueue
 @brief UMBackgrounderWithQueue is an object to run tasks from a single queue.

 The queue can be unique to one background thread or multiple background
 threads can share the same queue.  This is useful if run on multi CPU machines 
 so work items would be stuffed into the queue and picked off the queue.

 To have a proper task queue to throw work objects to it you should use UMTaskQueue
 which instantiates a certain amount of UMBackgrounderWithQueueObject attached
 to a single queue which you then can stuff UMTask objects into to get executed.

*/

@class UMQueue;
@class UMSleeper;

@interface UMBackgrounderWithQueue : UMBackgrounder
{
    UMQueue *queue;
    UMLock  *readLock;
    BOOL sharedQueue;
}

@property(strong)     UMQueue   *queue;
@property(assign)     BOOL      sharedQueue;

- (UMBackgrounderWithQueue *)init;
- (UMBackgrounderWithQueue *)initWithSharedQueue:(UMQueue *)queue
                                            name:(NSString *)name
                                     workSleeper:(UMSleeper *)ws;
@end
