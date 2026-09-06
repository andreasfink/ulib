//
//  UMASN1ObjectIdentifier.m
//  ulibasn1
//
//  Created by Andreas Fink on 20/04/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMASN1ObjectIdentifier.h>
#import <ulib/NSString+ulib.h>
#import <ulib/NSMutableString+ulib.h>

@implementation UMASN1ObjectIdentifier

- (void)processBeforeEncode
{
    [super processBeforeEncode];
    self.asn1_tag.tagClass = UMASN1Class_Universal;
    self.asn1_tag.tagNumber = UMASN1Primitive_object_identifier;
}


- (NSString *)objectName
{
    return @"ObjectIdentifier";
}

+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_object_identifier;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_object_identifier;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_object_identifier))
    {
        return YES;
    }
    return NO;
}



- (UMASN1ObjectIdentifier *)initWithValue:(NSData *)d
{
    self = [super init];
    if(self)
    {
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        self.asn1_tag.tagNumber = UMASN1Primitive_object_identifier;
        self.asn1_data = d;
    }
    return self;
}

- (UMASN1ObjectIdentifier *)initWithString:(NSString *)s
{
    return [self initWithValue:[s unhexedData]];
}

- (UMASN1ObjectIdentifier *)initWithOIDString:(NSString *)s
{
    NSArray *a = [s componentsSeparatedByString:@"."];
    if(a.count < 2)
    {
        return NULL;
    }
    int64_t firstVal = [a[0] intValue];
    if((firstVal > 2) || (firstVal <0))
    {
        return NULL;
    }
    int64_t secondVal = [a[1] intValue];
    if(secondVal < 0)
    {
        return NULL;
    }
    if((firstVal < 2) && (secondVal > 39))
    {
        return NULL;
    }


    uint64_t i;
    int idx=1;
    NSMutableData *data = [[NSMutableData alloc]init];

    for(idx=1;idx < a.count;idx++)
    {
        if(idx==1)
        {
            i = firstVal * 40 + secondVal;
        }
        else
        {
            i = [a[idx] intValue];
        }
        /* how many octets do we need ? we limit ourselves to a 64bit integer so we will never need more than 16 */
        unsigned char bytes[16];
        if(i < (1LL << 7)) /* 7 bits */
        {
            bytes[0] = i;
            [data appendBytes:&bytes length:1];
        }
        else if(i < (1LL << 14)) /* 2x 7 bits */
        {
            bytes[0] = ((i >> 7) & 0x7F) | 0x80;
            bytes[1] = ((i >> 0) & 0x7F) | 0x00;
            [data appendBytes:&bytes length:2];
        }
        else if(i < (1LL << 21)) /* 3 x 7 bits */
        {
            bytes[0] = ((i >> 14) & 0x7F) | 0x80;
            bytes[1] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[2] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:3];
        }
        else if(i < (1LL << 28)) /* 4 x 7 bits */
        {
            bytes[0] = ((i >> 21) & 0x7F) | 0x80;
            bytes[1] = ((i >> 14) & 0x7F) | 0x80;
            bytes[2] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[3] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:4];
        }
        else if(i < (1LL << 35)) /* 5 x 7 bits */
        {
            bytes[0] = ((i >> 28) & 0x7F) | 0x80;
            bytes[1] = ((i >> 21) & 0x7F) | 0x80;
            bytes[2] = ((i >> 14) & 0x7F) | 0x80;
            bytes[3] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[4] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:5];
        }
        else if(i < (1LL << 42)) /* 6 x 7 bits */
        {
            bytes[0] = ((i >> 35) & 0x7F) | 0x80;
            bytes[1] = ((i >> 28) & 0x7F) | 0x80;
            bytes[2] = ((i >> 21) & 0x7F) | 0x80;
            bytes[3] = ((i >> 14) & 0x7F) | 0x80;
            bytes[4] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[5] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:6];
        }
        else if(i < (1LL << 49)) /* 7 x 7 bits */
        {
            bytes[0] = ((i >> 42) & 0x7F) | 0x80;
            bytes[1] = ((i >> 35) & 0x7F) | 0x80;
            bytes[2] = ((i >> 28) & 0x7F) | 0x80;
            bytes[3] = ((i >> 21) & 0x7F) | 0x80;
            bytes[4] = ((i >> 14) & 0x7F) | 0x80;
            bytes[5] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[6] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:7];
        }
        else if(i < (1LL << 56)) /* 8 x 7 bits */
        {
            bytes[0] = ((i >> 49) & 0x7F) | 0x80;
            bytes[1] = ((i >> 42) & 0x7F) | 0x80;
            bytes[2] = ((i >> 35) & 0x7F) | 0x80;
            bytes[3] = ((i >> 28) & 0x7F) | 0x80;
            bytes[4] = ((i >> 21) & 0x7F) | 0x80;
            bytes[5] = ((i >> 14) & 0x7F) | 0x80;
            bytes[6] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[7] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:8];
        }
        else if(i < (1LL << 63)) /* 9 x 7 bits */
        {
            bytes[0] = ((i >> 56) & 0x7F) | 0x80;
            bytes[1] = ((i >> 49) & 0x7F) | 0x80;
            bytes[2] = ((i >> 42) & 0x7F) | 0x80;
            bytes[3] = ((i >> 35) & 0x7F) | 0x80;
            bytes[4] = ((i >> 28) & 0x7F) | 0x80;
            bytes[5] = ((i >> 21) & 0x7F) | 0x80;
            bytes[6] = ((i >> 14) & 0x7F) | 0x80;
            bytes[7] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[8] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:9];
        }
        else
        {
            bytes[0] = ((i >> 63) & 0x7F) | 0x80;
            bytes[1] = ((i >> 56) & 0x7F) | 0x80;
            bytes[2] = ((i >> 49) & 0x7F) | 0x80;
            bytes[3] = ((i >> 42) & 0x7F) | 0x80;
            bytes[4] = ((i >> 35) & 0x7F) | 0x80;
            bytes[5] = ((i >> 28) & 0x7F) | 0x80;
            bytes[6] = ((i >> 21) & 0x7F) | 0x80;
            bytes[7] = ((i >> 14) & 0x7F) | 0x80;
            bytes[8] = ((i >> 7) & 0x7F)  | 0x80;
            bytes[9] =  (i >> 0) & 0x7F;
            [data appendBytes:&bytes length:10];
        }
    }
    return [self initWithValue:data];
}

