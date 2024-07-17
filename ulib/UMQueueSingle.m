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
        ummutex_lock(_queueLock);
        [_queue addObject:obj];
        ummutex_unlock(_queueLock);
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
        ummutex_lock(_queueLock);
        [_queue insertObject:obj atIndex:0];
        ummutex_unlock(_queueLock);
    }
}


- (void)appendUnique:(id)obj
{
    if(obj)
    {
        ummutex_lock(_queueLock);
        [_queue removeObject:obj]; /* should not be there twice */
        [_queue addObject:obj];
        ummutex_unlock(_queueLock);
    }
}


- (void)removeObject:(id)obj
{
    if(obj)
    {
        ummutex_lock(_queueLock);
        [_queue removeObject:obj];
        ummutex_unlock(_queueLock);
    }
}

- (id)getFirst
{
    id obj = NULL;
    ummutex_lock(_queueLock);
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
        [_queue removeObjectAtIndex:0];
    }
    ummutex_unlock(_queueLock);
    return obj;
}

- (id)peekFirst
{
    id obj = NULL;
    ummutex_lock(_queueLock);
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
    }
    ummutex_unlock(_queueLock);
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
    ummutex_lock(_queueLock);
    NSInteger i = [_queue count];
    ummutex_unlock(_queueLock);
    return i;
}

- (void)lock
{
    ummutex_lock(_queueLock);
}

- (void)unlock
{
    ummutex_unlock(_queueLock);
}

- (id)getObjectAtIndex:(NSInteger)i
{
    ummutex_lock(_queueLock);
    id obj = [_queue objectAtIndex:0];
    ummutex_unlock(_queueLock);
    return obj;
}

@end
