//
//  UMSingleQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMQueueSingle.h>
#import <ulib/UMMutex.h>
#import <ulib/UMAssert.h>

@implementation UMQueueSingle

- (UMQueueSingle *)init
{
    self=[super init];
    if(self)
    {
        _queueLock = [[UMMutex alloc] initWithName:@"umqueue"];
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
        _queueLock = NULL;
        _queue = [[NSMutableArray alloc]init];
    }
    return self;
}


- (void)append:(id)obj
{
    UMAssert(_queue!=NULL,@"Queue is not set");
    if(obj)
    {
        UMMUTEX_LOCK(_queueLock);
        [_queue addObject:obj];
        UMMUTEX_UNLOCK(_queueLock);
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
        UMMUTEX_LOCK(_queueLock);
        [_queue insertObject:obj atIndex:0];
        UMMUTEX_UNLOCK(_queueLock);
    }
}


- (void)appendUnique:(id)obj
{
    if(obj)
    {
        UMMUTEX_LOCK(_queueLock);
        [_queue removeObject:obj]; /* should not be there twice */
        [_queue addObject:obj];
        UMMUTEX_UNLOCK(_queueLock);
    }
}


- (void)removeObject:(id)obj
{
    if(obj)
    {
        UMMUTEX_LOCK(_queueLock);
        [_queue removeObject:obj];
        UMMUTEX_UNLOCK(_queueLock);
    }
}

- (id)getFirst
{
    id obj = NULL;
    UMMUTEX_LOCK(_queueLock);
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
        [_queue removeObjectAtIndex:0];
    }
    UMMUTEX_UNLOCK(_queueLock);
    return obj;
}

- (id)peekFirst
{
    id obj = NULL;
    UMMUTEX_LOCK(_queueLock);
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
    }
    UMMUTEX_UNLOCK(_queueLock);
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
    UMMUTEX_LOCK(_queueLock);
    NSInteger i = [_queue count];
    UMMUTEX_UNLOCK(_queueLock);
    return i;
}

- (void)lock
{
    UMMUTEX_LOCK(_queueLock);
}

- (void)unlock
{
    UMMUTEX_UNLOCK(_queueLock);
}

- (id)getObjectAtIndex:(NSInteger)i
{
    UMMUTEX_LOCK(_queueLock);
    id obj = [_queue objectAtIndex:0];
    UMMUTEX_UNLOCK(_queueLock);
    return obj;
}

@end
