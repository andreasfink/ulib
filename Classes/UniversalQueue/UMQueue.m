//
//  UMQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import "UMQueue.h"
#import "UMLock.h"
@implementation UMQueue

- (UMQueue *)init
{
    self=[super init];
    if(self)
    {
        lock = [[UMLock alloc] initNonReentrant];
        queue = [[NSMutableArray alloc]init];
    }
    return self;
}

- (UMQueue *)initWithoutLock
{
    self=[super init];
    if(self)
    {
        lock = NULL;
        queue = [[NSMutableArray alloc]init];
    }
    return self;
}


- (void)append:(id)obj
{
    if(obj)
    {
        [self lock];
        [queue addObject:obj];
        [self unlock];
    }
}


- (void)appendUnique:(id)obj
{
    if(obj)
    {
        [self lock];
        [queue removeObject:obj]; /* should not be there twice */
        [queue addObject:obj];
        [self unlock];
    }
}


- (void)removeObject:(id)obj
{
    if(obj)
    {
        [self lock];
        [queue removeObject:obj];
        [self unlock];
    }
}

- (id)getFirst
{
    id obj = NULL;
    [self lock];
    if ([queue count]>0)
    {
        obj = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
    }
    [self unlock];
    return obj;
}

- (id)getFirstWhileLocked
{
    id obj = NULL;
    if ([queue count]>0)
    {
        obj = [queue objectAtIndex:0];
        [queue removeObjectAtIndex:0];
    }
    return obj;
}

- (void)lock
{
    [lock lock];
}

- (void)unlock
{
    [lock unlock];
}

- (NSInteger)count
{
    [self lock];
    NSInteger i = [queue count];
    [self unlock];
    return i;
}
@end
