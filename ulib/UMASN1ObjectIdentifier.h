//
//  UMASN1ObjectIdentifier.h
//  ulibasn1
//
//  Created by Andreas Fink on 20/04/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1ObjectPrimitive.h>

@interface UMASN1ObjectIdentifier : UMASN1ObjectPrimitive

- (UMASN1ObjectIdentifier *)initWithValue:(NSData *)d;
- (UMASN1ObjectIdentifier *)initWithString:(NSString *)s; /* this expects a hex string of the OID bytes */
- (UMASN1ObjectIdentifier *)initWithOIDString:(NSString *)s; /* this expects a string like "2.16.756.5.40" */
- (NSString *)oidString;
- (NSData *)value;

@end
