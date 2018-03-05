//
//  UMAtomicCounter.m
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMAtomicCounter.h"

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
    [_mutex lock];
    r = _counter;
    [_mutex unlock];
    return r;
}

- (void)setCounter:(int64_t)c
{
    [_mutex lock];
    _counter = c;
    [_mutex unlock];
}

- (void)increase:(int64_t)c
{
    [_mutex lock];
    _counter += c;
    [_mutex unlock];
}

- (void)decrease:(int64_t)c
{
    [_mutex lock];
    _counter -= c;
    [_mutex unlock];
}


- (void)increase
{
    [_mutex lock];
    _counter++;
    [_mutex unlock];
}

- (void)decrease
{
    [_mutex lock];
    _counter--;
    [_mutex unlock];
}

- (UMAtomicCounter *)copyWithZone:(NSZone *)zone
{
    int64_t val = [self counter];
    return [[UMAtomicCounter allocWithZone:zone]initWithInteger:val];
}

@end
