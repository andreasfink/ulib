//
//  UMASN1UTF8String.h
//  ulibasn1
//
//  Created by Andreas Fink on 08.09.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1Object.h>

@interface UMASN1UTF8String : UMASN1Object

- (UMASN1UTF8String *)initWithString:(NSString *)s;
- (UMASN1UTF8String *)initWithValue:(NSString *)s;
- (NSString *) value;
- (NSString *)stringValue;
- (void) setValue:(NSString *)v;

@end
