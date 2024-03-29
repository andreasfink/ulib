//
//  UMSynchronizedArray.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMMutex.h>
/*!
 @class UMSynchronizedArray
 @brief An array who's access is synchronized so it can be accessed from multiple threads

 UMSynchronizedArray can be used like NSMutableArray (but its not a subclass of it).
 To create a UMSynchronizedArray from a NSArray use the initWithArray initializer.
 To create a NSArray/NSMutableArray from UMSynchronizedArray, use mutableCopy method.
 */

@interface UMSynchronizedArray : UMObject<NSCopying,NSFastEnumeration>
{
    NSMutableArray  *_array;
    UMMutex         *_arrayLock;
}

@property (readonly,strong) NSMutableArray *array;

- (UMSynchronizedArray *)init;
- (UMSynchronizedArray *)initWithArray:(NSArray *)arr;
- (UMSynchronizedArray *)initWithStringLines:(NSString *)lines;

+ (instancetype)synchronizedArray;
+ (instancetype)synchronizedArrayWithArray:(NSArray *)array;

- (NSUInteger)count;

- (void)addObject:(id)anObject;
- (void)addObjectUnique:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (id)objectAtIndex:(NSUInteger)index;
- (NSString *)stringLines;
- (void)addPrintableString:(NSString *)s;
- (void)removeObject:(id)obj;
- (id)removeFirst;
- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSMutableArray *)mutableCopy;
- (void)appendArray:(NSArray *)app;
- (NSArray *)arrayCopy;

- (NSString *)jsonString;
- (NSString *)jsonCompactString;


/* if you need to lock other thread's operation on this array temporarely */
- (void)lock;
- (void)unlock;
@end

