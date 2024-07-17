//
//  UMSynchronizedDictionary.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#include <pthread.h>
#import <ulib/UMSynchronizedDictionary.h>
#import <ulib/UMJsonWriter.h>

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
    ummutex_lock(_dictionaryLock);
    _underlyingDictionary = [[NSMutableDictionary alloc] init];
    ummutex_unlock(_dictionaryLock);
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
    ummutex_lock(_dictionaryLock);
}

- (void)unlock
{
    ummutex_unlock(_dictionaryLock);
}

- (void)lockDictionary
{
    ummutex_lock(_dictionaryLock);
}

- (void)unlockDictionary
{
    ummutex_unlock(_dictionaryLock);
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
    ummutex_lock(_dictionaryLock);
    NSUInteger cnt  = [_underlyingDictionary count];
    ummutex_unlock(_dictionaryLock);
    return cnt;
}


- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key
{
    if((key) &&(anObject))
    {
        ummutex_lock(_dictionaryLock);
        [_underlyingDictionary setObject:anObject forKey:key];
        ummutex_unlock(_dictionaryLock);
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    id returnValue = NULL;
    if(key)
    {
        ummutex_lock(_dictionaryLock);
        returnValue = [_underlyingDictionary objectForKey:key];
        ummutex_unlock(_dictionaryLock);
    }
    return returnValue;
}

- (NSArray *)allKeys
{
    NSArray *a;
    ummutex_lock(_dictionaryLock);
    a = [_underlyingDictionary allKeys];
    ummutex_unlock(_dictionaryLock);
    return a;
}

- (void)removeObjectForKey:(id)aKey
{
    if(aKey)
    {
        ummutex_lock(_dictionaryLock);
        [_underlyingDictionary removeObjectForKey:aKey];
        ummutex_unlock(_dictionaryLock);
    }
}

- (NSMutableDictionary *)mutableCopy
{
    NSMutableDictionary *d;
    ummutex_lock(_dictionaryLock);
    d = [_underlyingDictionary mutableCopy];
    ummutex_unlock(_dictionaryLock);
    return d;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    UMSynchronizedDictionary *cpy;
    ummutex_lock(_dictionaryLock);
    cpy = [[UMSynchronizedDictionary allocWithZone:zone] initWithDictionary:_underlyingDictionary];
    ummutex_unlock(_dictionaryLock);
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
