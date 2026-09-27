//
//  UMASN1Integer.m
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulib/UMASN1Integer.h>
#import <ulib/UMASN1Tag.h>
#import <ulib/UMASN1Length.h>

@implementation UMASN1Integer

- (UMASN1Integer *)init
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_integer;
        [self setValue:0];
    }
    return self;
}

- (UMASN1Integer *)initWithValue:(int64_t)i
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_integer;
        [self setValue:i];
    }
    return self;
}

- (UMASN1Integer *)initWithNumber:(NSNumber *)num
{
    if(num == NULL)
    {
        return NULL;
    }
    long long ull = [num longLongValue];
    return [self initWithValue:ull];
}

- (NSNumber *)number;
{
    NSNumber *n = @(self.value);
    return n;
}

- (UMASN1Integer *)initWithString:(NSString *)s
{
    return [self initWithValue:(int64_t)[s integerValue]];
}



/* 8.3 Encoding of an integer value
 8.3.2 If the contents octets of an integer value encoding consist of more
 than one octet, then the bits of the first octet
 and bit 8 of the second octet:
 a) shall not all be ones; and
 b) shall not all be zero.
 NOTE – These rules ensure that an integer value is always encoded in the 
 smallest possible number of octets.
 8.3.3 The contents octets shall be a two's complement binary number
 equal to the integer value, and consisting of bits 8 to 1 of the first octet, followed by bits 8 to 1 of the second octet, followed by bits 8 to 1 of each octet in turn up to and including the last octet of the contents octets.
 8.4
 NOTE – The value of a two's complement binary number is derived by numbering the bits in the contents octets, starting with bit 1 of the last octet as bit zero and ending the numbering with bit 8 of the first octet. Each bit is assigned a numerical value of 2N, where N is its position in the above numbering sequence. The value of the two's complement binary number is obtained by summing the numerical values assigned to each bit for those bits which are set to one, excluding bit 8 of the first octet, and then reducing this value by the numerical value assigned to bit 8 of the first octet if that bit is set to one.
*/

- (int64_t)value
{
    uint8_t buf[8];
    if(self.asn1_data==NULL)
    {
        return 0;
    }
    if(([self.asn1_data length]<1) ||  ([self.asn1_data length]> 8))
    {
        return 0;
    }
    uint8_t *bytes = (uint8_t *)self.asn1_data.bytes;
    if(*bytes & 0x80)
    {
        memset(buf,0xFF,sizeof(buf));
    }
    else
    {
        memset(buf,0x00,sizeof(buf));
    }
    size_t startpos = 8 - self.asn1_data.length;
    memcpy(&buf[startpos],self.asn1_data.bytes,self.asn1_data.length);
    
    uint64_t v = 0;
    v = v | (((uint64_t)buf[0]) <<  56);
    v = v | (((uint64_t)buf[1]) <<  48);
    v = v | (((uint64_t)buf[2]) <<  40);
    v = v | (((uint64_t)buf[3]) <<  32);
    v = v | (((uint64_t)buf[4]) <<  24);
    v = v | (((uint64_t)buf[5]) <<  16);
    v = v | (((uint64_t)buf[6]) <<  8);
    v = v | (((uint64_t)buf[7]) <<  0);
    return (int64_t)v;
}

- (void)setValue:(int64_t)val
{
    self.asn1_data = [UMASN1Integer packedInteger:val];
}

- (void)processBeforeEncode
{
    [super processBeforeEncode];
}

- (NSString *)objectName
{
    return @"Integer";
}

-(id) objectValue
{
    return @([self value]);
}


+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_integer;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_integer;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_integer))
    {
        return YES;
    }
    return NO;
}

+(NSData *)packedInteger:(int64_t)val
{
    uint64_t v = (uint64_t)val;
    uint8_t buf[8];
    buf[0] = 0xFF & (v >> 56);
    buf[1] = 0xFF & (v >> 48);
    buf[2] = 0xFF & (v >> 40);
    buf[3] = 0xFF & (v >> 32);
    buf[4] = 0xFF & (v >> 24);
    buf[5] = 0xFF & (v >> 16);
    buf[6] = 0xFF & (v >> 8);
    buf[7] = 0xFF & (v >> 0);

    uint8_t *start = &buf[0];
    uint8_t *end = start + sizeof(buf);
    if(val == 0)
    {
        uint8_t byte = 0;
        return [NSData dataWithBytes:&byte length:1];
    }
    else if(val == -1)
    {
        uint8_t byte = 0xFF;
        return [NSData dataWithBytes:&byte length:1];
    }
    /* Compute the number of superfluous leading bytes */
    for(;start<end;start++)
    {
        /*
         * If the contents octets of an integer value encoding
         * consist of more than one octet, then the bits of the
         * first octet and bit 8 of the second octet:
         * a) shall not all be ones; and
         * b) shall not all be zero.
         */
        switch(*start)
        {
            case 0x00: if((start[1] & 0x80) == 0)
                continue;
                break;
            case 0xff: if((start[1] & 0x80))
                continue;
                break;
        }
        break;
    }
    /* Remove leading superfluous bytes from the integer */
    NSData *d = [NSData dataWithBytes:start length:end-start];
    return d;
}
@end
