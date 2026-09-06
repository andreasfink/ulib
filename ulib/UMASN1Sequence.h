//
//  UMASN1Sequence.h
//  ulibasn1
//
//  Created by Andreas Fink on 08.09.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1Object.h>

@interface UMASN1Sequence : UMASN1Object

- (UMASN1Sequence *)init;
- (UMASN1Sequence *)initWithValues:(NSArray *)arr;
- (NSArray *)values;
- (void)setValues:(NSArray *)arr;
- (void)appendValue:(UMASN1Object *)o;

@end
