//
//  UMBackgrounderWithQueues.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMBackgrounderWithQueue.h>

@class UMQueueMulti;
@class UMSleeper;

/*!
 @class UMBackgrounderWithQueues
 @brief UMBackgrounderWithQueues is a slightly modified version of UMBackgrounderWithQueue
 which instead of having a single queue, it can have multiple queues in the form
 of a UMQueueMulti. Useful for priority queuing
*/

@interface UMBackgrounderWithQueues : UMBackgrounderWithQueue

{
    UMQueueMulti *_multiQueue; /* array of UMQueueSingle object sorted by priority */
    NSString     *_lastTask;
}

//@property(strong)     NSArray *queues;

- (UMBackgrounderWithQueues *)initWithSharedQueues:(UMQueueMulti *)queues
                                             name:(NSString *)name
                                      workSleeper:(UMSleeper *)ws;
@end
