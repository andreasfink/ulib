//  UMASN1Real.m
//  ulibasn1
//
//  Created by Andreas Fink on 06/09/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMASN1Real.h>
#import <ulib/UMUtil.h>
#import <ulib/NSData+ulib.h>
#import <ulib/NSMutableData+ulib.h>

#include <math.h>

@implementation UMASN1Real

- (UMASN1Real *)initWithNumber:(NSNumber *)r
{
    return [self initWithValue:r.doubleValue];
}

- (UMASN1Real *)initWithValue:(double)r
{
    self = [super init];
    if(self)
    {
        self.asn1_tag.tagClass = UMASN1Class_Universal;
        self.asn1_tag.tagNumber = UMASN1Primitive_real;
        [self.asn1_tag setTagIsPrimitive];
        [self setValue:r];
    }
    return self;
}

- (NSNumber *)number;
{
    NSNumber *n = @(self.value);
    return n;
}

- (void) setIsPlusInfinity:(BOOL)b
{
    _isPlusInfinity = b;
    _isMinusInfinity = NO;
    _isNotANumber = NO;
    _isMinusZero = NO;
    _isZero = NO;
    _internalValue = INFINITY;
    [self privateEncodeValue];
}


- (BOOL)isPlusInfinity
{
    return _isPlusInfinity;
}

- (void) setIsMinusInfinity:(BOOL)b
{
    _isPlusInfinity = NO;
    _isMinusInfinity = b;
    _isNotANumber = NO;
    _isMinusZero = NO;
    _isZero = NO;
    _internalValue = -INFINITY;
    [self privateEncodeValue];
}

- (BOOL)isMinusInfinity
{
    return _isMinusInfinity;
}

- (void) setIsNotANumber:(BOOL)b
{
    _isPlusInfinity = NO;
    _isMinusInfinity = NO;
    _isNotANumber = b;
    _isMinusZero = NO;
    _isZero = NO;
    _internalValue = NAN;
    [self privateEncodeValue];
}

- (BOOL)isNotANumber
{
    return _isNotANumber;
}



- (void) setIsMinusZero:(BOOL)b
{
    _isPlusInfinity = NO;
    _isMinusInfinity = NO;
    _isNotANumber = NO;
    _isMinusZero = b;
    _isZero = NO;
    _internalValue = -0.00;
    [self privateEncodeValue];
}

- (BOOL)isMinusZero
{
    return _isMinusZero;
}

- (void) setIsZero:(BOOL)b
{
    _isPlusInfinity = NO;
    _isMinusInfinity = NO;
    _isNotANumber = NO;
    _isMinusZero = NO;
    _isZero= b;
    _internalValue = 0.00;
    [self privateEncodeValue];
}

- (BOOL)isZero
{
    return _isZero;
}

- (double) value
{
    if(_isPlusInfinity)
    {
        return INFINITY;
    }
    if(_isMinusInfinity)
    {
        return -INFINITY;
    }
    if(_isNotANumber)
    {
        return NAN;
    }
    if(_isMinusZero)
    {
        return -0.00;
    }
    if(_isZero)
    {
        return 0.00;
    }
    return _internalValue;
}

- (void) setValue:(double)d
{
    _isZero=NO;
    _isMinusZero=NO;
    _isPlusInfinity=NO;
    _isMinusInfinity=NO;
    _isNotANumber=NO;
    _internalValue = d;
    if(isnan(d))
    {
        self.isNotANumber = YES;
    }
    else if(!isfinite(d))
    {
        if(copysign(1.0, d) < 0.0)
        {
            self.isMinusInfinity = YES;
        }
        else
        {
            self.isPlusInfinity = YES;
        }
    }
    else if(ilogb(d) <= -INT_MAX)
    {
        if(copysign(1.0, d) < 0.0)
        {
            self.isMinusZero = YES;
        }
        else
        {
            self.isZero = YES;
        }
    }
    [self privateEncodeValue];
}


#define LEADING_SPACE_SECTION   0
#define MAIN_DIGITS_SECTION     1
#define FRACTIONS_SECTION       2
#define EXPONENT_SECTION        3
#define EXPONENT_DIGITS_SECTION 4

