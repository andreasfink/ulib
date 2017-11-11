//
//  UMSynchronizedDictionary.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#include <pthread.h>
#import "UMSynchronizedDictionary.h"

#define SYNC_LOCK()

#define SYNC_ENDLOCK

@implementation UMSynchronizedDictionary

@synthesize dict;

- (UMSynchronizedDictionary *)init
{
    self = [super init];
    if(self)
    {
        underlyingDictionary = [[NSMutableDictionary alloc] init];
        mutex = [[UMMutex alloc]init];
    }
    return self;
}

- (UMSynchronizedDictionary *)initWithDictionary:(NSDictionary *)sd
{
    self = [super init];
    if(self)
    {
        underlyingDictionary = [sd mutableCopy];
        mutex = [[UMMutex alloc]init];
    }
    return self;
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

- (NSUInteger)count
{
    [mutex lock];
    NSUInteger cnt  = [underlyingDictionary count];
    [mutex unlock];
    return cnt;
}


- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key
{
    if(key)
    {
        [mutex lock];
        [underlyingDictionary setObject:anObject forKey:key];
        [mutex unlock];
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    id returnValue = NULL;
    if(key)
    {
        [mutex lock];
        returnValue = [underlyingDictionary objectForKey:key];
        [mutex unlock];
    }
    return returnValue;
}

- (NSArray *)allKeys
{
    NSArray *a;
    [mutex lock];
    a = [underlyingDictionary allKeys];
    [mutex unlock];
    return a;
}

- (void)removeObjectForKey:(id)aKey
{
    if(aKey)
    {
        [mutex lock];
        [underlyingDictionary removeObjectForKey:aKey];
        [mutex unlock];
    }
}

- (NSMutableDictionary *)mutableCopy
{
    NSMutableDictionary *d;
    [mutex lock];
    d = [underlyingDictionary mutableCopy];
    [mutex unlock];
    return d;
}

- (UMSynchronizedDictionary *)copyWithZone:(NSZone *)zone
{
    UMSynchronizedDictionary *cpy;
    [mutex lock];
    cpy = [[UMSynchronizedDictionary allocWithZone:zone] initWithDictionary:underlyingDictionary];
    [mutex unlock];
    return cpy;
}
@end
