//
//  UMASN1Set.m
//  ulibasn1
//
//  Created by Andreas Fink on 08.09.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1Set.h>

@implementation UMASN1Set

- (UMASN1Set *)init
{
    return [self initWithValues:@[]];
}

- (UMASN1Set *)initWithValues:(NSArray *)arr
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsConstructed];
       // asn1_tag.tagNumber = UMASN1Primitive_set;
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

- (NSString *)objectName
{
    return @"Set";
}

+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_set_of;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_set_of;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_set_of))
    {
        return YES;
    }
    return NO;
}
@end
