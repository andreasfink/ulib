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
    [_mutex lock];
    NSDate *d = [_date copy];
    [_mutex unlock];
    return d;
}

- (void)setDate:(NSDate *)d
{
    [_mutex lock];
    _date = d;
    [_mutex unlock];
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
        [_mutex lock];
        r = [_date timeIntervalSinceDate:since];
        [_mutex unlock];
    }
    return r;
}

- (NSTimeInterval)age
{
    NSTimeInterval r;

    [_mutex lock];
    r = [_date timeIntervalSinceNow];
    [_mutex unlock];
    return -r;
}

- (NSTimeInterval)timeIntervalSinceNow
{
    NSTimeInterval r;

    [_mutex lock];
    r = [_date timeIntervalSinceNow];
    [_mutex unlock];
    return fabs(r);
}

- (void)touch
{
    [_mutex lock];
    _date = [NSDate new];
    [_mutex unlock];
}

- (UMAtomicDate *)copyWithZone:(NSZone *)zone
{
    NSDate *d = [self date];
    return [[UMAtomicDate allocWithZone:zone]initWithDate:d];
}

- (NSString *)description
{
    [_mutex lock];
    NSString *s = _date.description;
    [_mutex unlock];
    return s;
}


- (id)proxyForJson
{
    return [_date stringValue];
}

@end

