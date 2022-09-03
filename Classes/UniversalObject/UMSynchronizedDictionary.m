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
    @autoreleasepool
    {
        self = [super init];
        if(self)
        {
            _underlyingDictionary = [[NSMutableDictionary alloc] init];
            _lock = [[UMMutex alloc]initWithName:@"synchronized-dictionary"];
        }
        return self;
    }
}

- (void)flush
{
    UMMUTEX_LOCK(_lock);
    _underlyingDictionary = [[NSMutableDictionary alloc] init];
    UMMUTEX_UNLOCK(_lock);
}

- (UMSynchronizedDictionary *)initWithDictionary:(NSDictionary *)sd
{
    @autoreleasepool
    {
        self = [super init];
        if(self)
        {
            _underlyingDictionary = [sd mutableCopy];
            _lock = [[UMMutex alloc]initWithName:@"synchronized-dictionary"];
        }
        return self;
    }
}

- (void)lock
{
    UMMUTEX_LOCK(_lock);
}

- (void)unlock
{
    UMMUTEX_UNLOCK(_lock);
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
    UMMUTEX_LOCK(_lock);
    NSUInteger cnt  = [_underlyingDictionary count];
    UMMUTEX_UNLOCK(_lock);
    return cnt;
}


- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key
{
    if((key) &&(anObject))
    {
        UMMUTEX_LOCK(_lock);
        [_underlyingDictionary setObject:anObject forKey:key];
        UMMUTEX_UNLOCK(_lock);
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    id returnValue = NULL;
    if(key)
    {
        UMMUTEX_LOCK(_lock);
        returnValue = [_underlyingDictionary objectForKey:key];
        UMMUTEX_UNLOCK(_lock);
    }
    return returnValue;
}

- (NSArray *)allKeys
{
    NSArray *a;
    UMMUTEX_LOCK(_lock);
    a = [_underlyingDictionary allKeys];
    UMMUTEX_UNLOCK(_lock);
    return a;
}

- (void)removeObjectForKey:(id)aKey
{
    if(aKey)
    {
        UMMUTEX_LOCK(_lock);
        [_underlyingDictionary removeObjectForKey:aKey];
        UMMUTEX_UNLOCK(_lock);
    }
}

- (NSMutableDictionary *)mutableCopy
{
    NSMutableDictionary *d;
    UMMUTEX_LOCK(_lock);
    d = [_underlyingDictionary mutableCopy];
    UMMUTEX_UNLOCK(_lock);
    return d;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    UMSynchronizedDictionary *cpy;
    UMMUTEX_LOCK(_lock);
    cpy = [[UMSynchronizedDictionary allocWithZone:zone] initWithDictionary:_underlyingDictionary];
    UMMUTEX_UNLOCK(_lock);
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
