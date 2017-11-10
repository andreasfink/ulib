//
//  UMSynchronizedDictionary.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMSynchronizedDictionary.h"

@implementation UMSynchronizedDictionary

@synthesize dict;

- (UMSynchronizedDictionary *)init
{
    self = [super init];
    if(self)
    {
        underlyingDictionary = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (UMSynchronizedDictionary *)initWithDictionary:(NSDictionary *)sd
{
    self = [super init];
    if(self)
    {
        underlyingDictionary = [sd mutableCopy];
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
    @synchronized(underlyingDictionary)
    {
        NSUInteger cnt  = [underlyingDictionary count];
        return cnt;
    }
}


- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key
{
    if(key)
    {
        @synchronized(underlyingDictionary)
        {
            [underlyingDictionary setObject:anObject forKey:key];
        }
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    if(key)
    {
        @synchronized(underlyingDictionary)
        {
            return [underlyingDictionary objectForKey:key];
        }
    }
    return NULL;
}

- (NSArray *)allKeys
{
    @synchronized(underlyingDictionary)
    {
        return [underlyingDictionary allKeys];
    }
}

- (void)removeObjectForKey:(id)aKey
{
    if(aKey)
    {
        @synchronized(underlyingDictionary)
        {
            [underlyingDictionary removeObjectForKey:aKey];
        }
    }
}

- (NSMutableDictionary *)mutableCopy
{
    NSMutableDictionary *d;
    @synchronized(underlyingDictionary)
    {
        d = [underlyingDictionary mutableCopy];
    }
    return d;
}

- (UMSynchronizedDictionary *)copyWithZone:(NSZone *)zone
{
    @synchronized(underlyingDictionary)
    {
        UMSynchronizedDictionary *cpy = [[UMSynchronizedDictionary allocWithZone:zone] initWithDictionary:underlyingDictionary];
        return cpy;
    }
}
@end
