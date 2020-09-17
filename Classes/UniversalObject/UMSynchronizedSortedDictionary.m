//
//  UMSychronizedSortedDictionary.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSynchronizedSortedDictionary.h"
#import "UMJsonWriter.h"

@implementation UMSynchronizedSortedDictionary


- (UMSynchronizedSortedDictionary *)init
{
    self = [super init];
    if(self)
    {
        _sortIndex = [[NSMutableArray alloc]init];
    }
    return self;
}

- (UMSynchronizedSortedDictionary *)initWithDictionary:(NSDictionary *)sd
{
    self = [super initWithDictionary:sd];
    if(self)
    {
        _sortIndex = [[NSMutableArray alloc]init];
        for(id key in _underlyingDictionary)
        {
            [_sortIndex addObject:key];
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
    [_lock lock];
    if (_underlyingDictionary[key] == NULL)
    {
        if(anObject)
        {
            [super setObject:anObject forKeyedSubscript:key];
            [_sortIndex addObject:key];
        }
    }
    else
    {
        if(anObject)
        {
            [super setObject:anObject forKeyedSubscript:key];
        }
    }
    [_lock unlock];
}

- (id)objectForKeyedSubscript:(id)key
{
    if(!key)
    {
        return NULL;
    }
    [_lock lock];
    id r = [_underlyingDictionary objectForKey:key];
    [_lock unlock];
    return r;
}

- (id)objectAtIndex:(NSUInteger)index
{
    id r = NULL;
    [_lock lock];
    id key = _sortIndex[index];
    if(key)
    {
        r = [_underlyingDictionary objectForKey:key];
    }
    [_lock unlock];
    return r;
}

- (id)keyAtIndex:(NSUInteger)index
{
    id key = NULL;
    [_lock lock];
    key = _sortIndex[index];
    [_lock unlock];
    return key;
}


- (NSArray *)allKeys
{
    [_lock lock];
    NSArray *r = [_sortIndex copy];
    [_lock unlock];
    return r;
}

- (void)removeObjectForKey:(id)aKey
{
    if(!aKey)
    {
        return;
    }
    [_lock lock];
    [_underlyingDictionary removeObjectForKey:aKey];
    [_sortIndex removeObject:aKey];
    [_lock unlock];
}



- (void)addObject:(id)o forKey:(id)key
{
    [self setObject:o forKeyedSubscript:key];
}

- (NSArray *)sortedKeys
{
    return [_sortIndex copy];
}
- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"UMSynchronizedSortedDictionary {\n"];
    for(id key in _sortIndex)
    {
        id entry = _underlyingDictionary[key];
        [s appendFormat:@"%@ = %@\n",key,entry];
    }
    [s appendFormat:@"}\n"];
    return s;
}

- (NSString *)jsonString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    [_lock lock];
    NSString *json=NULL;
    @try
    {
        json = [writer stringWithObject:self];
        if (!json)
        {
            NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
            NSLog(@"_underlyingDictionary = %@",_underlyingDictionary);
            NSLog(@"_sortIndex = %@",_sortIndex);
        }
    }
    @finally
    {
        [_lock unlock];
    }
    return json;
}

- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = NO;
    [_lock lock];
    NSString *json=NULL;
    @try
    {
        json = [writer stringWithObject:self];
        if (!json)
        {
            NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
        }
    }
    @finally
    {
        [_lock unlock];
    }
    return json;
}


- (id)copyWithZone:(nullable NSZone *)zone
{
    UMSynchronizedSortedDictionary *cpy = [[UMSynchronizedSortedDictionary allocWithZone:zone]init];
    cpy->_underlyingDictionary = [_underlyingDictionary mutableCopy];
    cpy->_sortIndex = [_sortIndex mutableCopy];
    return cpy;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained _Nullable [_Nonnull])stackbuf
									count:(NSUInteger)len
{
	[_lock lock];
	NSUInteger iu = [_sortIndex countByEnumeratingWithState:state objects:stackbuf count:len];
	[_lock unlock];
	return iu;
}

@end

