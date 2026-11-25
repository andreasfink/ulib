//
//  UMASN1Sequence.h
//  ulibasn1
//
//  Created by Andreas Fink on 08.09.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMASN1Object.h>

@interface UMASN1Sequence : UMASN1Object

- (UMASN1Sequence *)init;
- (UMASN1Sequence *)initWithValues:(NSArray *)arr;
- (NSArray *)values;
- (void)setValues:(NSArray *)arr;
- (void)appendValue:(UMASN1Object *)o;


- (void)addObject:(UMASN1Object *)o;
- (void)addObject:(NSObject *)o1 withContentSpecificTag:(uint64_t)tag;
- (void)addNSString:(NSString *)s withContentSpecificTag:(uint64_t)tag;
- (void)addIntegerNumber:(NSNumber *)n withContentSpecificTag:(int64_t)tag;
- (void)addRealNumber:(NSNumber *)n withContentSpecificTag:(int64_t)tag;
- (void)addBooleanNull:(BOOL)b withContentSpecificTag:(int64_t)tag;

@end
