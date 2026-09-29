//
//  UMASN1Enumerated.m
//  ulibasn1
//
//  Created by Andreas Fink on 04/07/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMASN1Enumerated.h>

@implementation UMASN1Enumerated

- (UMASN1Enumerated *)init
{
    return [self initWithValue:0];
}

- (void)setEnumDefinition
{
    /* this is overridden normally */
    /* this metod should _enumDefinition to a dictionary stringValue -> @(number) */
}

- (UMASN1Enumerated *)initWithValue:(int64_t)i
{
    self = [super init];
    if(self)
    {
        [self setEnumDefinition];
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_enumerated;
        [self setValue:i];
    }
    return self;
}

- (UMASN1Enumerated *)initWithString:(NSString *)s
{
    self = [super init];
    if(self)
    {
        [self setEnumDefinition];
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_enumerated;
        [self setString:s];
    }
    return self;
}

- (void)setString:(NSString *)s
{
    NSArray *allKeys = [_enumDefinition allKeys];
    for(NSString *key in allKeys)
    {
        NSInteger intVal = [_enumDefinition[key] integerValue];
        if([s isEqualToString:key])
        {
            [self setValue:intVal];
            return;
        }
        NSString *s2 = [NSString stringWithFormat:@"%@ (%ld)",key,(long )intVal];
        if([s2 isEqualToString:key])
        {
            [self setValue:intVal];
            return;
        }
    }
    [self setValue: [s integerValue]];
}

- (NSString *)stringValue
{
    NSArray *allKeys = [_enumDefinition allKeys];
    for(NSString *key in allKeys)
    {
        NSInteger intVal = [_enumDefinition[key] integerValue];
        if (self.value == intVal)
        {
            NSString *s2 = [NSString stringWithFormat:@"%@ (%ld)",key,(long )intVal];
            return s2;
        }
    }
    return [NSString stringWithFormat:@"undefined (%ld)",(long)self.value];
}

- (void)processBeforeEncode
{
    [super processBeforeEncode];
}


+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_enumerated;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_enumerated;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_enumerated))
    {
        return YES;
    }
    return NO;
}

- (id) objectValue
{
    return [self stringValue];
}

@end
