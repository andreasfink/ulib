//
//  UMPool.m
//  ulib
//
//  Created by Andreas Fink on 24.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMPool.h>

@implementation UMPool

- (UMPool *)init
{
    self=[super init];
    if(self)
    {
        for(int i=0;i<UMPOOL_QUEUES_COUNT;i++)
        {
            _poolLock[i] = [[UMMutex alloc] initWithName:@"umpool"];
            _queues[i] = [[NSMutableArray alloc]init];
            _rotary = 0;
        }
    }
    return self;
}

- (void)append:(id)obj
{
    if(obj)
    {
        _rotary = ++_rotary % UMPOOL_QUEUES_COUNT;
        int start = _rotary;
        int end = start + UMPOOL_QUEUES_COUNT;
        int index;
        for(index=start;index<end;index++)
        {
            int i = index % UMPOOL_QUEUES_COUNT;
            int result;
            UMMUTEX_TRYLOCK(_poolLock[i], 1, 1, result);
            if(result)
            {
               [_queues[i] addObject:obj];
               UMMUTEX_UNLOCK(_poolLock[i]);
               return;
            }
        }
        /* we only get here if all locks are established */
        /* now we have no other choice than to do a waitlock */
        int i = ++index % UMPOOL_QUEUES_COUNT;
        UMMUTEX_LOCK(_poolLock[i]);
        [_queues[i] addObject:obj];
        UMMUTEX_UNLOCK(_poolLock[i]);
    }
}

- (void)removeObject:(id)obj
{
    if(obj)
    {
        int start = _rotary;
        int end = start + UMPOOL_QUEUES_COUNT;
        for(int index=start;index<end;index++)
        {
            int i = index % UMPOOL_QUEUES_COUNT;
            UMMUTEX_LOCK(_poolLock[i]);
            [_queues[i] removeObject:obj];
            UMMUTEX_UNLOCK(_poolLock[i]);
        }
        _rotary = ++_rotary % UMPOOL_QUEUES_COUNT;
    }
}
/*
- (void)removeObjectIdenticalTo:(id)obj
{
    if(obj)
    {
        int start = _rotary;
        int end = start + UMPOOL_QUEUES_COUNT;
        for(int index=start;index<end;index++)
        {
            int i = index % UMPOOL_QUEUES_COUNT;
            UMMUTEX_LOCK(_poolLock[i]);
            [_queues[i] removeObjectIdenticalTo:obj];
            UMMUTEX_UNLOCK(_poolLock[i]);
        }
        _rotary = ++_rotary % UMPOOL_QUEUES_COUNT;
    }
}
*/
- (id)getAny
{
    id obj = NULL;
    int start = _rotary;
    int end = start + UMPOOL_QUEUES_COUNT;
    for(int index=start;index<end;index++)
    {
        int i = index % UMPOOL_QUEUES_COUNT;
        UMMUTEX_LOCK(_poolLock[i]);
        if ([_queues[i] count]>0)
        {
            obj = [_queues[i] objectAtIndex:0];
            [_queues[i] removeObjectAtIndex:0];
        }
        UMMUTEX_UNLOCK(_poolLock[i]);
        if(obj)
        {
            break;
        }
    }
    _rotary = ++_rotary % UMPOOL_QUEUES_COUNT;
    return obj;
}


- (NSInteger)count
{
    NSInteger cnt = 0;
    int start = _rotary;
    int end = start + UMPOOL_QUEUES_COUNT;
    for(int index=start;index<end;index++)
    {
        int i = index % UMPOOL_QUEUES_COUNT;
        UMMUTEX_LOCK(_poolLock[i]);
        cnt= cnt + [_queues[i] count];
        UMMUTEX_UNLOCK(_poolLock[i]);
    }
    _rotary = ++_rotary % UMPOOL_QUEUES_COUNT;
    return cnt;
}

@end
