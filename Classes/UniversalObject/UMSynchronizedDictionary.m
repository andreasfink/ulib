//
//  UMSynchronizedDictionary.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#include <pthread.h>
#import "UMSynchronizedDictionary.h"
#import "UMJsonWriter.h"

#define SYNC_LOCK()

#define SYNC_ENDLOCK

@implementation UMSynchronizedDictionary

@synthesize dict;

- (UMSynchronizedDictionary *)init
{
    self = [super init];
    if(self)
    {
        _underlyingDictionary = [[NSMutableDictionary alloc] init];
        _lock = [[UMMutex alloc]initWithName:@"synchronized-dictionary"];
    }
    return self;
}

- (void)flush
{
    [_lock lock];
    _underlyingDictionary = [[NSMutableDictionary alloc] init];
    [_lock unlock];
}

- (UMSynchronizedDictionary *)initWithDictionary:(NSDictionary *)sd
{
    self = [super init];
    if(self)
    {
        _underlyingDictionary = [sd mutableCopy];
        _lock = [[UMMutex alloc]initWithName:@"synchronized-dictionary"];
    }
    return self;
}

- (void)lock
{
    [_lock lock];
}

- (void)unlock
{
    [_lock unlock];
}


+ (instancetype)synchronizedDictionary
{
    UMSynchronizedDictionary *sd = [[UMSynchronizedDictionary alloc]init];
    return sd;
}

+ (instancetype)synchronizedDictionaryWithDictionary:(NSDictionary *)xd
{
    return [[UMSynchronizedDictionary alloc]initWithDictionary:xd];
}

- (NSDictionary *)dictionaryCopy
{
    return [_underlyingDictionary copy];
}

- (NSUInteger)count
{
    [_lock lock];
    NSUInteger cnt  = [_underlyingDictionary count];
    [_lock unlock];
    return cnt;
}


- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key
{
    if(key)
    {
        [_lock lock];
        [_underlyingDictionary setObject:anObject forKey:key];
        [_lock unlock];
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    id returnValue = NULL;
    if(key)
    {
        [_lock lock];
        returnValue = [_underlyingDictionary objectForKey:key];
        [_lock unlock];
    }
    return returnValue;
}

- (NSArray *)allKeys
{
    NSArray *a;
    [_lock lock];
    a = [_underlyingDictionary allKeys];
    [_lock unlock];
    return a;
}

- (void)removeObjectForKey:(id)aKey
{
    if(aKey)
    {
        [_lock lock];
        [_underlyingDictionary removeObjectForKey:aKey];
        [_lock unlock];
    }
}

- (NSMutableDictionary *)mutableCopy
{
    NSMutableDictionary *d;
    [_lock lock];
    d = [_underlyingDictionary mutableCopy];
    [_lock unlock];
    return d;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    UMSynchronizedDictionary *cpy;
    [_lock lock];
    cpy = [[UMSynchronizedDictionary allocWithZone:zone] initWithDictionary:_underlyingDictionary];
    [_lock unlock];
    return cpy;
}

- (NSString *)jsonString;
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    NSString *json = [writer stringWithObject:_underlyingDictionary];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

- (NSString *)jsonCompactString;
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = NO;
    NSString *json = [writer stringWithObject:_underlyingDictionary];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

@end