+ (double)parseRealString:(const uint8_t *)bytes length:(NSInteger)len
{
    /* decoder for ISO 6093 NR1/NR2/NR3 */
    int section = LEADING_SPACE_SECTION;

    double  value = 0;
    BOOL    value_is_negative = NO;
    int     exponent = 0;
    BOOL    exponen_is_negative = NO;
    double  fractionFactor = 1;
    
    for(NSInteger i=0;i<len;i++)
    {
        char c = bytes[i];
        if(section==LEADING_SPACE_SECTION)
        {
            if(c==' ')
            {
                /* skipping spaces in front */
                continue;
            }
            if(c=='+')
            {
                section = MAIN_DIGITS_SECTION;
                value_is_negative = NO;
                continue;
            }
            if(c=='-')
            {
                section = MAIN_DIGITS_SECTION;
                value_is_negative = YES;
                continue;
            }
            if((c=='.') && (c==','))
            {
                section = FRACTIONS_SECTION;
                continue;
            }
            if((c>='1') && (c<='9'))
            {
                section = MAIN_DIGITS_SECTION;
                value = c - '0';
                continue;
            }
            @throw([NSException exceptionWithName:@"INVALID_CHAR"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : [NSString stringWithFormat:@"invalid character '%c' in NR1 format",c],
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0),
                                                    }
                    ]);
        }
        else if(section==MAIN_DIGITS_SECTION)
        {
            if((c>='1') && (c<='9'))
            {
                value = value * 10;
                value = value + (c - '0');
                continue;
            }
            if(c=='E')
            {
                section = EXPONENT_SECTION;
                continue;
            }
            if((c=='.') && (c==','))
            {
                section = FRACTIONS_SECTION;
                continue;
            }
            @throw([NSException exceptionWithName:@"UNEXPECTED_CHAR"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : [NSString stringWithFormat:@"unexpected character '%c' in NR1 format",c],
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0),
                                                    }
                    ]);
        }
        else if(section==FRACTIONS_SECTION)
        {
            if((c>='1') && (c<='9'))
            {
                fractionFactor = fractionFactor / 10;
                value = value + ((c - '0') * fractionFactor);
                continue;
            }
            if(c=='E')
            {
                section = EXPONENT_SECTION;
                continue;
            }
            @throw([NSException exceptionWithName:@"UNEXPECTED_CHAR"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : [NSString stringWithFormat:@"unexpected character '%c' in NR1 format",c],
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0),
                                                    }
                    ]);
        }
        else if(section==EXPONENT_SECTION)
        {
            if((c>='1') && (c<='9'))
            {
                exponent = (c - '0');
                section = EXPONENT_DIGITS_SECTION;
                continue;
            }
            else if(c=='+')
            {
                section = EXPONENT_DIGITS_SECTION;
                continue;
            }
            else if(c=='-')
            {
                exponen_is_negative = YES;
                section = EXPONENT_DIGITS_SECTION;
                continue;
            }
            @throw([NSException exceptionWithName:@"UNEXPECTED_CHAR"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : [NSString stringWithFormat:@"unexpected character '%c' in exponent section",c],
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);
        }
        else if(section==EXPONENT_DIGITS_SECTION)
        {
            if((c>='1') && (c<='9'))
            {
                exponent = exponent * 10 + (c - '0');
                section = EXPONENT_DIGITS_SECTION;
                continue;
            }
            @throw([NSException exceptionWithName:@"UNEXPECTED_CHAR"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : [NSString stringWithFormat:@"unexpected character '%c' in exponent digit section",c],
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);
        }
    }
    if(value_is_negative)
    {
        value = -value;
    }
    if(exponen_is_negative)
    {
        exponent = -exponent;
    }
    return value * pow(10,exponent);
}

- (NSString *)objectName
{
    return @"Real";
}

- (id) objectValue
{
    return @(self.value);
}


- (void)processBeforeEncode
{
    [super processBeforeEncode];
}

