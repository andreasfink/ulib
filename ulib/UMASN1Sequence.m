//
//  UMASN1Sequence.m
//  ulibasn1
//
//  Created by Andreas Fink on 08.09.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMASN1Sequence.h>

@implementation UMASN1Sequence

- (UMASN1Sequence *)init
{
    return [self initWithValues:@[]];
}

- (UMASN1Sequence *)initWithValues:(NSArray *)arr
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        self.asn1_tag.tagNumber = UMASN1Primitive_sequence;
        self.asn1_tag.isConstructed = YES;
		[self setValues:arr];
    }
    return self;
}

- (NSArray *) values
{
    return [NSArray arrayWithArray:self.asn1_list];
}

- (void) setValues:(NSArray *)arr
{
    self.asn1_list = [arr mutableCopy];
}

- (void) appendValue:(UMASN1Object *)o
{
    [self.asn1_list addObject:o];
}


- (void)processBeforeEncode
{
    [super processBeforeEncode];
    [self.asn1_tag setTagIsConstructed];
}

- (NSString *)objectName
{
    return @"Sequence";
}

+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_sequence;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_sequence;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_sequence))
    {
        return YES;
    }
    return NO;
}

@end
