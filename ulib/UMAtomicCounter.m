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
    ummutex_lock(_mutex);
    r = _counter;
    ummutex_unlock(_mutex);
    return r;
}

- (void)setCounter:(int64_t)c
{
    ummutex_lock(_mutex);
    _counter = c;
    ummutex_unlock(_mutex);
}

- (void)increase:(int64_t)c
{
    ummutex_lock(_mutex);
    _counter += c;
    ummutex_unlock(_mutex);
}

- (void)decrease:(int64_t)c
{
    ummutex_lock(_mutex);
    _counter -= c;
    ummutex_unlock(_mutex);
}


- (void)increase
{
    ummutex_lock(_mutex);
    _counter++;
    ummutex_unlock(_mutex);
}

- (void)decrease
{
    ummutex_lock(_mutex);
    _counter--;
    ummutex_unlock(_mutex);
}

- (UMAtomicCounter *)copyWithZone:(NSZone *)zone
{
    int64_t val = [self counter];
    return [[UMAtomicCounter allocWithZone:zone]initWithInteger:val];
}

@end
