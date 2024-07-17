//
//  UMSychronizedSortedDictionary.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMSynchronizedSortedDictionary.h>
#import <ulib/UMJsonWriter.h>

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
    ummutex_lock(_dictionaryLock);
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
    ummutex_unlock(_dictionaryLock);
}

- (id)objectForKeyedSubscript:(id)key
{
    if(!key)
    {
        return NULL;
    }
    ummutex_lock(_dictionaryLock);
    id r = [_underlyingDictionary objectForKey:key];
    ummutex_unlock(_dictionaryLock);
    return r;
}

- (id)objectAtIndex:(NSUInteger)index
{
    id r = NULL;
    ummutex_lock(_dictionaryLock);
    id key = _sortIndex[index];
    if(key)
    {
        r = [_underlyingDictionary objectForKey:key];
    }
    ummutex_unlock(_dictionaryLock);
    return r;
}

- (id)keyAtIndex:(NSUInteger)index
{
    id key = NULL;
    ummutex_lock(_dictionaryLock);
    key = _sortIndex[index];
    ummutex_unlock(_dictionaryLock);
    return key;
}


- (NSArray *)allKeys
{
    ummutex_lock(_dictionaryLock);
    NSArray *r = [_sortIndex copy];
    ummutex_unlock(_dictionaryLock);
    return r;
}

- (void)removeObjectForKey:(id)aKey
{
    if(!aKey)
    {
        return;
    }
    ummutex_lock(_dictionaryLock);
    [_underlyingDictionary removeObjectForKey:aKey];
    [_sortIndex removeObject:aKey];
    ummutex_unlock(_dictionaryLock);
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
    ummutex_lock(_dictionaryLock);
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
        ummutex_unlock(_dictionaryLock);
    }
    return json;
}

- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = NO;
    ummutex_lock(_dictionaryLock);
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
        ummutex_unlock(_dictionaryLock);
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
	ummutex_lock(_dictionaryLock);
	NSUInteger iu = [_sortIndex countByEnumeratingWithState:state objects:stackbuf count:len];
	ummutex_unlock(_dictionaryLock);
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

