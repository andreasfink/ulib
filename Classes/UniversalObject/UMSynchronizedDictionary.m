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
            _dictionaryLock = [[UMMutex alloc]initWithName:@"synchronized-dictionary"];
        }
        return self;
    }
}

- (void)flush
{
    UMMUTEX_LOCK(_dictionaryLock);
    _underlyingDictionary = [[NSMutableDictionary alloc] init];
    UMMUTEX_UNLOCK(_dictionaryLock);
}

- (UMSynchronizedDictionary *)initWithDictionary:(NSDictionary *)sd
{
    @autoreleasepool
    {
        self = [super init];
        if(self)
        {
            _underlyingDictionary = [sd mutableCopy];
            _dictionaryLock = [[UMMutex alloc]initWithName:@"synchronized-dictionary"];
        }
        return self;
    }
}

- (void)lock
{
    UMMUTEX_LOCK(_dictionaryLock);
}

- (void)unlock
{
    UMMUTEX_UNLOCK(_dictionaryLock);
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
    UMMUTEX_LOCK(_dictionaryLock);
    NSUInteger cnt  = [_underlyingDictionary count];
    UMMUTEX_UNLOCK(_dictionaryLock);
    return cnt;
}


- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key
{
    if((key) &&(anObject))
    {
        UMMUTEX_LOCK(_dictionaryLock);
        [_underlyingDictionary setObject:anObject forKey:key];
        UMMUTEX_UNLOCK(_dictionaryLock);
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    id returnValue = NULL;
    if(key)
    {
        UMMUTEX_LOCK(_dictionaryLock);
        returnValue = [_underlyingDictionary objectForKey:key];
        UMMUTEX_UNLOCK(_dictionaryLock);
    }
    return returnValue;
}

- (NSArray *)allKeys
{
    NSArray *a;
    UMMUTEX_LOCK(_dictionaryLock);
    a = [_underlyingDictionary allKeys];
    UMMUTEX_UNLOCK(_dictionaryLock);
    return a;
}

- (void)removeObjectForKey:(id)aKey
{
    if(aKey)
    {
        UMMUTEX_LOCK(_dictionaryLock);
        [_underlyingDictionary removeObjectForKey:aKey];
        UMMUTEX_UNLOCK(_dictionaryLock);
    }
}

- (NSMutableDictionary *)mutableCopy
{
    NSMutableDictionary *d;
    UMMUTEX_LOCK(_dictionaryLock);
    d = [_underlyingDictionary mutableCopy];
    UMMUTEX_UNLOCK(_dictionaryLock);
    return d;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    UMSynchronizedDictionary *cpy;
    UMMUTEX_LOCK(_dictionaryLock);
    cpy = [[UMSynchronizedDictionary allocWithZone:zone] initWithDictionary:_underlyingDictionary];
    UMMUTEX_UNLOCK(_dictionaryLock);
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
