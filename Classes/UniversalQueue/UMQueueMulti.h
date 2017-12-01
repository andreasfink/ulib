//
//  UMQueueMulti.h
//  ulib
//
//  Created by Andreas Fink on 30.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMQueue.h"

@interface UMQueueMulti : UMQueue
{
@private
    NSMutableArray  *queues;
}

- (UMQueueMulti *)initWithQueueCount:(NSUInteger)index;
- (void)append:(id)obj;
- (void)append:(id)obj forQueueNumber:(NSUInteger)index;
- (void)appendUnique:(id)obj;
- (void)appendUnique:(id)obj forQueueNumber:(NSUInteger)index;
- (id)getFirst;
- (id)getFirstWhileLocked;
- (void)insertFirst:(id)obj;
- (void)insertFirst:(id)obj forQueueNumber:(NSUInteger)index;
- (NSInteger)count;
- (NSInteger)countForQueueNumber:(NSUInteger)index;
- (void)removeObject:(id)object;
- (void)removeObject:(id)object forQueueNumber:(NSUInteger)index;;

@end

