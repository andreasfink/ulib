//
//  UMSychronizedSortedDictionary.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
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
    if(key)
    {
        @synchronized(self)
        {
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
        }
    }
}

- (id)objectForKeyedSubscript:(id)key
{
    if(key)
    {
        @synchronized(self)
        {
            return [underlyingDictionary objectForKey:key];
        }
    }
    return NULL;
}

- (id)objectAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        id key = sortIndex[index];
        if(key)
        {
            return [underlyingDictionary objectForKey:key];
        }
    }
    return NULL;
}

- (NSArray *)allKeys
{
    @synchronized(self)
    {
        return [sortIndex copy];
    }
}

- (void)removeObjectForKey:(id)aKey
{
    @synchronized(self)
    {
        if(aKey)
        {
            [underlyingDictionary removeObjectForKey:aKey];
            [sortIndex removeObjectIdenticalTo:aKey];
        }
    }
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

@end

