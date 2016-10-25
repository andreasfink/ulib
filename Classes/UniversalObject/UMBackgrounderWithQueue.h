//
//  UMBackgrounderWithQueue.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMBackgrounder.h"

@class UMLock;

/*
 
 UMBackgrounderWithQueue.h is an object to run tasks from a queue.
 The queue can be unique to one background thread or multipel background threads can share the same queue.
 This is useful if run on multi CPU machines so work items would be stuffed into the queue and picked off the queue.
 
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
