//
//  UMASN1BitString.m
//  ulibasn1
//
//  Created by Andreas Fink on 03.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulibasn1/UMASN1BitString.h>

@implementation UMASN1BitString

- (UMASN1BitString *)init
{
    self = [self initWithValue:[NSData data] bitcount:0];
    [self setBitStringDefinition];
    return self;
}

- (void)setBitStringDefinition
{
    /* this is overridden normally */
    /* this metod should _bitStringDefintionBitToName to a dictionary stringValue -> @(number) */
    /* this metod should _bitStringDefintionNameToBt to a dictionary @(number)->stringValue  */
}


- (UMASN1BitString *)initWithValue:(NSData *)d bitcount:(NSInteger)bc
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        [self.asn1_tag setTagIsPrimitive];
        self.asn1_tag.tagNumber = UMASN1Primitive_bitstring;
        [self setValue:d bitcount:bc];
        [self setBitStringDefinition];
    }
    return self;
}

- (NSData *)value
{
    NSData *d = [NSData dataWithBytes:self.asn1_data.bytes+1 length:self.asn1_data.length-1];
    return d;
}

-(NSInteger) bitcount
{
    const uint8_t *bytes = self.asn1_data.bytes;
    NSInteger len = (self.asn1_data.length-1) * 8;
    len  = len - *bytes;
    return len;
}

- (void) setValue:(NSData *)s bitcount:(NSInteger)bc
{
    if(bc==0)
    {
        uint8_t byte = 0;
        self.asn1_data = [NSData dataWithBytes:&byte length:1];
    }
    else
    {
        NSInteger trailing_bits = s.length * 8 - bc;

        if(trailing_bits < 0)
        {
            @throw([NSException exceptionWithName:@"ASN1_BITCOUNT_TOO_LARGE"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"bitcount is larger than supplied bits",
                                                    @"func": @(__func__),
                                                    @"obj" : self,
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);
        }
        if(trailing_bits > 7)
        {
            @throw([NSException exceptionWithName:@"ASN1_BITCOUNT_TOO_SMALL"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"bitcount is too small",
                                                    @"func": @(__func__),
                                                    @"obj" : self,
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);
        }
        uint8_t byte = trailing_bits;
        NSMutableData *d = [NSMutableData dataWithBytes:&byte length:1];
        [d appendData:s];
        self.asn1_data = d;
    }
}

- (void)processBeforeEncode
{
    [super processBeforeEncode];
//    asn1_tag.tagClass = UMASN1Class_Universal;
//    asn1_tag.tagNumber = UMASN1Primitive_bitstring;
}

- (NSString *)objectName
{
    return @"BitString";
}

- (id)objectValue
{
    if(_bitStringDefintionBitToName == NULL)
    {
        [self setBitStringDefinition];
    }
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    dict[@"raw"] =  [self.asn1_data hexString];
    NSInteger totalBits = [self bitcount];
    for(int bit=0; bit<totalBits;bit++)
    {
        NSString *name = @"unknown";
        if(_bitStringDefintionBitToName)
        {
            NSString *n = _bitStringDefintionBitToName[@(bit)];;
            if(n.length > 0)
            {
                name = n;
            }
        }
        NSString *desc = [NSString stringWithFormat:@"%@(%d)",name,bit];
        BOOL value = [self bit:bit];
        dict[desc] =@(value);
    }
    return dict;
}


+ (uint64_t)classTagNumber
{
    return UMASN1Primitive_bitstring;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == UMASN1Primitive_bitstring;
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if((t.tagClass == UMASN1Class_Universal) && (t.tagNumber = UMASN1Primitive_bitstring))
    {
        return YES;
    }
    return NO;
}

- (NSData *)dataExtendedToBit:(NSInteger)bit
{

    NSInteger byteCount = (bit + 8) / 8;
    uint8_t unusedBits = (uint8_t)((byteCount) * 8 - bit -1);

    if(self.asn1_data == NULL)
    {
        NSMutableData *d = [[NSMutableData alloc]init];
        [d appendByte:unusedBits];
        for(NSInteger i=0;i<byteCount;i++)
        {
            [d appendByte:0];
        }
        return d;
    }
    else /*if((byteCount+1) > self.asn1_data.length)*/
    {
        NSMutableData *d = [[NSMutableData alloc]init];
        const uint8_t *b = self.asn1_data.bytes;
        [d appendByte:unusedBits];
        NSInteger i;
        for(i=1;i<self.asn1_data.length;i++)
        {
            [d appendByte:b[i]];
        }
        while(i< (byteCount+1))
        {
            [d appendByte:0];
            i++;
        }
        return d;
    }/*
    else
    {
        return self.asn1_data;
    }*/
}

- (void)extendToBit:(NSInteger)bit
{
    self.asn1_data = [self dataExtendedToBit:bit];
}


- (void)setBit:(NSInteger)bit value:(BOOL)bitValue
{
    [self extendToBit:bit];
    NSInteger bytePos = bit/8;
    NSInteger bitPos = bit % 8;
    NSMutableData *d = [self.asn1_data mutableCopy];
    const uint8_t *b = d.bytes;
    uint8_t val = b[bytePos+1];
    if(bitValue)
    {
        val = val | (1 << (7-bitPos));
    }
    else
    {
        val = val & ~(1 << (7-bitPos));
    }
    [d replaceBytesInRange:NSMakeRange(bytePos+1,1) withBytes:&val length:1];
    self.asn1_data = d;
}


- (void)setBit:(NSInteger)bit
{
    [self setBit:bit value:YES];
}

- (void)clearBit:(NSInteger)bit
{
    [self setBit:bit value:NO];
}

- (BOOL)bit:(NSInteger)bit
{
    NSData *d = [self dataExtendedToBit:bit];
    NSInteger bytePos = bit/8;
    NSInteger bitPos = (bit % 8);
    const uint8_t *b = d.bytes;
    uint8_t val = b[bytePos+1];
    if(val  & (1 << (7-bitPos)))
    {
        return YES;
    }
    return NO;
}

@end
