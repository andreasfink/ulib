//
//  UMAtomicCounter.m
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMAtomicCounter.h>

@implementation UMAtomicCounter

- (UMAtomicCounter *)initWithInteger:(int64_t)value
{
    self = [super init];
    if(self)
    {
        _counter = value;
        _mutex = [[UMMutex alloc]initWithName:@"atomic-counter-mutex"];
    }
    return self;
}

- (UMAtomicCounter *)init
{
    return [self initWithInteger:0];
}


- (int64_t)counter
{
    int64_t r;
    UMMUTEX_LOCK(_mutex);
    r = _counter;
    UMMUTEX_UNLOCK(_mutex);
    return r;
}

- (void)setCounter:(int64_t)c
{
    UMMUTEX_LOCK(_mutex);
    _counter = c;
    UMMUTEX_UNLOCK(_mutex);
}

- (void)increase:(int64_t)c
{
    UMMUTEX_LOCK(_mutex);
    _counter += c;
    UMMUTEX_UNLOCK(_mutex);
}

- (void)decrease:(int64_t)c
{
    UMMUTEX_LOCK(_mutex);
    _counter -= c;
    UMMUTEX_UNLOCK(_mutex);
}


- (void)increase
{
    UMMUTEX_LOCK(_mutex);
    _counter++;
    UMMUTEX_UNLOCK(_mutex);
}

- (void)decrease
{
    UMMUTEX_LOCK(_mutex);
    _counter--;
    UMMUTEX_UNLOCK(_mutex);
}

- (UMAtomicCounter *)copyWithZone:(NSZone *)zone
{
    int64_t val = [self counter];
    return [[UMAtomicCounter allocWithZone:zone]initWithInteger:val];
}

@end
