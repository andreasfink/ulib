//
//  UMASN1Length.m
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulibasn1/UMASN1Length.h>


static inline uint8_t grab_byte(NSData *data,NSUInteger *pos, id obj);

static inline uint8_t grab_byte(NSData *data,NSUInteger *pos, id obj)
{
    const uint8_t *bytes = data.bytes;
    NSUInteger len = data.length;
    if(*pos >= len)
    {
        @throw([NSException exceptionWithName:@"ASN1_READ_BEYOND_EOD"
                                       reason:NULL
                                     userInfo:@{
                                                @"sysmsg" : @"reading beyond end of data in length bytes",
                                                @"func": @(__func__),
                                                @"obj" : obj,
                                                @"backtrace": UMBacktrace(NULL,0),
                                                }
                ]);
    }
    uint8_t byte = bytes[(*pos)++];
    return byte;
}


@implementation UMASN1Length

- (void)setLength:(uint64_t)newLength
{
    self.undefinedLength = NO;
    length = newLength;
}

- (uint64_t)length
{
    if(undefinedLength)
    {
        return 0;
    }
    return length;
}

- (BOOL) undefinedLength
{
    return undefinedLength;
}

- (void)setUndefinedLength:(BOOL)b
{
    undefinedLength = b;
    if(b)
    {
        length = 0;
    }
}

#if 0
- (void)appendToMutableData:(NSMutableData *)d
{
    uint8_t byte;
    
    if(length < 0x7F)
    {
        /* short form */
        byte = length;
        [d appendBytes:&byte length:1];
    }
    else
    {
        NSUInteger len = length;
        NSUInteger numberOfBytesNeeded = 1;
        while(!(len < (1LL << (numberOfBytesNeeded*8))))
        {
            numberOfBytesNeeded++;
        }
        byte = numberOfBytesNeeded;
        [d appendBytes:&byte length:1];

        while(numberOfBytesNeeded > 0)
        {
            if(numberOfBytesNeeded <=1)
            {
                byte = len & 0xFF;
            }
            else
            {
                byte = ((len >> (numberOfBytesNeeded * 8)) & 0xFF );
            }
            [d appendBytes:&byte length:1];
            numberOfBytesNeeded--;
        }
    }
}
#endif

- (UMASN1Length *)initWithBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context
{
    self = [super init];
    if(self)
    {
        uint8_t byte = grab_byte(data,pos,self);
        if (byte == 0x80)
        {
            /* indefinitive form */
            length = 0;
            undefinedLength = YES;
        }
        else if (byte < 0x80)
        {
            /* short form */
            length = byte;
            undefinedLength = NO;
        }
        else
        {
            int count = byte & 0x7F;
            length = 0;
            while(count > 0)
            {
                byte = grab_byte(data,pos,self);
                length = (length << 8) | byte;
                count--;
            }
        }
    }
    return self;
}

- (NSString *)description
{
    if([self undefinedLength])
    {
        return @"UNDEFINED_LENGTH";
    }
    else
    {
        return [NSString stringWithFormat:@"LENGTH=%ld",(long)self.length];
    }
}


- (NSData *)berEncodedEndOfData
{
    /* 
        ITU X.690  (07/2002):
        8.1.5 End-of-contents octets
        The end-of-contents octets shall be present if the length
        is encoded as specified in 8.1.3.6, otherwise they shall not be present.
    */

    if(undefinedLength)
    {
        unsigned char byte[2] = { 0x00, 0x00 };
        return [NSData dataWithBytes:&byte length:2];
    }
    return [[NSData alloc]init];
}

- (NSData *)berEncoded
{
    unsigned char bytes[16];

    if(undefinedLength)
    {
        return [NSData dataWithBytes:&bytes length:0];
    }

    NSMutableData *data = [[NSMutableData alloc]init];
    uint64_t i = length;
    
    if(i < 128) /* 7 bits */
    {
        bytes[0] = i;
        [data appendBytes:&bytes length:1];
    }
    else if(i < (1LL << 8)) /* 1x8 bits */
    {
        bytes[0] = 1 | 0x80;
        bytes[1] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:2];
    }
    else if(i < (1LL << 16)) /* 2x8 bits */
    {
        bytes[0] = 2 | 0x80;
        bytes[1] = (i >> 8) & 0xFF;
        bytes[2] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:3];
    }
    else if(i < (1LL << 24)) /* 3 x 8 bits */
    {
        bytes[0] = 3 | 0x80;
        bytes[1] = (i >> 16) & 0xFF;
        bytes[2] = (i >> 8) & 0xFF;
        bytes[3] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:4];
    }
    else if(i < (1LL << 32)) /* 4 x 8 bits */
    {
        bytes[0] = 4 | 0x80;
        bytes[1] = (i >> 24) & 0xFF;
        bytes[2] = (i >> 16) & 0xFF;
        bytes[3] = (i >> 8) & 0xFF;
        bytes[4] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:5];
    }
    else if(i < (1LL << 40)) /* 5 x 8 bits */
    {
        bytes[0] = 5 | 0x80;
        bytes[1] = (i >> 32) & 0xFF;
        bytes[2] = (i >> 24) & 0xFF;
        bytes[3] = (i >> 16) & 0xFF;
        bytes[4] = (i >> 8) & 0xFF;
        bytes[5] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:6];
    }
    else if(i < (1LL << 48)) /* 6x 8 bits */
    {
        bytes[0] = 6 | 0x80;
        bytes[1] = (i >> 40) & 0xFF;
        bytes[2] = (i >> 32) & 0xFF;
        bytes[3] = (i >> 24) & 0xFF;
        bytes[4] = (i >> 16) & 0xFF;
        bytes[5] = (i >> 8) & 0xFF;
        bytes[6] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:7];
    }
    else if(i < (1LL << 56)) /* 7 x 8 bits */
    {
        bytes[0] = 7 | 0x80;
        bytes[1] = (i >> 48) & 0xFF;
        bytes[2] = (i >> 40) & 0xFF;
        bytes[3] = (i >> 32) & 0xFF;
        bytes[4] = (i >> 24) & 0xFF;
        bytes[5] = (i >> 16) & 0xFF;
        bytes[6] = (i >> 8) & 0xFF;
        bytes[7] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:8];
    }
    else /* 8 x 8 bits */
    {
        bytes[0] = 8 | 0x80;
        bytes[1] = (i >> 56) & 0xFF;
        bytes[2] = (i >> 48) & 0xFF;
        bytes[3] = (i >> 40) & 0xFF;
        bytes[4] = (i >> 32) & 0xFF;
        bytes[5] = (i >> 24) & 0xFF;
        bytes[6] = (i >> 16) & 0xFF;
        bytes[7] = (i >> 8) & 0xFF;
        bytes[8] = (i >> 0) & 0xFF;
        [data appendBytes:&bytes length:9];
    }
    return data;
}
@end
