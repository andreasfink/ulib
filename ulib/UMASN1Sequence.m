//
//  UMASN1Sequence.m
//  ulibasn1
//
//  Created by Andreas Fink on 08.09.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMASN1Sequence.h>
#import <ulib/UMASN1UTF8String.h>
#import <ulib/UMASN1Integer.h>
#import <ulib/UMASN1OctetString.h>
#import <ulib/UMASN1Null.h>
#import <ulib/UMASN1Real.h>
#import <ulib/UMASN1Boolean.h>

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
        _asn1_tag.tagClass = UMASN1Class_Universal;
        _asn1_tag.tagNumber = UMASN1Primitive_sequence;
        _asn1_tag.isConstructed = YES;
		[self setValues:arr];
    }
    return self;
}

- (NSArray *) values
{
    return [NSArray arrayWithArray:_asn1_list];
}

- (void) setValues:(NSArray *)arr
{
    _asn1_list = [arr mutableCopy];
}

- (void) appendValue:(UMASN1Object *)o
{
    if(_asn1_list == 0)
    {
        _asn1_list = [[NSMutableArray alloc]init];
    }
    [_asn1_list addObject:o];
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

- (void)addObject:(UMASN1Object *)o
{
    if(_asn1_list == 0)
    {
        _asn1_list = [[NSMutableArray alloc]init];
    }
    if(o)
    {
        [_asn1_list addObject:o];
    }
}

- (void)addObject:(NSObject *)o1 withContentSpecificTag:(uint64_t)tag
{
    if(_asn1_list == 0)
    {
        _asn1_list = [[NSMutableArray alloc]init];
    }
    if([o1 isKindOfClass:[UMASN1Object class]])
    {
        UMASN1Object *o = (UMASN1Object *)o1;
        o.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        o.asn1_tag.tagNumber = tag;
        [_asn1_list addObject:o];
    }
    else if([o1 isKindOfClass:[NSString class]])
    {
        UMASN1UTF8String *o = [[UMASN1UTF8String alloc]initWithString:(NSString *)o1];
        o.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        o.asn1_tag.tagNumber = tag;
        [_asn1_list addObject:o];
    }
    else if([o1 isKindOfClass:[NSNumber class]])
    {
        UMASN1Integer *o = [[UMASN1Integer alloc]initWithNumber:(NSNumber *)o1];
        o.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        o.asn1_tag.tagNumber = tag;
        [_asn1_list addObject:o];
    }
    else
    {
        NSString *s = [NSString stringWithFormat:@"ASN1 Sequence: Dont know how to add object of type %@",o1];
        @throw([NSException exceptionWithName:@"ASN1_ENCODING_ERROR"
                                       reason:s
                                     userInfo:@{@"backtrace": UMBacktrace(NULL,0) }]);
    }
}

- (void)addNSString:(NSString *)s withContentSpecificTag:(uint64_t)tag
{
    if(s == NULL)
    {
        UMASN1UTF8String *u = [[UMASN1UTF8String alloc] initWithString:s];
        [self addObject:u withContentSpecificTag:tag];
    }
}

- (void)addIntegerNumber:(NSNumber *)n withContentSpecificTag:(int64_t)tag
{
    if(n)
    {
        UMASN1Integer *i = [[UMASN1Integer alloc] initWithNumber:n];
        [self addObject:i withContentSpecificTag:tag];
    }
}


- (void)addRealNumber:(NSNumber *)n withContentSpecificTag:(int64_t)tag
{
    if(n)
    {
        UMASN1Real *r = [[UMASN1Real alloc] initWithNumber:n];
        [self addObject:r withContentSpecificTag:tag];
    }
}

- (void)addBooleanNull:(BOOL)b withContentSpecificTag:(int64_t)tag;
{
    if(b==YES)
    {
        UMASN1Null *n = [[UMASN1Null alloc] init];
        [self addObject:n withContentSpecificTag:tag];
    }
}
@end
