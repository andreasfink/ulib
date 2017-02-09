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
    @synchronized(self)
    {
        NSUInteger cnt = [array count];
        return cnt;
    }
}


- (void)addObject:(id)anObject
{
    @synchronized(self)
    {
        [array addObject:anObject];
    }
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
    @synchronized(self)
    {
        [array insertObject:anObject atIndex:index];
    }
}

- (void)removeLastObject
{
    @synchronized(self)
    {
        [array removeLastObject];
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        [array removeObjectAtIndex:index];
    }
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    @synchronized(self)
    {
        [array setObject:anObject atIndexedSubscript:index];
        ////array[index] = anObject;
    }
}

- (id)objectAtIndex:(NSUInteger)index
{
    id obj;
    @synchronized(self)
    {
        if(index >= [array count])
        {
            return NULL;
        }
        obj = [array objectAtIndex:index];
    }
    return obj;
}

- (NSString *)stringLines
{
    NSString *s;
    @synchronized(self)
    {
        s = [array componentsJoinedByString:@"\n"];
    }
    return s;
}

- (void)removeObject:(id)obj
{
    @synchronized(self)
    {
        [array removeObject:obj];
    }
}


- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    @synchronized(self)
    {
        [array setObject:obj atIndexedSubscript:idx];
    }
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    return [self objectAtIndex:idx];
}

- (NSMutableArray *)mutableCopy
{
    NSMutableArray *a;
    @synchronized(self)
    {
        a = [array mutableCopy];
    }
    return a;
}


- (void)appendArray:(NSArray *)arr
{
    if(arr)
    {
        @synchronized (self)
        {
            for (id o in arr)
            {
                [array addObject:o];
            }
        }
    }
}

- (NSString *)jsonString;
{
    @synchronized (self)
    {

        UMJsonWriter *writer = [[UMJsonWriter alloc] init];
        NSString *json = [writer stringWithObject:array];
        if (!json)
        {
            NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
        }
        
        return json;
    }
}
@end
