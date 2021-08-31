//
//  UMSynchronizedArray.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSynchronizedArray.h"
#import "NSString+UniversalObject.h"
#import "UMUtil.h" /* for UMBacktrace */
#import "UMJsonWriter.h"

@implementation UMSynchronizedArray

- (id)init
{
    self = [super init];
    if(self)
    {
        _array = [[NSMutableArray alloc]init];
        _lock = [[UMMutex alloc]initWithName:@"synchronized-array"];
    }
    return self;
}

- (id)initWithArray:(NSArray *)arr
{
    self = [super init];
    if(self)
    {
        _array = [arr mutableCopy];
    }
    return self;
}


- (UMSynchronizedArray *)initWithStringLines:(NSString *)lines
{
    return [self initWithArray: [lines componentsSeparatedByString:@"\n"]];
}

+ (instancetype)synchronizedArray
{
    UMSynchronizedArray *sa = [[UMSynchronizedArray alloc]init];
    return sa;
}

+ (instancetype)synchronizedArrayWithArray:(NSArray *)arr
{
    UMSynchronizedArray *sa = [[UMSynchronizedArray alloc]initWithArray:arr];
    return sa;
}

- (NSUInteger)count
{
    UMMUTEX_LOCK(_lock);
    NSUInteger cnt = [_array count];
    UMMUTEX_LOCK(_lock);
    return cnt;
}


- (void)addObject:(id)anObject
{
    if(anObject==NULL)
    {
        return;
    }
    UMMUTEX_LOCK(_lock);
    [_array addObject:anObject];
    UMMUTEX_UNLOCK(_lock);
}


- (void)addObjectUnique:(id)anObject
{
    if(anObject==NULL)
    {
        return;
    }
    UMMUTEX_LOCK(_lock);
    [_array removeObject:anObject];
    [_array addObject:anObject];
    UMMUTEX_UNLOCK(_lock);
}

- (void)addPrintableString:(NSString *)s
{
    NSString *ps = [s printable];
    [self addObject:ps];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if(anObject==NULL)
    {
        @throw([NSException exceptionWithName:@"INSERT_NULL_IN_SYNCRONIZED_ARRAY"
                                       reason:NULL
                                     userInfo:@{
                                                @"sysmsg" : @"UMSynchronizedArray: trying to insert NULL object",
                                                @"func": @(__func__),
                                                @"backtrace": UMBacktrace(NULL,0)
                                                }
                ]);
    }
    UMMUTEX_LOCK(_lock);
    [_array insertObject:anObject atIndex:index];
    UMMUTEX_UNLOCK(_lock);
}

- (void)removeLastObject
{
    UMMUTEX_LOCK(_lock);
    [_array removeLastObject];
    UMMUTEX_UNLOCK(_lock);
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    UMMUTEX_LOCK(_lock);
    [_array removeObjectAtIndex:index];
    UMMUTEX_UNLOCK(_lock);
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    UMMUTEX_LOCK(_lock);
    [_array setObject:anObject atIndexedSubscript:index];
    UMMUTEX_UNLOCK(_lock);
}

- (id)objectAtIndex:(NSUInteger)index
{
    id obj = NULL;
    UMMUTEX_LOCK(_lock);
    if(index < [_array count])
    {
        obj = [_array objectAtIndex:index];
    }
    UMMUTEX_UNLOCK(_lock);
    return obj;
}


- (id)removeFirst
{
    id obj = NULL;
    UMMUTEX_LOCK(_lock);
    if(_array.count>0)
    {
        obj = [_array objectAtIndex:0];
        [_array removeObjectAtIndex:0];
    }
    UMMUTEX_UNLOCK(_lock);
    return obj;
}

- (NSString *)stringLines
{
    NSString *s;
    UMMUTEX_LOCK(_lock);
    s = [_array componentsJoinedByString:@"\n"];
    UMMUTEX_UNLOCK(_lock);
    return s;
}

- (void)removeObject:(id)obj
{
    UMMUTEX_LOCK(_lock);
    [_array removeObject:obj];
    UMMUTEX_UNLOCK(_lock);
}


- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    UMMUTEX_LOCK(_lock);
    [_array setObject:obj atIndexedSubscript:idx];
    UMMUTEX_UNLOCK(_lock);
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    UMMUTEX_LOCK(_lock);
    id r = [self objectAtIndex:idx];
    UMMUTEX_UNLOCK(_lock);
    return r;
}

- (NSMutableArray *)mutableCopy
{
    NSMutableArray *a;
    UMMUTEX_LOCK(_lock);
    a = [_array mutableCopy];
    UMMUTEX_UNLOCK(_lock);
    return a;
}


- (void)appendArray:(NSArray *)arr
{
    if(arr)
    {
        UMMUTEX_LOCK(_lock);
        for (id o in arr)
        {
            [_array addObject:o];
        }
        UMMUTEX_UNLOCK(_lock);
    }
}


- (id)copyWithZone:(nullable NSZone *)zone
{
    UMMUTEX_LOCK(_lock);
    UMSynchronizedArray *sa = [[UMSynchronizedArray allocWithZone:zone]initWithArray:_array];
    UMMUTEX_UNLOCK(_lock);
    return sa;
}

- (NSArray *)arrayCopy
{
    UMMUTEX_LOCK(_lock);
    NSArray *a = [_array copy];
    UMMUTEX_UNLOCK(_lock);
    return a;
}


- (NSString *)jsonString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    UMMUTEX_LOCK(_lock);
    NSString *json=NULL;
    @try
    {
        json = [writer stringWithObject:_array];
        if (!json)
        {
            NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
        }
    }
    @finally
    {
        UMMUTEX_UNLOCK(_lock);
    }
    return json;
}


- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    UMMUTEX_LOCK(_lock);
    NSString *json=NULL;
    @try
    {
        json = [writer stringWithObject:_array];
        if (!json)
        {
            NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
        }
    }
    @finally
    {
        UMMUTEX_UNLOCK(_lock);
    }
    return json;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained _Nullable [_Nonnull])stackbuf
									count:(NSUInteger)len;
{
	UMMUTEX_LOCK(_lock);
	NSUInteger iu = [_array countByEnumeratingWithState:state objects:stackbuf count:len];
	UMMUTEX_UNLOCK(_lock);
	return iu;
}


- (void)lock
{
    UMMUTEX_LOCK(_lock);
}

- (void)unlock
{
    UMMUTEX_UNLOCK(_lock);
}

@end
