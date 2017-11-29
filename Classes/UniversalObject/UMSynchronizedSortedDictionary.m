//
//  UMSychronizedSortedDictionary.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSynchronizedSortedDictionary.h"
#import "UMJsonWriter.h"

@implementation UMSynchronizedSortedDictionary


@synthesize sortIndex;

- (UMSynchronizedSortedDictionary *)init
{
    self = [super init];
    if(self)
    {
        sortIndex = [[NSMutableArray alloc]init];
    }
    return self;
}

- (UMSynchronizedSortedDictionary *)initWithDictionary:(NSDictionary *)sd
{
    self = [super initWithDictionary:sd];
    if(self)
    {
        sortIndex = [[NSMutableArray alloc]init];
        for(id key in underlyingDictionary)
        {
            [sortIndex addObject:key];
        }
    }
    return self;
}

+ (instancetype)synchronizedSortedDictionary
{
    UMSynchronizedSortedDictionary *sd = [[UMSynchronizedSortedDictionary alloc]init];
    return sd;
}

+ (instancetype)synchronizedSortedDictionaryWithDictionary:(NSDictionary *)xd
{
    return [[UMSynchronizedSortedDictionary alloc]initWithDictionary:xd];
}


- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key
{
    if(!key)
    {
        return;
    }
    [_mutex lock];
    if (underlyingDictionary[key] == NULL)
    {
        if(anObject)
        {
            [underlyingDictionary setObject:anObject forKey:key];
            [sortIndex addObject:key];
        }
    }
    else
    {
        if(anObject)
        {
            [underlyingDictionary setObject:anObject forKey:key];
        }
    }
    [_mutex unlock];
}

- (id)objectForKeyedSubscript:(id)key
{
    if(!key)
    {
        return NULL;
    }
    [_mutex lock];
    id r = [underlyingDictionary objectForKey:key];
    [_mutex unlock];
    return r;
}

- (id)objectAtIndex:(NSUInteger)index
{
    id r = NULL;
    [_mutex lock];
    id key = sortIndex[index];
    if(key)
    {
        r = [underlyingDictionary objectForKey:key];
    }
    [_mutex unlock];
    return r;
}

- (id)keyAtIndex:(NSUInteger)index
{
    id key = NULL;
    [_mutex lock];
    key = sortIndex[index];
    [_mutex unlock];
    return key;
}


- (NSArray *)allKeys
{
    [_mutex lock];
    NSArray *r = [sortIndex copy];
    [_mutex unlock];
    return r;
}

- (void)removeObjectForKey:(id)aKey
{
    if(!aKey)
    {
        return;
    }
    [_mutex lock];
    [underlyingDictionary removeObjectForKey:aKey];
    [sortIndex removeObjectIdenticalTo:aKey];
    [_mutex unlock];
}


- (void)addObject:(id)o forKey:(id)key
{
    [self setObject:o forKeyedSubscript:key];
}

- (NSArray *)sortedKeys
{
    return [sortIndex copy];
}
- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"UMSynchronizedSortedDictionary {\n"];
    for(id key in sortIndex)
    {
        id entry = underlyingDictionary[key];
        [s appendFormat:@"%@ = %@\n",key,entry];
    }
    [s appendFormat:@"}\n"];
    return s;
}

- (NSString *)jsonString;
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    NSString *json = [writer stringWithObject:self];
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
    NSString *json = [writer stringWithObject:self];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}


- (id)copyWithZone:(nullable NSZone *)zone
{
    UMSynchronizedSortedDictionary *cpy = [[UMSynchronizedSortedDictionary allocWithZone:zone]init];
    cpy->underlyingDictionary = [underlyingDictionary copy];
    cpy->sortIndex = [sortIndex copy];
    return cpy;
}

@end

