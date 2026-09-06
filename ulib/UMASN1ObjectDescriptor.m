//
//  UMASN1ObjectDescriptor.m
//  ulibasn1
//
//  Created by Andreas Fink on 20/04/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1ObjectDescriptor.h>

@implementation UMASN1ObjectDescriptor

- (void)processBeforeEncode
{
    [super processBeforeEncode];
    self.asn1_tag.tagClass = UMASN1Class_Universal;
    self.asn1_tag.tagNumber = UMASN1Primitive_object_descriptor;
}

+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_object_descriptor;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_object_descriptor;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_object_descriptor))
    {
        return YES;
    }
    return NO;
}

@end
