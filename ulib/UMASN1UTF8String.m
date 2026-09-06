//
//  UMASN1UTF8String.m
//  ulibasn1
//
//  Created by Andreas Fink on 08.09.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1UTF8String.h>
#import <ulibasn1/UMASN1Tag.h>

@implementation UMASN1UTF8String


- (UMASN1UTF8String *)init
{
    return [self initWithValue:@""];
}

- (UMASN1UTF8String *)initWithValue:(NSString *)s
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_UTF8String;
        self.value =s;
    }
    return self;
}

- (UMASN1UTF8String *)initWithString:(NSString *)s
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_UTF8String;
        self.value =s;
    }
    return self;
}

- (NSString *) value
{
    NSString *s = [[NSString alloc] initWithData:self.asn1_data encoding:NSUTF8StringEncoding];
    return s;
}

- (NSString *) stringValue
{
    NSString *s = [[NSString alloc] initWithData:self.asn1_data encoding:NSUTF8StringEncoding];
    return s;
}


- (void) setValue:(NSString *)s
{
    self.asn1_data = [s dataUsingEncoding:NSUTF8StringEncoding];
    self.asn1_length.length = self.asn1_data.length;
}

- (void) setString:(NSString *)s
{
    self.asn1_data = [s dataUsingEncoding:NSUTF8StringEncoding];
    self.asn1_length.length = self.asn1_data.length;
}


- (NSString *)objectName
{
    return @"UTF8String";
}

- (id) objectValue
{
    return [[NSString alloc]initWithData:self.asn1_data encoding:NSUTF8StringEncoding];
}

+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_UTF8String;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_UTF8String;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_UTF8String))
    {
        return YES;
    }
    return NO;
}

@end
