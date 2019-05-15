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
        _mutex = [[UMMutex alloc]initWithName:@"synchronized-array"];
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
    [_mutex lock];
    NSUInteger cnt = [_array count];
    [_mutex unlock];
    return cnt;
}


- (void)addObject:(id)anObject
{
    [_mutex lock];
    [_array addObject:anObject];
    [_mutex unlock];
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
    [_mutex lock];
    [_array insertObject:anObject atIndex:index];
    [_mutex unlock];
}

- (void)removeLastObject
{
    [_mutex lock];
    [_array removeLastObject];
    [_mutex unlock];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_mutex lock];
    [_array removeObjectAtIndex:index];
    [_mutex unlock];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [_mutex lock];
    [_array setObject:anObject atIndexedSubscript:index];
    [_mutex unlock];
}

- (id)objectAtIndex:(NSUInteger)index
{
    id obj = NULL;
    [_mutex lock];
    if(index < [_array count])
    {
        obj = [_array objectAtIndex:index];
    }
    [_mutex unlock];
    return obj;
}


- (id)removeFirst
{
    id obj = NULL;
    [_mutex lock];
    if(_array.count>0)
    {
        obj = [_array objectAtIndex:0];
        [_array removeObjectAtIndex:0];
    }
    [_mutex unlock];
    return obj;
}

- (NSString *)stringLines
{
    NSString *s;
    [_mutex lock];
    s = [_array componentsJoinedByString:@"\n"];
    [_mutex unlock];
    return s;
}

- (void)removeObject:(id)obj
{
    [_mutex lock];
    [_array removeObject:obj];
    [_mutex unlock];
}


- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [_mutex lock];
    [_array setObject:obj atIndexedSubscript:idx];
    [_mutex unlock];
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    [_mutex lock];
    id r = [self objectAtIndex:idx];
    [_mutex unlock];
    return r;
}

- (NSMutableArray *)mutableCopy
{
    NSMutableArray *a;
    [_mutex lock];
    a = [_array mutableCopy];
    [_mutex unlock];
    return a;
}


- (void)appendArray:(NSArray *)arr
{
    if(arr)
    {
        [_mutex lock];
        for (id o in arr)
        {
            [_array addObject:o];
        }
        [_mutex unlock];
    }
}


- (id)copyWithZone:(nullable NSZone *)zone
{
    [_mutex lock];
    UMSynchronizedArray *sa = [[UMSynchronizedArray allocWithZone:zone]initWithArray:_array];
    [_mutex unlock];
    return sa;
}

- (NSArray *)arrayCopy
{
    [_mutex lock];
    NSArray *a = [_array copy];
    [_mutex unlock];
    return a;
}


- (NSString *)jsonString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    [_mutex lock];
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
        [_mutex unlock];
    }
    return json;
}


- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    [_mutex lock];
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
        [_mutex unlock];
    }
    return json;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained _Nullable [_Nonnull])stackbuf
									count:(NSUInteger)len;
{
	[_mutex lock];
	NSUInteger iu = [_array countByEnumeratingWithState:state objects:stackbuf count:len];
	[_mutex unlock];
	return iu;
}

@end
