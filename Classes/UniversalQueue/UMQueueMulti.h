//
//  UMQueueMulti.h
//  ulib
//
//  Created by Andreas Fink on 30.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMQueueSingle.h"

@class UMThroughputCounter;

@interface UMQueueMulti : UMQueueSingle
{
@private
    NSMutableArray  *_queues;
    NSUInteger      _workInProgress;
    NSUInteger      _currentlyInQueue;
    NSUInteger      _hardLimit;
    UMThroughputCounter *_processingThroughput;
}

@property(readwrite,assign,atomic)  NSUInteger      workInProgress;
@property(readwrite,assign,atomic)  NSUInteger      hardLimit;
@property(readwrite,strong,atomic)  UMThroughputCounter *processingThroughput;

- (void)startWork;
- (void)endWork;

- (UMQueueMulti *)initWithQueueCount:(NSUInteger)index;
- (void)append:(id)obj;
- (void)append:(id)obj forQueueNumber:(NSUInteger)index;
- (void)appendArray:(NSArray *)objects forQueueNumber:(NSUInteger)index;

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
- (NSDictionary *)status;
- (NSDictionary *)statusByObjectType;

@end

