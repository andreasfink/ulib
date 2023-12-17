//
//  UMSynchronizedArray.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMSynchronizedArray.h>
#import <ulib/NSString+ulib.h>
#import <ulib/UMUtil.h> /* for UMBacktrace */
#import <ulib/UMJsonWriter.h>

@implementation UMSynchronizedArray

- (id)init
{
    self = [super init];
    if(self)
    {
        _array = [[NSMutableArray alloc]init];
        _arrayLock = [[UMMutex alloc]initWithName:@"synchronized-array"];
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
    UMMUTEX_LOCK(_arrayLock);
    NSUInteger cnt = [_array count];
    UMMUTEX_UNLOCK(_arrayLock);
    return cnt;
}


- (void)addObject:(id)anObject
{
    if(anObject==NULL)
    {
        return;
    }
    UMMUTEX_LOCK(_arrayLock);
    [_array addObject:anObject];
    UMMUTEX_UNLOCK(_arrayLock);
}


- (void)addObjectUnique:(id)anObject
{
    if(anObject==NULL)
    {
        return;
    }
    UMMUTEX_LOCK(_arrayLock);
    [_array removeObject:anObject];
    [_array addObject:anObject];
    UMMUTEX_UNLOCK(_arrayLock);
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
    UMMUTEX_LOCK(_arrayLock);
    [_array insertObject:anObject atIndex:index];
    UMMUTEX_UNLOCK(_arrayLock);
}

- (void)removeLastObject
{
    UMMUTEX_LOCK(_arrayLock);
    [_array removeLastObject];
    UMMUTEX_UNLOCK(_arrayLock);
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    UMMUTEX_LOCK(_arrayLock);
    [_array removeObjectAtIndex:index];
    UMMUTEX_UNLOCK(_arrayLock);
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    UMMUTEX_LOCK(_arrayLock);
    [_array setObject:anObject atIndexedSubscript:index];
    UMMUTEX_UNLOCK(_arrayLock);
}

- (id)objectAtIndex:(NSUInteger)index
{
    id obj = NULL;
    UMMUTEX_LOCK(_arrayLock);
    if(index < [_array count])
    {
        obj = [_array objectAtIndex:index];
    }
    UMMUTEX_UNLOCK(_arrayLock);
    return obj;
}


- (id)removeFirst
{
    id obj = NULL;
    UMMUTEX_LOCK(_arrayLock);
    if(_array.count>0)
    {
        obj = [_array objectAtIndex:0];
        [_array removeObjectAtIndex:0];
    }
    UMMUTEX_UNLOCK(_arrayLock);
    return obj;
}

- (NSString *)stringLines
{
    NSString *s;
    UMMUTEX_LOCK(_arrayLock);
    s = [_array componentsJoinedByString:@"\n"];
    UMMUTEX_UNLOCK(_arrayLock);
    return s;
}

- (void)removeObject:(id)obj
{
    UMMUTEX_LOCK(_arrayLock);
    [_array removeObject:obj];
    UMMUTEX_UNLOCK(_arrayLock);
}


- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    UMMUTEX_LOCK(_arrayLock);
    [_array setObject:obj atIndexedSubscript:idx];
    UMMUTEX_UNLOCK(_arrayLock);
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    UMMUTEX_LOCK(_arrayLock);
    id r = [self objectAtIndex:idx];
    UMMUTEX_UNLOCK(_arrayLock);
    return r;
}

- (NSMutableArray *)mutableCopy
{
    NSMutableArray *a;
    UMMUTEX_LOCK(_arrayLock);
    a = [_array mutableCopy];
    UMMUTEX_UNLOCK(_arrayLock);
    return a;
}


- (void)appendArray:(NSArray *)arr
{
    if(arr)
    {
        UMMUTEX_LOCK(_arrayLock);
        for (id o in arr)
        {
            [_array addObject:o];
        }
        UMMUTEX_UNLOCK(_arrayLock);
    }
}


- (id)copyWithZone:(nullable NSZone *)zone
{
    UMMUTEX_LOCK(_arrayLock);
    UMSynchronizedArray *sa = [[UMSynchronizedArray allocWithZone:zone]initWithArray:_array];
    UMMUTEX_UNLOCK(_arrayLock);
    return sa;
}

- (NSArray *)arrayCopy
{
    UMMUTEX_LOCK(_arrayLock);
    NSArray *a = [_array copy];
    UMMUTEX_UNLOCK(_arrayLock);
    return a;
}


- (NSString *)jsonString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    UMMUTEX_LOCK(_arrayLock);
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
        UMMUTEX_UNLOCK(_arrayLock);
    }
    return json;
}


- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    UMMUTEX_LOCK(_arrayLock);
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
        UMMUTEX_UNLOCK(_arrayLock);
    }
    return json;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained _Nullable [_Nonnull])stackbuf
									count:(NSUInteger)len;
{
	UMMUTEX_LOCK(_arrayLock);
	NSUInteger iu = [_array countByEnumeratingWithState:state objects:stackbuf count:len];
	UMMUTEX_UNLOCK(_arrayLock);
	return iu;
}


- (void)lock
{
    UMMUTEX_LOCK(_arrayLock);
}

- (void)unlock
{
    UMMUTEX_UNLOCK(_arrayLock);
}

@end