- (NSData *)value
{
    return [self.asn1_data copy];
}


- (int64_t)grabInteger:(const uint8_t *)data atPosition:(NSUInteger *)posPtr max:(NSUInteger)maxlen
{
    NSUInteger pos = *posPtr;
    if(pos >= maxlen)
    {
        return -1;
    }
    int64_t value = 0;

    int bit7=0;
    do
    {
        int byte = data[pos++];
        bit7 = byte & 0x80;
        value = value << 7;
        value = value | (byte & 0x7F);
    } while ((bit7 != 0) && (pos<maxlen));
    *posPtr = pos;
    return value;
}

- (NSString *)oidString
{
    NSMutableString *s = [[NSMutableString alloc]init];
    const uint8_t *bytes = [self.asn1_data bytes];
    NSUInteger len = [self.asn1_data length];

    NSUInteger pos = 0;
    int64_t value0;
    int64_t value1 = [self grabInteger:bytes atPosition:&pos max:len];

    if(value1 < 40)
    {
        value0 = 0;
        value1 = value1 - 0;
    }
    else if(value1 < 80)
    {
        value0 = 1;
        value1 = value1 - 40;
    }
    else
    {
        value0 = 2;
        value1 = value1 - 80;
    }

    [s appendFormat:@"%lld.%lld",( long long)value0,(long long)value1];

    int64_t valueN = [self grabInteger:bytes atPosition:&pos max:len];
    while(valueN >= 0)
    {
        [s appendFormat:@".%lld",(long long)valueN];
        valueN = [self grabInteger:bytes atPosition:&pos max:len];
    }
    return s;
}
@end
