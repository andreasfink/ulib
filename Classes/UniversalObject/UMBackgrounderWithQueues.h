//
//  UMBackgrounderWithQueues.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMBackgrounderWithQueue.h"

@class UMQueue;
@class UMSleeper;

@interface UMBackgrounderWithQueues : UMBackgrounderWithQueue

{
    NSArray *queues; /* array of UMQueue object sorted by priority */
}

@property(strong)     NSArray *queues;

- (UMBackgrounderWithQueues *)init;
- (UMBackgrounderWithQueues *)initWithSharedQueues:(NSArray *)queues
                                             name:(NSString *)name
                                      workSleeper:(UMSleeper *)ws;
@end
