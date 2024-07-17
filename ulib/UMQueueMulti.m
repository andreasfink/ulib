//
//  UMQueueMulti.m
//  ulib
//
//  Created by Andreas Fink on 30.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMQueueMulti.h>
#import <ulib/UMMutex.h>
#import <ulib/UMThroughputCounter.h>
#import <ulib/UMTaskQueueTask.h>

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
        _queueLock = [[UMMutex alloc] initWithName:@"umqueue-multi"];
        _queue = NULL;
        _queues = [[NSMutableArray alloc]init];
        _currentlyInQueue = 0;
        _hardLimit = 0;
        for(NSUInteger i=0;i<count;i++)
        {
            [_queues addObject:[[NSMutableArray alloc]init]];
        }
        _processingThroughput = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
    }
    return self;
}

- (void)startWork
{
    ummutex_lock(_queueLock);
    _workInProgress++;
    ummutex_unlock(_queueLock);
    [_processingThroughput increase];
}

- (void)endWork
{
    ummutex_lock(_queueLock);
    _workInProgress--;
    ummutex_unlock(_queueLock);
}

- (void)append:(id)obj
{
    [self append:obj forQueueNumber:0];
}

- (void)append:(id)obj forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        BOOL limitReached = NO;
        ummutex_lock(_queueLock);
        _currentlyInQueue++;
        if((_hardLimit > 0) && (_currentlyInQueue > _hardLimit))
        {
            _currentlyInQueue--;
            limitReached = YES;
        }
        NSMutableArray *subqueue = _queues[index];
        [subqueue addObject:obj];
        ummutex_unlock(_queueLock);
        if(limitReached)
        {
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
    }
}

- (void)appendArray:(NSArray *)objects forQueueNumber:(NSUInteger)index
{
    if(objects.count > 0)
    {
        BOOL limitReached = NO;
        ummutex_lock(_queueLock);
        _currentlyInQueue += objects.count;
        if((_hardLimit > 0) && (_currentlyInQueue > _hardLimit))
        {
            _currentlyInQueue -= objects.count;
            limitReached = YES;
        }
        if(limitReached == NO)
        {
            NSMutableArray *subqueue = _queues[index];
            [subqueue addObjectsFromArray:objects];
        }
        ummutex_unlock(_queueLock);
        if(limitReached)
        {
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
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
        NSMutableArray *subqueue = _queues[index];
        
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
        ummutex_lock(_queueLock);
        _currentlyInQueue++;
        if((_hardLimit > 0) && (_currentlyInQueue > _hardLimit))
        {
            _currentlyInQueue--;
            ummutex_unlock(_queueLock);
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
        NSMutableArray *subqueue = _queues[index];
        [subqueue insertObject:obj atIndex:0];
        ummutex_unlock(_queueLock);
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
        ummutex_lock(_queueLock);
        NSMutableArray *subqueue = _queues[index];
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
            ummutex_unlock(_queueLock);
            @throw([NSException exceptionWithName:@"QUEUE-LIMIT-REACHED" reason:NULL userInfo:NULL]);
        }
        [subqueue addObject:obj];
        ummutex_unlock(_queueLock);
    }
}


- (void)removeObject:(id)obj
{
    NSUInteger count = _queues.count;
    for(NSUInteger i=0;i<count;i++)
    {
        [self removeObject:obj forQueueNumber:i];
    }
}

- (void)removeObject:(id)obj forQueueNumber:(NSUInteger)index
{
    if(obj)
    {
        ummutex_lock(_queueLock);
        NSMutableArray *subqueue = _queues[index];
        NSInteger idx = [subqueue indexOfObject:obj];
        if(idx != NSNotFound)
        {
            _currentlyInQueue--;
            [subqueue removeObjectAtIndex:idx];
        }
        ummutex_unlock(_queueLock);
    }
}

- (id)getFirst
{
    id obj = NULL;
    ummutex_lock(_queueLock);
    NSUInteger cnt = _queues.count;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = _queues[index];
        if (subqueue.count>0)
        {
            obj = [subqueue objectAtIndex:0];
            _currentlyInQueue--;
            [subqueue removeObjectAtIndex:0];
            break;
        }
    }
    ummutex_unlock(_queueLock);
    return obj;
}

- (id)getFirstWhileLocked
{
    id obj = NULL;
    NSUInteger cnt = _queues.count;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = _queues[index];
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
    ummutex_lock(_queueLock);
    NSUInteger cnt = _queues.count;
    NSUInteger total = 0;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = _queues[index];
        total += subqueue.count;
    }
    ummutex_unlock(_queueLock);
    return total;
}

- (NSDictionary *)status
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    ummutex_lock(_queueLock);
    NSUInteger cnt = _queues.count;
    NSUInteger total = 0;
    for(NSUInteger index=0;index<cnt;index++)
    {
        NSMutableArray *subqueue = _queues[index];
        dict[@(index)] = @(subqueue.count);
        total += subqueue.count;
    }
    ummutex_unlock(_queueLock);
    dict[@"total"] = @(total);
    return dict;
}

- (NSDictionary *)subQueueStatus:(NSUInteger)index
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    NSMutableArray *subqueue = _queues[index];
    NSUInteger n = subqueue.count;
    for(NSUInteger i=0;i<n;i++)
    {
        NSString *name;
        id obj = subqueue[i];
        if([obj isKindOfClass:[UMTaskQueueTask class]])
        {
            UMTaskQueueTask *task = (UMTaskQueueTask *)obj;
            name = task.name;
        }
        else
        {
            name = [[obj class]description];
        }
        NSNumber *entry = dict[name];
        if(entry!=NULL)
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
    ummutex_lock(_queueLock);
    NSUInteger cnt = _queues.count;
    for(NSUInteger index=0;index<cnt;index++)
    {
        dict[@(index)] = [self subQueueStatus:index];
    }
    ummutex_unlock(_queueLock);
    return dict;
}


- (NSInteger)countForQueueNumber:(NSUInteger)index
{
    ummutex_lock(_queueLock);
    NSMutableArray *subqueue = _queues[index];
    NSInteger i = [subqueue count];
    ummutex_unlock(_queueLock);
    return i;
}

@end


