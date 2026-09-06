//
//  UMASN1Tag.m
//  ulibasn1
//
//  Created by Andreas Fink on 02.07.14.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1Tag.h>
#import <sys/errno.h>

static inline uint8_t grab_byte(NSData *data,NSUInteger *pos);

static inline uint8_t grab_byte(NSData *data,NSUInteger *pos)
{
    const uint8_t *bytes = data.bytes;
    NSUInteger len = data.length;
    if(*pos >= len)
    {
        @throw([NSException exceptionWithName:@"READ_BEYOND_EOD"
                                       reason:NULL
                                     userInfo:@{
                                                    @"sysmsg" : @"reading beyond end of data in tag bytes",
                                                    @"func": @(__func__)
                                                    }
                ]);
    }
    uint8_t byte = bytes[(*pos)++];
    return byte;
}

@implementation UMASN1Tag


-(BOOL) tagIsPrimitive
{
    return !_isConstructed;
}

- (BOOL)tagIsConstructed
{
    return _isConstructed;
}
   
-(void)setTagIsConstructed
{
    _isConstructed = YES;
}

-(void)setTagIsPrimitive
{
    _isConstructed = NO;
}

/* this only works for tags < 1F */
- (UMASN1Tag *)initWithInteger:(NSInteger)i
{
    self = [super init];
    if(self)
    {
        uint8_t byte = (uint8_t) i;
        switch((byte>>6) & 0x3)
        {
            case 1:
                _tagClass = UMASN1Class_Application;
                break;
            case 2:
                _tagClass = UMASN1Class_ContextSpecific;
                break;
            case 3:
                _tagClass = UMASN1Class_Private;
                break;
            case 0:
            default:
                _tagClass = UMASN1Class_Universal;
                break;
        }

        if(byte & 0x20)
        {
            [self setTagIsConstructed];
        }
        else
        {
            [self setTagIsPrimitive];
        }
    }
    return self;
}


- (UMASN1Tag *)initWithBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context
{
    self = [super init];
    if(self)
    {
        uint8_t byte = grab_byte(data,pos);
        switch((byte>>6) & 0x3)
        {
            case 1:
                _tagClass = UMASN1Class_Application;
                break;
            case 2:
                _tagClass = UMASN1Class_ContextSpecific;
                break;
            case 3:
                _tagClass = UMASN1Class_Private;
                break;
            case 0:
            default:
                _tagClass = UMASN1Class_Universal;
                break;
        }

        if(byte & 0x20)
        {
            [self setTagIsConstructed];
        }
        else
        {
            [self setTagIsPrimitive];
        }
        _tagNumber = byte & 0x1F;
        if(_tagNumber == 0x1F) /* all bits set */
        {
            _tagNumber = 0;
            uint8_t bit7;
            do
            {
                byte = grab_byte(data,pos);
                bit7 = byte & 0x80;
                _tagNumber = _tagNumber << 7;
                _tagNumber = _tagNumber | (byte & 0x7F);
            } while (bit7!=0);
        }
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc] init];
    switch(_tagClass)
    {
        case UMASN1Class_Universal:
            [s appendString:@"UNIVERSAL"];
            break;
        case UMASN1Class_Application:
            [s appendString:@"APPLICATION"];
            break;
        case UMASN1Class_ContextSpecific:
            [s appendString:@"CONTEXT_SPECIFIC"];
            break;
        case UMASN1Class_Private:
            [s appendString:@"PRIVATE"];
            break;
    }
    [s appendFormat:@" [%lu] ",(unsigned long)_tagNumber];
    
    if(_isConstructed)
    {
        [s appendString:@"CONSTRUCTED"];
    }
    else
    {
        
        [s appendString:@"PRIMITIVE"];
    }
    return s;
}

- (NSString *)name
{
    NSString *c;
    switch(_tagClass)
    {
        case UMASN1Class_Universal:
        {
            c = @"Universal";
            switch(_tagNumber)
            {
                case 1:
                    return @"BOOLEAN";
                case 2:
                    return @"INTEGER";
                case 3:
                    return @"BIT_STRING";
                case 4:
                    return @"OCTET_STRING";
                case 5:
                    return @"NULL";
                case 6:
                    return @"OBJECT_IDENTIFIER";
                case 7:
                    return @"ObjectDescriptor";
                case 8:
                    return @"EXTERNAL";
                case 9:
                    return @"REAL";
                case 10:
                    return @"ENUMERATED";
                case 11:
                    return @"EMBEDDED_PDV";
                case 12:
                    return @"UTF8String";
                case 13:
                    return @"RELATIVE_OID";
                case 16:
                    return @"SEQUENCE";
                case 17:
                    return @"SET";
                case 18:
                    return @"NumericString";
                case 19:
                    return @"PrintableString";
                case 20:
                    return @"T61String";
                case 21:
                    return @"VideotexString";
                case 22:
                    return @"IA5String";
                case 23:
                    return @"UTCTime";
                case 24:
                    return @"GeneralizedTime";
                case 25:
                    return @"GraphicString";
                case 26:
                    return @"ISO646String";
                case 27:
                    return @"GeneralString";
                case 28:
                    return @"UniversalString";
                case 29:
                    return @"CHARACTER_STRING";
                case 30:
                    return @"BMPString";
            }
        }
            break;
        case UMASN1Class_Application:
            c = @"Application";
            break;
        case UMASN1Class_ContextSpecific:
            c = @"ContextSpecific";
            break;
        case UMASN1Class_Private:
        default:
            c = @"Private";
            break;
    }
    return [NSString stringWithFormat: @"%@_%@",c,@(_tagNumber)];
}

- (NSData *)berEncoded
{
    NSMutableData *data = [[NSMutableData alloc]init];
    uint8_t byte = (_tagClass & 0x3) << 6;
    if(self.tagIsConstructed)
    {
        byte = byte | 0x20;
    }
    if(_tagNumber < 31)
    {
        /* simple case: 1 byte identifier */
        byte = byte | (_tagNumber & 0x1F);
        [data appendBytes:&byte length:1];
    }
    else
    {
        byte = byte | 0x1F;
        [data appendBytes:&byte length:1];
        uint64_t i = _tagNumber;

        uint8_t bytes[16];
        if(i < (1LL << 7)) /* 7 bits */
        {
            bytes[0] = i & 0x7F;
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
    return data;
}
@end
