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
    UMMUTEX_LOCK(_dictionaryLock);
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
    UMMUTEX_UNLOCK(_dictionaryLock);
}

- (id)objectForKeyedSubscript:(id)key
{
    if(!key)
    {
        return NULL;
    }
    UMMUTEX_LOCK(_dictionaryLock);
    id r = [_underlyingDictionary objectForKey:key];
    UMMUTEX_UNLOCK(_dictionaryLock);
    return r;
}

- (id)objectAtIndex:(NSUInteger)index
{
    id r = NULL;
    UMMUTEX_LOCK(_dictionaryLock);
    id key = _sortIndex[index];
    if(key)
    {
        r = [_underlyingDictionary objectForKey:key];
    }
    UMMUTEX_UNLOCK(_dictionaryLock);
    return r;
}

- (id)keyAtIndex:(NSUInteger)index
{
    id key = NULL;
    UMMUTEX_LOCK(_dictionaryLock);
    key = _sortIndex[index];
    UMMUTEX_UNLOCK(_dictionaryLock);
    return key;
}


- (NSArray *)allKeys
{
    UMMUTEX_LOCK(_dictionaryLock);
    NSArray *r = [_sortIndex copy];
    UMMUTEX_UNLOCK(_dictionaryLock);
    return r;
}

- (void)removeObjectForKey:(id)aKey
{
    if(!aKey)
    {
        return;
    }
    UMMUTEX_LOCK(_dictionaryLock);
    [_underlyingDictionary removeObjectForKey:aKey];
    [_sortIndex removeObject:aKey];
    UMMUTEX_UNLOCK(_dictionaryLock);
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
    UMMUTEX_LOCK(_dictionaryLock);
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
        UMMUTEX_UNLOCK(_dictionaryLock);
    }
    return json;
}

- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = NO;
    UMMUTEX_LOCK(_dictionaryLock);
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
        UMMUTEX_UNLOCK(_dictionaryLock);
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
	UMMUTEX_LOCK(_dictionaryLock);
	NSUInteger iu = [_sortIndex countByEnumeratingWithState:state objects:stackbuf count:len];
	UMMUTEX_UNLOCK(_dictionaryLock);
	return iu;
}

static NSInteger keySort(id a, id b, void *context)
{
    return [a compare:b];
}

- (void)sortKeys
{
    NSArray *sortedIndex =  [_sortIndex sortedArrayUsingFunction:keySort context:NULL];
    _sortIndex = [sortedIndex mutableCopy];
}


@end

