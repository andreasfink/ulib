//
//  UMQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import "UMQueue.h"
#import "UMMutex.h"

@implementation UMQueue

- (UMQueue *)init
{
    self=[super init];
    if(self)
    {
        _lock = [[UMMutex alloc] initWithName:@"umqueue"];
        _queue = [[NSMutableArray alloc]init];
    }
    return self;
}

- (UMQueue *)initWithoutLock
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
    if(obj)
    {
        [_lock lock];
        [_queue addObject:obj];
        [_lock unlock];
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
        [_lock lock];
        [_queue insertObject:obj atIndex:0];
        [_lock unlock];
    }
}


- (void)appendUnique:(id)obj
{
    if(obj)
    {
        [_lock lock];
        [_queue removeObject:obj]; /* should not be there twice */
        [_queue addObject:obj];
        [_lock unlock];
    }
}


- (void)removeObject:(id)obj
{
    if(obj)
    {
        [_lock lock];
        [_queue removeObject:obj];
        [_lock unlock];
    }
}

- (id)getFirst
{
    id obj = NULL;
    [_lock lock];
    if ([_queue count]>0)
    {
        obj = [_queue objectAtIndex:0];
        [_queue removeObjectAtIndex:0];
    }
    [_lock unlock];
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
    [_lock lock];
    NSInteger i = [_queue count];
    [_lock unlock];
    return i;
}
@end
