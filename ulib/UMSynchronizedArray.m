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
        _arrayLock = [[UMMutex alloc]initWithName:@"synchronized-array"];
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
    ummutex_lock(_arrayLock);
    NSUInteger cnt = [_array count];
    ummutex_unlock(_arrayLock);
    return cnt;
}


- (void)addObject:(id)anObject
{
    if(anObject==NULL)
    {
        return;
    }
    ummutex_lock(_arrayLock);
    [_array addObject:anObject];
    ummutex_unlock(_arrayLock);
}


- (void)addObjectUnique:(id)anObject
{
    if(anObject==NULL)
    {
        return;
    }
    ummutex_lock(_arrayLock);
    [_array removeObject:anObject];
    [_array addObject:anObject];
    ummutex_unlock(_arrayLock);
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
    ummutex_lock(_arrayLock);
    [_array insertObject:anObject atIndex:index];
    ummutex_unlock(_arrayLock);
}

- (id)lastObject
{
    id lastObject = NULL;
    ummutex_lock(_arrayLock);
    NSInteger i = _array.count;
    if(i>0)
    {
        lastObject = [_array objectAtIndex:i-1];
    }
    ummutex_unlock(_arrayLock);
    return lastObject;
}

- (id)firstObject
{
    id firstObject = NULL;
    ummutex_lock(_arrayLock);
    NSInteger i = _array.count;
    if(i>0)
    {
        firstObject = [_array objectAtIndex:0];
    }
    ummutex_unlock(_arrayLock);
    return firstObject;
}
- (id)removeLastObject
{
    id lastObject = NULL;
    ummutex_lock(_arrayLock);
    NSInteger i = _array.count;
    if(i>0)
    {
        lastObject = [_array objectAtIndex:i];
        [_array removeLastObject];
    }
    ummutex_unlock(_arrayLock);
    return lastObject;
}

- (id)removeObjectAtIndex:(NSUInteger)index
{
    ummutex_lock(_arrayLock);
    id removedObject = [_array objectAtIndex:index];
    [_array removeObjectAtIndex:index];
    ummutex_unlock(_arrayLock);
    return removedObject;
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    ummutex_lock(_arrayLock);
    [_array setObject:anObject atIndexedSubscript:index];
    ummutex_unlock(_arrayLock);
}

- (id)objectAtIndex:(NSUInteger)index
{
    id obj = NULL;
    ummutex_lock(_arrayLock);
    if(index < [_array count])
    {
        obj = [_array objectAtIndex:index];
    }
    ummutex_unlock(_arrayLock);
    return obj;
}


- (id)removeFirst
{
    id obj = NULL;
    ummutex_lock(_arrayLock);
    if(_array.count>0)
    {
        obj = [_array objectAtIndex:0];
        [_array removeObjectAtIndex:0];
    }
    ummutex_unlock(_arrayLock);
    return obj;
}

- (NSString *)stringLines
{
    NSString *s;
    ummutex_lock(_arrayLock);
    s = [_array componentsJoinedByString:@"\n"];
    ummutex_unlock(_arrayLock);
    return s;
}

- (void)removeObject:(id)obj
{
    ummutex_lock(_arrayLock);
    [_array removeObject:obj];
    ummutex_unlock(_arrayLock);
}


- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    ummutex_lock(_arrayLock);
    [_array setObject:obj atIndexedSubscript:idx];
    ummutex_unlock(_arrayLock);
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    ummutex_lock(_arrayLock);
    id r = [self objectAtIndex:idx];
    ummutex_unlock(_arrayLock);
    return r;
}

- (NSMutableArray *)mutableCopy
{
    NSMutableArray *a;
    ummutex_lock(_arrayLock);
    a = [_array mutableCopy];
    ummutex_unlock(_arrayLock);
    return a;
}


- (void)appendArray:(NSArray *)arr
{
    if(arr)
    {
        ummutex_lock(_arrayLock);
        for (id o in arr)
        {
            [_array addObject:o];
        }
        ummutex_unlock(_arrayLock);
    }
}


- (id)copyWithZone:(nullable NSZone *)zone
{
    ummutex_lock(_arrayLock);
    UMSynchronizedArray *sa = [[UMSynchronizedArray allocWithZone:zone]initWithArray:_array];
    ummutex_unlock(_arrayLock);
    return sa;
}

- (NSArray *)arrayCopy
{
    ummutex_lock(_arrayLock);
    NSArray *a = [_array copy];
    ummutex_unlock(_arrayLock);
    return a;
}


- (NSString *)jsonString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    ummutex_lock(_arrayLock);
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
        ummutex_unlock(_arrayLock);
    }
    return json;
}


- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    ummutex_lock(_arrayLock);
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
        ummutex_unlock(_arrayLock);
    }
    return json;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained _Nullable [_Nonnull])stackbuf
                                    count:(NSUInteger)len;
{
    ummutex_lock(_arrayLock);
    NSUInteger iu = [_array countByEnumeratingWithState:state objects:stackbuf count:len];
    ummutex_unlock(_arrayLock);
    return iu;
}


- (void)lock
{
    ummutex_lock(_arrayLock);
}

- (void)unlock
{
    ummutex_unlock(_arrayLock);
}


- (UMSynchronizedArray *)sortedArrayUsingComparator:(NSComparator)cmptr
{
    ummutex_lock(_arrayLock);
    NSArray *arr2 = [_array sortedArrayUsingComparator:cmptr];
    UMSynchronizedArray *ua = [[UMSynchronizedArray alloc]initWithArray:arr2];
    ummutex_unlock(_arrayLock);
    return ua;
}

- (NSString *)componentsJoinedByString:(NSString *)separator
{
    ummutex_lock(_arrayLock);
    NSString *s = [_array componentsJoinedByString:separator];
    ummutex_unlock(_arrayLock);
    return s;
}
@end
