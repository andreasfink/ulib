//
//  UMSynchronizedDictionary.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMObject.h>
#import <ulib/UMMutex.h>
/*!
 @class UMSynchronizedDictionary
 @brief A dictionary who's access is synchronized so it can be accessed from multiple threads

 UMSynchronizedDictionary can be used like NSMutableDictionary (but its not a subclass of it).
 To create a UMSynchronizedDictionary from a NSDictionary use the initWithDictionary initializer.
 To create a NSMutableDictionary from UMSynchronizedDictionary, use mutableCopy method.
 */

@interface UMSynchronizedDictionary : UMObject<NSCopying>
{
    NSMutableDictionary *_underlyingDictionary;
    UMMutex             *_dictionaryLock;
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
- (NSDictionary *)dictionaryCopy;
- (UMSynchronizedDictionary *)copyWithZone:(NSZone *)zone;
- (void) lock;
- (void) unlock;
- (void) flush;

- (NSString *)jsonCompactString;
- (NSString *)jsonString;

@end
