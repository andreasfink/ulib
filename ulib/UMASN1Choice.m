//
//  UMASN1Choice.m
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.

#import <ulibasn1/UMASN1Choice.h>

@implementation UMASN1Choice

- (UMASN1Choice *)init
{
    self = [super init];
    if(self)
    {
        _asn1_tag.tagClass = UMASN1Class_Universal;
        _asn1_tag.tagNumber = UMASN1Primitive_choice;
    }
    return self;
}


- (NSString *)objectName
{
    return @"Choice";
}

+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_choice;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return YES;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    /* FIXME: check subtypes */
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_bitstring))
    {
        return YES;
    }
    return NO;
}

- (void)cloneFrom:(UMASN1Object *)other
{
    [other processBeforeEncode];
    _asn1_tag.tagNumber = other.asn1_tag.tagNumber;
    _asn1_tag.tagClass = other.asn1_tag.tagClass;
    _asn1_tag.isConstructed = other.asn1_tag.isConstructed;
    if(_asn1_tag.isConstructed)
    {
        _asn1_list = [other.asn1_list copy];
    }
    else
    {
        _asn1_data = [other.asn1_data copy];
    }
}

@end
