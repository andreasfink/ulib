//
//  UMSynchronizedSortedDictionary.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMSynchronizedDictionary.h"

@interface UMSynchronizedSortedDictionary : UMSynchronizedDictionary
{
    NSMutableArray *sortIndex;
}

@property (readonly,strong) NSMutableArray *sortIndex;

+ (instancetype)synchronizedSortedDictionary;
+ (instancetype)synchronizedSortedDictionaryWithDictionary:(NSDictionary *)xd;
- (id)objectAtIndex:(NSUInteger)index;
- (id)objectForKeyedSubscript:(id)key;
- (void)removeObjectForKey:(id)aKey;
- (void)addObject:(id)o forKey:(id)key;
- (NSArray *)sortedKeys;
- (NSString *)jsonString;
@end

