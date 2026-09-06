//
//  UMASN1Enumerated.h
//  ulibasn1
//
//  Created by Andreas Fink on 04/07/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1Integer.h>

@interface UMASN1Enumerated : UMASN1Integer
{
    NSDictionary *_enumDefinition;
}

@property(readwrite,strong)     NSDictionary *enumDefinition;

- (void)setEnumDefinition;

/*
this is overridden normally with a method doing something like this:

    _enumDefinition  = @ {
        @"stringValue1" : @(1),
        @"stringValue2" : @(2),
}

*/

- (UMASN1Enumerated *)initWithString:(NSString *)s;
- (void)setString:(NSString *)s;
- (NSString *)stringValue;
@end
