//
//  UMBackgrounderWithQueues.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMBackgrounderWithQueue.h"

@class UMQueue;
@class UMSleeper;

/*!
 @class UMBackgrounderWithQueues
 @brief UMBackgrounderWithQueues is a slightly modified version of UMBackgrounderWithQueue
 which instead of having a single queue, it can have multiple queues. Useful for priority queuing
*/

@interface UMBackgrounderWithQueues : UMBackgrounderWithQueue

{
    NSArray *_queues; /* array of UMQueue object sorted by priority */
    NSString *_lastTask;
}

@property(strong)     NSArray *queues;

- (UMBackgrounderWithQueues *)initWithSharedQueues:(NSArray *)queues
                                             name:(NSString *)name
                                      workSleeper:(UMSleeper *)ws;
@end