- (void)privateEncodeValue
{
    [_asn1_tag setTagIsPrimitive];
    
    if(_isZero)
    {
        _asn1_data = [NSData data];
    }
    else if(_isPlusInfinity)
    {
        uint8_t byte = 0x40;
        _asn1_data = [NSData dataWithBytes:&byte length:1];
    }
    else if(_isMinusInfinity)
    {
        uint8_t byte = 0x41;
        _asn1_data = [NSData dataWithBytes:&byte length:1];
    }
    else if(_isNotANumber)
    {
        uint8_t byte = 0x42;
        _asn1_data = [NSData dataWithBytes:&byte length:1];
    }
    else if(_isMinusZero)
    {
        uint8_t byte = 0x43;
        _asn1_data = [NSData dataWithBytes:&byte length:1];
    }
    else
    {
        /*
         * Assume IEEE 754 floating point: standard 64 bit double.
         * [1 bit sign]  [11 bits exponent]  [52 bits mantissa]
         */
        
        double test = -0.0;
        int float_big_endian = *(const char *)&test != 0;
        uint8_t buf[16] = {0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF};    /* More than enough for 8-byte dbl_value */
        uint8_t dscr[sizeof(_internalValue)];    /* double value scratch pad */
        /* Assertion guards: won't even compile, if unexpected double size */
 //       char assertion_buffer1[9 - sizeof(_internalValue)];
 //       char assertion_buffer2[sizeof(_internalValue) - 7];
        uint8_t *ptr = buf;
        uint8_t *mstop;        /* Last byte of mantissa */
        unsigned int mval;    /* Value of the last byte of mantissa */
        unsigned int bmsign;    /* binary mask with sign */
        unsigned int buflen;
        unsigned int accum;
        int         expval;

        /*
         * ilogb(+-0) returns -INT_MAX or INT_MIN (platform-dependent)
         * ilogb(+-inf) returns INT_MAX, logb(+-inf) returns +inf
         * ilogb(NaN) returns INT_MIN or INT_MAX (platform-dependent)
         */
        expval = ilogb(_internalValue);
        if((expval <= -INT_MAX) || (expval == INT_MAX))
        {
            /* fpclassify(3) is not portable yet */
            if(isnan(_internalValue) || _isNotANumber)
            {
                uint8_t byte = 0x42;
                _asn1_data = [NSData dataWithBytes:&byte length:1];
            }
            else if(!isfinite(_internalValue) || _isMinusInfinity || _isPlusInfinity)
            {
                if((copysign(1.0, _internalValue) < 0.0) || _isMinusInfinity)
                {
                    uint8_t byte = 0x41; /* MINUS-INFINITY */
                    _asn1_data = [NSData dataWithBytes:&byte length:1];
                }
                else
                {
                    uint8_t byte = 0x40; /* PLUS-INFINITY */
                    _asn1_data = [NSData dataWithBytes:&byte length:1];
                }
            }
            else
            {
                if((copysign(1.0, _internalValue) >= 0.0) || _isZero)
                {
                    /* no content octets: positive zero */
                    _asn1_data = [NSData data];
                }
                else
                {
                    /* Negative zero. #8.5.3, 8.5.9 */
                    uint8_t byte = 0x43; /* NEGATIV ZERO */
                    _asn1_data = [NSData dataWithBytes:&byte length:1];
                }
            }
            return; /* special cases done */
        }

        if(float_big_endian)
        {
            uint8_t *s = ((uint8_t *)&_internalValue) + 1;
            uint8_t *end = ((uint8_t *)&_internalValue) + sizeof(double);
            uint8_t *d;

            bmsign = 0x80 | ((s[-1] >> 1) & 0x40);    /* binary mask & - */
            for(mstop = d = dscr; s < end; d++, s++)
            {
                *d = *s;
                if(*d)
                {
                    mstop = d;
                }
            }
        }
        else
        {
            uint8_t *s = ((uint8_t *)&_internalValue) + sizeof(double) - 2;
            uint8_t *start = ((uint8_t *)&_internalValue);
            uint8_t *d;

            bmsign = 0x80 | ((s[1] >> 1) & 0x40);    /* binary mask & - */
            for(mstop = d = dscr; s >= start; d++, s--)
            {
                *d = *s;
                if(*d)
                {
                    mstop = d;
                }
            }

            /* Remove parts of the exponent, leave mantissa and explicit 1. */
            dscr[0] = 0x10 | (dscr[0] & 0x0f);

            /* Adjust exponent in a very unobvious way */
            expval -= 8 * ((mstop - dscr) + 1) - 4;

            /* This loop ensures DER conformance by forcing mantissa odd: 11.3.1 */
            mval = *mstop;
            if(mval && !(mval & 1))
            {
                int shift_count = 1;
                int ishift;
                uint8_t *mptr;

                /*
                 * Figure out what needs to be done to make mantissa odd.
                 */
                if(!(mval & 0x0f))    /* Speed-up a little */
                {
                    shift_count = 4;
                }
                while(((mval >> shift_count) & 1) == 0)
                {
                    shift_count++;
                }
                ishift = 8 - shift_count;
                accum = 0;

                /* Go over the buffer, shifting it shift_count bits right. */
                for(mptr = dscr; mptr <= mstop; mptr++)
                {
                    mval = *mptr;
                    *mptr = accum | (mval >> shift_count);
                    accum = mval << ishift;
                }

                /* Adjust exponent appropriately. */
                expval += shift_count;
            }

            if(expval < 0)
            {
                if((expval >> 7) == -1)
                {
                    *ptr++ = bmsign | 0x00;
                    *ptr++ = expval;
                }
                else if((expval >> 15) == -1)
                {
                    *ptr++ = bmsign | 0x01;
                    *ptr++ = expval >> 8;
                    *ptr++ = expval;
                }
                else
                {
                    *ptr++ = bmsign | 0x02;
                    *ptr++ = expval >> 16;
                    *ptr++ = expval >> 8;
                    *ptr++ = expval;
                }
            }
            else if(expval <= 0x7f)
            {
                *ptr++ = bmsign | 0x00;
                *ptr++ = expval;
            }
            else if(expval <= 0x7fff)
            {
                *ptr++ = bmsign | 0x01;
                *ptr++ = expval >> 8;
                *ptr++ = expval;
            }
            else
            {
                assert(expval <= 0x7fffff);
                *ptr++ = bmsign | 0x02;
                *ptr++ = expval >> 16;
                *ptr++ = expval >> 8;
                *ptr++ = expval;
            }

            buflen = (unsigned int) (mstop - dscr) + 1;
            memcpy(ptr, dscr, buflen);
            ptr += buflen;
            buflen = (unsigned int)( ptr - buf);
            
            NSMutableData *data = [[NSMutableData alloc]initWithBytes:buf length:buflen];
            _asn1_data = data;

            return;
        }
    }
}

