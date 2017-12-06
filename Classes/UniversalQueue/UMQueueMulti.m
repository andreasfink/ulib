//
//  UMQueueMulti.m
//  ulib
//
//  Created by Andreas Fink on 30.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMQueueMulti.h"
#import "UMMutex.h"
#import "UMThroughputCounter.h"
#import "UMTask.h"

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
        _currentlyInQueue = 0;
        _hardLimit = 0;
        for(NSUInteger i=0;i<count;i++)
        {
            [queues addObject:[[NSMutableArray alloc]init]];
        }
        _processingThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
    }
    return self;
}

- (void)startWork
{
    [_lock lock];
    _workInProgress++;
    [_lock unlock];
    [_processingThroughput increase];
}

- (void)endWork
{
    [_lock lock];
    _workInProgress--;
    [_lock unlock];
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
        _currentlyInQueue++;
        if((_hardLimit > 0) && (_currentlyInQueue > _hardLimit))
        {
            _currentlyInQueue--;
            [_lock unlock];
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
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
        
        _currentlyInQueue++;
        if((_hardLimit > 0) && (_currentlyInQueue > _hardLimit))
        {
            _currentlyInQueue--;
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
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
        _currentlyInQueue++;
        if((_hardLimit > 0) && (_currentlyInQueue > _hardLimit))
        {
            _currentlyInQueue--;
            [_lock unlock];
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
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
        NSInteger idx = [subqueue indexOfObject:obj];
        if(idx != NSNotFound)
        {
            [subqueue removeObjectAtIndex:idx]; /* should not be there twice */
            _currentlyInQueue--;
        }
        
        _currentlyInQueue++;
        if((_hardLimit > 0) && (_currentlyInQueue > _hardLimit))
        {
            _currentlyInQueue--;
            [_lock unlock];
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
        [subqueue addObject:obj];
        [_lock unlock];
    }
}


- (void)removeObject:(id)obj
{
    NSUInteger count = queues.count;
    for(NSUInteger i=0;i<count;i++)
    {
        [self removeObject:obj forQueueNumber:i];
    }
}

- (void)removeObject:(id)obj forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        [_lock lock];
        NSMutableArray *subqueue = queues[index];
        NSInteger idx = [subqueue indexOfObject:obj];
        if(idx != NSNotFound)
        {
            _currentlyInQueue--;
            [subqueue removeObjectAtIndex:idx];
        }
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
        if (subqueue.count>0)
        {
            obj = [subqueue objectAtIndex:0];
            [subqueue removeObjectAtIndex:0];
            _currentlyInQueue--;
            break;
        }
    }
    [_lock unlock];
    return obj;
}

- (id)getFirstWhileLocked
{
    id obj = NULL;
    NSUInteger cnt = queues.count;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = queues[index];
        if (subqueue.count>0)
        {
            obj = [subqueue objectAtIndex:0];
            [subqueue removeObjectAtIndex:0];
            _currentlyInQueue--;
            break;
        }
    }
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

- (NSDictionary *)status
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [_lock lock];
    NSUInteger cnt = queues.count;
    NSUInteger total = 0;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = queues[index];
        dict[@(index)] = @(subqueue.count);
        total += subqueue.count;
    }
    [_lock unlock];
    dict[@"total"] = @(total);
    return dict;
}

- (NSDictionary *)subQueueStatus:(NSUInteger)index
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    NSMutableArray *subqueue = queues[index];
    NSUInteger n = subqueue.count;
    for(NSUInteger i=0;i<n;i++)
    {
        NSString *name;
        id obj = subqueue[i];
        if([obj isKindOfClass:[UMTask class]])
        {
            UMTask *task = (UMTask *)obj;
            name = task.name;
        }
        else
        {
            name = [[obj class]description];
        }
        NSNumber *entry = dict[name];
        if(entry)
        {
            entry = @(entry.integerValue +1);
        }
        else
        {
            entry = @(1);
        }
        dict[name] = entry;
    }
    return dict;
}

- (NSDictionary *)statusByObjectType
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [_lock lock];
    NSUInteger cnt = queues.count;
    for(NSUInteger index=0;index<cnt;index++)
    {
        dict[@(index)] = [self subQueueStatus:index];
    }
    [_lock unlock];
    return dict;
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


