//
//  UMSynchronizedDictionary.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMObject.h"

/* note: this object is not based on UMObject */

@interface UMSynchronizedDictionary : UMObject
{
    NSMutableDictionary *underlyingDictionary;
}

@property (readonly,strong) NSMutableDictionary *dict;


- (UMSynchronizedDictionary *)initWithDictionary:(NSDictionary *)sd;
+ (instancetype)synchronizedDictionary;
+ (instancetype)synchronizedDictionaryWithDictionary:(NSDictionary *)array;
- (NSUInteger)count;
- (NSArray *)allKeys;
- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)key;
- (id)objectForKeyedSubscript:(id)key;
- (void)removeObjectForKey:(id)aKey;
- (NSMutableDictionary *)mutableCopy;

@end
