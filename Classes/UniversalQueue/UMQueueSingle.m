//
//  UMSingleQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import "UMQueueSingle.h"
#import "UMMutex.h"
#import "UMAssert.h"

@implementation UMQueueSingle

- (UMQueueSingle *)init
{
    self=[super init];
    if(self)
    {
        _lock = [[UMMutex alloc] initWithName:@"umqueue"];
        NSMutableArray *q = [[NSMutableArray alloc]init];
        _queue = q;
    }
    return self;
}

- (UMQueueSingle *)initWithoutLock
{
    self=[super init];
    if(self)
    {
        _lock = NULL;
        _queue = [[NSMutableArray alloc]init];
    }
    return self;
}


- (void)append:(id)obj
{
    UMAssert(_queue!=NULL,@"Queue is not set");
    if(obj)
    {
        UMMUTEX_LOCK(_lock);
        [_queue addObject:obj];
        UMMUTEX_UNLOCK(_lock);
    }
}

- (void)appendUnlocked:(id)obj
{
    if(obj)
    {
        [_queue addObject:obj];
    }
}

- (void)insertFirst:(id)obj
{
    if(obj)
    {
        UMMUTEX_LOCK(_lock);
        [_queue insertObject:obj atIndex:0];
        UMMUTEX_UNLOCK(_lock);
    }
}


- (void)appendUnique:(id)obj
{
    if(obj)
    {
        UMMUTEX_LOCK(_lock);
        [_queue removeObject:obj]; /* should not be there twice */
        [_queue addObject:obj];
        UMMUTEX_UNLOCK(_lock);
    }
}


- (void)removeObject:(id)obj
{
    if(obj)
    {
        UMMUTEX_LOCK(_lock);
        [_queue removeObject:obj];
        UMMUTEX_UNLOCK(_lock);
    }
}

- (id)getFirst
{
    id obj = NULL;
    UMMUTEX_LOCK(_lock);
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
        [_queue removeObjectAtIndex:0];
    }
    UMMUTEX_UNLOCK(_lock);
    return obj;
}

- (id)peekFirst
{
    id obj = NULL;
    UMMUTEX_LOCK(_lock);
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
    }
    UMMUTEX_UNLOCK(_lock);
    return obj;
}

- (id)getFirstWhileLocked
{
    id obj = NULL;
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
        [_queue removeObjectAtIndex:0];
    }
    return obj;
}


- (NSInteger)count
{
    UMMUTEX_LOCK(_lock);
    NSInteger i = [_queue count];
    UMMUTEX_UNLOCK(_lock);
    return i;
}

- (void)lock
{
    UMMUTEX_LOCK(_lock);
}

- (void)unlock
{
    UMMUTEX_UNLOCK(_lock);
}

- (id)getObjectAtIndex:(NSInteger)i
{
    UMMUTEX_LOCK(_lock);
    id obj = [_queue objectAtIndex:0];
    UMMUTEX_UNLOCK(_lock);
    return obj;
}

@end
