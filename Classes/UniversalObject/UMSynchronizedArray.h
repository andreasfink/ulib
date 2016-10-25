//
//  UMSynchronizedArray.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMObject.h"

@interface UMSynchronizedArray : UMObject
{
    NSMutableArray *array;
}

@property (readonly,strong) NSMutableArray *array;

- (UMSynchronizedArray *)init;
- (UMSynchronizedArray *)initWithArray:(NSArray *)arr;
- (UMSynchronizedArray *)initWithStringLines:(NSString *)lines;

+ (instancetype)synchronizedArray;
+ (instancetype)synchronizedArrayWithArray:(NSArray *)array;

- (NSUInteger)count;

- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(NSUInteger)index;
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject;
- (id)objectAtIndex:(NSUInteger)index;
- (NSString *)stringLines;
- (void)addPrintableString:(NSString *)s;
- (void)removeObject:(id)obj;


- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;
- (NSMutableArray *)mutableCopy;
- (void)appendArray:(NSArray *)app;

@end