- (UMASN1Real *) processAfterDecodeWithContext:(id)context
{
    const uint8_t *buf = _asn1_data.bytes;
    NSUInteger len     = _asn1_length.length;
    if(len==0)
    {
        self.isZero=YES;
        return self;
    }
    
    uint8_t firstByte  = *buf;
    //uint8_t secondByte = 0;
    //if(_asn1_data.length > 1)
    //{
    //    secondByte = buf[1];
    //}
    
    switch(firstByte & 0xC0)
    {
        case 0x40:
            /* X.690: 8.5.6 a) => 8.5.9 */
            /* "SpecialRealValue" */
        {
            if (firstByte == 0x40)
            {
                self.isPlusInfinity=YES;
                return self;
            }
            else if (firstByte == 0x41)
            {
                self.isMinusInfinity=YES;
                return self;
            }
            else if (firstByte == 0x42)
            {
                self.isNotANumber=YES;
                return self;
            }
            else if (firstByte == 0x43)
            {
                self.isMinusZero=YES;
                return self;
            }
            else
            {
                @throw([NSException exceptionWithName:@"ASN1_REAL_INVALID_DATA"
                                               reason:NULL
                                             userInfo:@{
                    @"sysmsg" : @"real value is special value but not know one",
                    @"func": @(__func__),
                    @"obj":self,
                    @"backtrace": UMBacktrace(NULL,0)
                }]);
            }
            break;
        }
        case 0x00:
        {    /* X.690: 8.5.7 */
            /*
             * Decimal. NR{1,2,3} format from ISO 6093.
             * NR1: [ ]*[+-]?[0-9]+
             * NR2: [ ]*[+-]?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)
             * NR3: [ ]*[+-]?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)[Ee][+-]?[0-9]+
             */
            char *source = 0;
            char *endptr;
            
            if((firstByte == 0) || (firstByte & 0x3C))
            {
                /* Remaining values of bits 6 to 1 are Reserved. */
                @throw([NSException exceptionWithName:@"ASN1_REAL_INVALID_DATA"
                                               reason:NULL
                                             userInfo:@{
                    @"sysmsg" : @"real value is invalid",
                    @"func": @(__func__),
                    @"obj":self,
                    @"backtrace": UMBacktrace(NULL,0)
                }]);
            }
            
            /* 1. By contract, an input buffer should be '\0'-terminated.
             * OCTET STRING decoder ensures that, as is asn_double2REAL().
             * 2. ISO 6093 specifies COMMA as a possible decimal separator.
             * However, strtod() can't always deal with COMMA.
             * So her we fix both by reallocating, copying and fixing.
             */
            NSMutableData *data = [[NSMutableData alloc]init];
            [data appendByte:firstByte];
            for(int i=1;i<len;i++)
            {
                char c = buf[i];
                if(c=='\0')
                {
                    continue;
                }
                if(c==',')
                {
                    c='.';
                }
                [data appendByte:c];
            }
            [data appendByte:'\0'];
            char *bytes2 = (char *)data.bytes;
            source = (char *)&bytes2[1];
            endptr = source;
            _internalValue = strtod(source, &endptr);
            if(*endptr != '\0')
            {
                @throw([NSException exceptionWithName:@"ASN1_REAL_INVALID_DATA"
                                               reason:NULL
                                             userInfo:@{
                    @"sysmsg" : @"real value is inconsistent",
                    @"func": @(__func__),
                    @"obj":self,
                    @"backtrace": UMBacktrace(NULL,0)
                }]);
            }
            break;
        }
        default:
        {
            double          m;
            int32_t         expval;        /* exponent value */
            unsigned int    elen;    /* exponent value length, in octets */
            int             scaleF;
            int             baseF;
            const uint8_t         *ptr;
            const uint8_t         *end;
            int             sign;
            
            switch((firstByte & 0x30) >> 4)
            {
                case 0x00:
                    baseF = 1;  /* base 2 */
                    break;
                case 0x01:
                    baseF = 3;  /* base 8 */
                    break;
                case 0x02:
                    baseF = 4;  /* base 16 */
                    break;
                default:
                {
                    @throw([NSException exceptionWithName:@"ASN1_REAL_INVALID_DATA"
                                                   reason:NULL
                                                 userInfo:@{
                        @"sysmsg" : @"reserved field",
                        @"func": @(__func__),
                        @"obj":self,
                        @"backtrace": UMBacktrace(NULL,0)
                    }]);
                }
                    break;
            }
            sign = (firstByte & 0x40);           /* bit 7 */
            scaleF = (firstByte & 0x0C) >> 2;    /* bits 4 to 3 */
            
            if(len <= 1 + (firstByte & 0x03))
            {
                @throw([NSException exceptionWithName:@"ASN1_REAL_INVALID_DATA"
                                               reason:NULL
                                             userInfo:@{
                    @"sysmsg" : @"invalid length field",
                    @"func": @(__func__),
                    @"obj":self,
                    @"backtrace": UMBacktrace(NULL,0)
                }]);            }
            
            elen = (firstByte & 0x03);    /* bits 2 to 1; 8.5.6.4 */
            if(elen == 0x03)
            {
                /* bits 2 to 1 = 11; 8.5.6.4, case d) */
                elen = buf[1];    /* unsigned binary number */
                if(elen == 0 || len <= (2 + elen))
                {
                    @throw([NSException exceptionWithName:@"ASN1_REAL_INVALID_DATA"
                                                   reason:NULL
                                                 userInfo:@{
                        @"sysmsg" : @"invalid real",
                        @"func": @(__func__),
                        @"obj":self,
                        @"backtrace": UMBacktrace(NULL,0)
                    }]);
                }
                /* FIXME: verify constraints of case d) */
                ptr = &buf[2];
            }
            else
            {
                ptr = &buf[1];
            }
            
            /* Fetch the multibyte exponent */
            expval = (int)(*(int8_t *)ptr);
            if(elen >= sizeof(expval)-1)
            {
                @throw([NSException exceptionWithName:@"ASN1_REAL_INVALID_DATA"
                                               reason:NULL
                                             userInfo:@{
                    @"sysmsg" : @"out of range real",
                    @"func": @(__func__),
                    @"obj":self,
                    @"backtrace": UMBacktrace(NULL,0)
                }]);
            }
            end = ptr + elen + 1;
            for(ptr++; ptr < end; ptr++)
            {
                expval = (expval * 256) + *ptr;
            }
            m = 0.0;    /* Initial mantissa value */
            
            /* Okay, the exponent is here. Now, what about mantissa? */
            end = buf + len;
            for(; ptr < end; ptr++)
            {
                m = ldexp(m, 8) + *ptr;
            }
            /*
             * (S * N * 2^F) * B^E
             * Essentially:
             m = ldexp(m, scaleF) * pow(pow(2, baseF), expval);
             */
            m = ldexp(m, expval * baseF + scaleF);
            _internalValue = sign ? -m : m;
        }
    }
    return self;
}

@end
