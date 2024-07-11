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
    UMMUTEX_LOCK(_mutex);
    NSDate *d = [_date copy];
    UMMUTEX_UNLOCK(_mutex);
    return d;
}

- (void)setDate:(NSDate *)d
{
    UMMUTEX_LOCK(_mutex);
    _date = d;
    UMMUTEX_UNLOCK(_mutex);
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
        UMMUTEX_LOCK(_mutex);
        r = [_date timeIntervalSinceDate:since];
        UMMUTEX_UNLOCK(_mutex);
    }
    return r;
}

- (NSTimeInterval)age
{
    NSTimeInterval r;

    UMMUTEX_LOCK(_mutex);
    r = [_date timeIntervalSinceNow];
    UMMUTEX_UNLOCK(_mutex);
    return -r;
}

- (NSTimeInterval)timeIntervalSinceNow
{
    NSTimeInterval r;

    UMMUTEX_LOCK(_mutex);
    r = [_date timeIntervalSinceNow];
    UMMUTEX_UNLOCK(_mutex);
    return fabs(r);
}

- (void)touch
{
    UMMUTEX_LOCK(_mutex);
    _date = [NSDate new];
    UMMUTEX_UNLOCK(_mutex);
}

- (UMAtomicDate *)copyWithZone:(NSZone *)zone
{
    NSDate *d = [self date];
    return [[UMAtomicDate allocWithZone:zone]initWithDate:d];
}

- (NSString *)description
{
    UMMUTEX_LOCK(_mutex);
    NSString *s = _date.description;
    UMMUTEX_UNLOCK(_mutex);
    return s;
}


- (id)proxyForJson
{
    return [_date stringValue];
}

@end

