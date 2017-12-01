//
//  UMQueueMulti.m
//  ulib
//
//  Created by Andreas Fink on 30.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMQueueMulti.h"
#import "UMMutex.h"

@implementation UMQueueMulti


- (UMQueueMulti *)init
{
    return [self initWithQueueCount:1];
}


- (UMQueueMulti *)initWithQueueCount:(NSUInteger)count
{
    self=[super init];
    if(self)
    {
        _lock = [[UMMutex alloc] init];
        queue = NULL;
        queues = [[NSMutableArray alloc]init];
        for(NSUInteger i=0;i<count;i++)
        {
            [queues addObject:[[NSMutableArray alloc]init]];
        }
    }
    return self;
}

- (void)append:(id)obj
{
    [self append:obj forQueueNumber:0];
}

- (void)append:(id)obj forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        [_lock lock];
        NSMutableArray *subqueue = queues[index];
        [subqueue addObject:obj];
        [_lock unlock];
    }
}

- (void)appendUnlocked:(id)obj
{
    [self appendUnlocked:obj forQueueNumber:0];
}

- (void)appendUnlocked:(id)obj forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        NSMutableArray *subqueue = queues[index];
        [subqueue addObject:obj];
    }
}

- (void)insertFirst:(id)obj
{
    [self insertFirst:obj forQueueNumber:0];
}

- (void)insertFirst:(id)obj forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        [_lock lock];
        NSMutableArray *subqueue = queues[index];
        [subqueue insertObject:obj atIndex:0];
        [_lock unlock];
    }
}

- (void)appendUnique:(id)obj
{
    return [self appendUnique:obj  forQueueNumber:0];
}

- (void)appendUnique:(id)obj  forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        [_lock lock];
        NSMutableArray *subqueue = queues[index];
        [subqueue removeObject:obj]; /* should not be there twice */
        [subqueue addObject:obj];
        [_lock unlock];
    }
}


- (void)removeObject:(id)obj
{
    [self removeObject:obj forQueueNumber:0];
}

- (void)removeObject:(id)obj forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        [_lock lock];
        NSMutableArray *subqueue = queues[index];
        [subqueue removeObject:obj];
        [_lock unlock];
    }
}

- (id)getFirst
{
    id obj = NULL;
    [_lock lock];
    NSUInteger cnt = queues.count;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = queues[index];
        if ([subqueue count]>0)
        {
            obj = [subqueue objectAtIndex:0];
            [subqueue removeObjectAtIndex:0];
            break;
        }
    }
    [_lock unlock];
    return obj;
}

- (id)getFirstWhileLocked
{
    id obj = NULL;
    [_lock lock];
    NSUInteger cnt = queues.count;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = queues[index];
        if ([subqueue count]>0)
        {
            obj = [subqueue objectAtIndex:0];
            [subqueue removeObjectAtIndex:0];
            break;
        }
    }
    [_lock unlock];
    return obj;
}


- (NSInteger)count
{
    [_lock lock];
    NSUInteger cnt = queues.count;
    NSUInteger total = 0;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = queues[index];
        total += subqueue.count;
    }
    [_lock unlock];
    return total;
}

- (NSInteger)countForQueueNumber:(NSUInteger)index
{
    [_lock lock];
    NSMutableArray *subqueue = queues[index];
    NSInteger i = [subqueue count];
    [_lock unlock];
    return i;
}

@end


