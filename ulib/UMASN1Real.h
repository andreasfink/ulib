//
//  UMASN1Real.h
//  ulibasn1
//
//  Created by Andreas Fink on 06/09/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMASN1Object.h>

@interface UMASN1Real : UMASN1Object
{
    BOOL    _isPlusInfinity;
    BOOL    _isMinusInfinity;
    BOOL    _isNotANumber;
    BOOL    _isMinusZero;
    BOOL    _isZero;
    double  _internalValue;
}

@property(readwrite,assign,atomic)  BOOL    isPlusInfinity;
@property(readwrite,assign,atomic)  BOOL    isMinusInfinity;
@property(readwrite,assign,atomic)  BOOL    isNotANumber;
@property(readwrite,assign,atomic)  BOOL    isMinusZero;
@property(readwrite,assign,atomic)  BOOL    isZero;

- (UMASN1Real *)initWithValue:(double)r;
- (UMASN1Real *)initWithNumber:(NSNumber *)r;
- (double) value;
- (void) setValue:(double)r;
- (NSNumber *)number;

- (BOOL) isZero;
+ (double)parseRealString:(const uint8_t *)bytes length:(NSInteger)len;

@end
