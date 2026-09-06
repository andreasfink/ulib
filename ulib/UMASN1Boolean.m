//
//  UMASN1Boolean.m
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulib/UMASN1Boolean.h>
#import <ulib/UMASN1Object.h>
#import <ulib/UMASN1Tag.h>
#import <ulib/UMASN1Length.h>


@implementation UMASN1Boolean

- (UMASN1Boolean *)init
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_boolean;
    }
    return self;
}


- (UMASN1Boolean *)initWithValue:(BOOL)v
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_boolean;
        [self setValue:v];
    }
    return self;
}

- (UMASN1Boolean *)initAsYes
{
    return [self initWithValue:YES];
}

- (UMASN1Boolean *)initAsNo
{
    return [self initWithValue:NO];
}

- (void)setValue:(BOOL)v
{
    uint8_t byte;
    if(v)
    {
        byte = 0xFF;
    }
    else
    {
        byte = 0x00;
    }
    self.asn1_data = [NSData dataWithBytes:&byte length:1];
    [self.asn1_length setLength:1];
}


-(BOOL)isTrue
{
    return ! [self isFalse];
}

- (BOOL)isFalse
{
    if((*(uint8_t *)self.asn1_data.bytes) == 0x00)
    {
        return YES;
    }
    return NO;
}

- (void)processBeforeEncode
{
    [super processBeforeEncode];
}

- (NSString *)objectName
{
    return @"END_OF_CONTENTS";
}

- (id) objectValue
{
    if([self isTrue])
        return @YES;
    return @NO;
}

+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_boolean;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_boolean;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_boolean))
    {
        return YES;
    }
    return NO;
}


@end
