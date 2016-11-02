//
//  NSData+UMHTTP.m
//  ulib
//
//  Created by Andreas Fink on 02.11.16.
//  Copyright © 2016 Andreas Fink. All rights reserved.
//

#import "NSData+UMHTTP.h"

@implementation NSData (UMHTTP)

- (NSString *)encodeBase64
{
    return [self base64EncodedStringWithOptions:0];
}

@end
