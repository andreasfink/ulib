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

@synthesize array;

- (id)init
{
    self = [super init];
    if(self)
    {
        array = [[NSMutableArray alloc]init];
        _mutex = [[UMMutex alloc]init];
    }
    return self;
}

- (id)initWithArray:(NSArray *)arr
{
    self = [super init];
    if(self)
    {
        array = [[NSMutableArray alloc]init];
        [array setArray:arr];
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
    NSUInteger cnt = [array count];
    [_mutex unlock];
    return cnt;
}


- (void)addObject:(id)anObject
{
    [_mutex lock];
    [array addObject:anObject];
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
    [array insertObject:anObject atIndex:index];
    [_mutex unlock];
}

- (void)removeLastObject
{
    [_mutex lock];
    [array removeLastObject];
    [_mutex unlock];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_mutex lock];
    [array removeObjectAtIndex:index];
    [_mutex unlock];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [_mutex lock];
    [array setObject:anObject atIndexedSubscript:index];
    [_mutex unlock];
}

- (id)objectAtIndex:(NSUInteger)index
{
    id obj = NULL;
    [_mutex lock];
    if(index < [array count])
    {
        obj = [array objectAtIndex:index];
    }
    [_mutex unlock];
    return obj;
}


- (id)removeFirst
{
    id obj = NULL;
    [_mutex lock];
    if(array.count>0)
    {
        obj = [array objectAtIndex:0];
        [array removeObjectAtIndex:0];
    }
    [_mutex unlock];
    return obj;
}

- (NSString *)stringLines
{
    NSString *s;
    [_mutex lock];
    s = [array componentsJoinedByString:@"\n"];
    [_mutex unlock];
    return s;
}

- (void)removeObject:(id)obj
{
    [_mutex lock];
    [array removeObject:obj];
    [_mutex unlock];
}


- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    [_mutex lock];
    [array setObject:obj atIndexedSubscript:idx];
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
    a = [array mutableCopy];
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
            [array addObject:o];
        }
        [_mutex unlock];
    }
}

- (NSString *)jsonString;
{
    NSString *json;
    [_mutex lock];
    @try
    {
        UMJsonWriter *writer = [[UMJsonWriter alloc] init];
        json = [writer stringWithObject:array];
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
@end
