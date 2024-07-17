//
//  UMAtomicDate.m
//  ulib
//
//  Created by Andreas Fink on 11.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMAtomicDate.h>
#import <ulib/NSDate+ulib.h>

@implementation UMAtomicDate

- (UMAtomicDate *)init
{
    return [self initWithDate:[NSDate date]];
}

- (UMAtomicDate *)initWithDate:(NSDate *)d
{
    self  = [super init];
    if(self)
    {
        _date = d;
        _mutex = [[UMMutex alloc]initWithName:@"atomic-date-mutex"];
    }
    return self;
}

- (NSDate *)date
{
    ummutex_lock(_mutex);
    NSDate *d = [_date copy];
    ummutex_lock(_mutex);
    return d;
}

- (void)setDate:(NSDate *)d
{
    ummutex_lock(_mutex);
    _date = d;
    ummutex_lock(_mutex);
}

- (NSTimeInterval)timeIntervalSinceDate:(NSDate *)since
{
    NSTimeInterval r;
    if(since==NULL)
    {
        r = INFINITY;
    }
    else
    {
        ummutex_lock(_mutex);
        r = [_date timeIntervalSinceDate:since];
        ummutex_lock(_mutex);
    }
    return r;
}

- (NSTimeInterval)age
{
    NSTimeInterval r;

    ummutex_lock(_mutex);
    r = [_date timeIntervalSinceNow];
    ummutex_lock(_mutex);
    return -r;
}

- (NSTimeInterval)timeIntervalSinceNow
{
    NSTimeInterval r;

    ummutex_lock(_mutex);
    r = [_date timeIntervalSinceNow];
    ummutex_lock(_mutex);
    return fabs(r);
}

- (void)touch
{
    ummutex_lock(_mutex);
    _date = [NSDate new];
    ummutex_lock(_mutex);
}

- (UMAtomicDate *)copyWithZone:(NSZone *)zone
{
    NSDate *d = [self date];
    return [[UMAtomicDate allocWithZone:zone]initWithDate:d];
}

- (NSString *)description
{
    ummutex_lock(_mutex);
    NSString *s = _date.description;
    ummutex_lock(_mutex);
    return s;
}


- (id)proxyForJson
{
    return [_date stringValue];
}

@end

