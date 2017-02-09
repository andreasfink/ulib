//
//  UMSynchronizedSortedDictionary.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSynchronizedDictionary.h"

/*!
 @class UMSynchronizedSortedDictionary
 @brief UMSynchronizedSortedDictionary is like UMSynchronizedDictionary but it keeps the sequence of the entries in the order they where added. Useful for dictionaries which have a natural order
     such as the order it was written in a config file or a specification.

 UMSynchronizedDictionary can be used like NSMutableDictionary (but its not a subclass of it).
 To create a UMSynchronizedDictionary from a NSDictionary use the initWithDictionary initializer.
 To create a NSMutableDictionary from UMSynchronizedDictionary, use mutableCopy method.
 */

@interface UMSynchronizedSortedDictionary : UMSynchronizedDictionary
{
    NSMutableArray *sortIndex;
}

@property (readonly,strong) NSMutableArray *sortIndex;

+ (instancetype)synchronizedSortedDictionary;
+ (instancetype)synchronizedSortedDictionaryWithDictionary:(NSDictionary *)xd;
- (id)objectAtIndex:(NSUInteger)index;
- (id)keyAtIndex:(NSUInteger)index;
- (id)objectForKeyedSubscript:(id)key;
- (void)removeObjectForKey:(id)aKey;
- (void)addObject:(id)o forKey:(id)key;
- (NSArray *)sortedKeys;
- (NSString *)jsonString;
@end

