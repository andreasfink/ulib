//
//  UMASN1Object.m
//  ulibasn1
//
//  Created by Andreas Fink on 02.07.14.
//
// This source is dual licensed either under the GNU GENERAL PUBLIC LICENSE
// Version 3 from 29 June 2007 and other commercial licenses available by
// the author.


#import <ulibasn1/UMASN1Object.h>
#import <ulibasn1/UMASN1Tag.h>

#define NIBBLE_TO_HEX(b)    (((b)<0x0A) ? ('0'+(b)) : ('A'+(b)-0x0A))

static inline uint8_t grab_byte(NSData *data,NSUInteger *pos, id obj);
static inline NSData *grab_bytes(NSData *data,NSUInteger *pos, NSUInteger grablen, id obj);

static inline uint8_t grab_byte(NSData *data,NSUInteger *pos, id obj)
{
    const uint8_t *bytes = data.bytes;
    NSUInteger len = data.length;
    if(*pos >= len)
    {
        @throw([NSException exceptionWithName:@"ASN1_READ_BEYOND_EOD"
                                       reason:NULL
                                     userInfo:@{
                                                @"sysmsg" : @"reading beyond end of data in content bytes",
                                                @"func": @(__func__),
                                                @"data" : data,
                                                @"pos" : @(*pos),
                                                @"backtrace": UMBacktrace(NULL,0)
                                                }
                ]);
    }
    uint8_t byte = bytes[(*pos)++];
    return byte;
}

static inline NSData *grab_bytes(NSData *data,NSUInteger *pos, NSUInteger grablen, id obj)
{
    const uint8_t *bytes = data.bytes;
    NSUInteger len = data.length;
    if(*pos+grablen > len)
    {
        @throw([NSException exceptionWithName:@"READ_BEYOND_EOD"
                                       reason:NULL
                                     userInfo:@{
                                                @"sysmsg" : @"reading beyond end of data in content bytes",
                                                @"func": @(__func__),
                                                @"data" : data,
                                                @"pos" : @(*pos),
                                                @"backtrace": UMBacktrace(NULL,0)
                                                }
                ]);
    }
    NSData *returnbytes = [NSData dataWithBytes:&bytes[*pos] length:grablen];
    *pos += grablen;
    return returnbytes;
}

NSString *BinaryToNSString(const unsigned char *str, int size )
{
    NSMutableString *tmp = NULL;
    unsigned char c;
    unsigned char a;
    unsigned char b;
    int len;
    int pos;
    int ton;
    int npi;
    pos=0;
    len = size;
    tmp = [[NSMutableString alloc]init];
    
    ton = str[pos++];
    npi = ton & 0x0F;
    ton =  (ton >> 4) & 0x07;
    
    while(--len)
    {
        c = str[pos++];
        a =  c & 0x0F;
        b =  ((c & 0xF0) >> 4);
        
        if((b == 0x0F) && (len < 2))
        {
            [tmp appendFormat:@"%c",NIBBLE_TO_HEX(a)];
        }
        else
        {
            [tmp appendFormat:@"%c",NIBBLE_TO_HEX(a)];
            [tmp appendFormat:@"%c",NIBBLE_TO_HEX(b)];
        }
    }
    if((ton==1) && (npi==1)) /* intl E164 */
    {
        return [NSString stringWithFormat:@"+%@",tmp];
    }
    else if((ton==0) && (npi==0)) /* unknown unknown */
    {
        return [NSString stringWithFormat:@"%@",tmp];
    }
    return [NSString stringWithFormat:@":%d:%d:%d:%@",ton,npi,0,tmp];
}

@implementation UMASN1Object

-(BOOL)isEndOfContents
{
    if( (_asn1_tag.tagClass == UMASN1Class_Universal) &&
        (_asn1_tag.tagIsPrimitive) &&
        (_asn1_tag.tagNumber == 0) &&
        (_asn1_length.length == 0) )
    {
        return YES;
    }
    return NO;
}


- (UMASN1Object *)init
{
    self = [super init];
    if(self)
    {
        _asn1_tag    = [[UMASN1Tag alloc]init];
        _asn1_length = [[UMASN1Length alloc]init];
    }
    return self;
}

- (UMASN1Object *)initWithBerData:(NSData *)data
{
    self = [super init];
    if(self)
    {
        @try
        {
            NSUInteger pos = 0;
            self = [self readBerData:data atPosition:&pos context:NULL];
            if(pos != data.length)
            {
                @throw([NSException exceptionWithName:@"ASN1_GARBAGE_AFTER_END"
                                               reason:NULL
                                             userInfo:NULL]);
            }
        }
        @catch(NSException *e)
        {
            @throw(e);
        }
        self = [self processAfterDecodeWithContext:NULL];
    }
    return self;
}

- (UMASN1Object *)initWithBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context
{
    self = [super init];
    if(self)
    {
        @try
        {
            self = [self readBerData:data atPosition:pos context:context];
        }
        @catch(NSException *e)
        {
            @throw(e);
        }
        self = [self processAfterDecodeWithContext:context];
    }
    return self;
}

- (UMASN1Object *)readBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context
{
    @try
    {
        _asn1_tag = [[UMASN1Tag alloc]initWithBerData:data atPosition:pos context:context];
        if(_asn1_tag == NULL)
        {
            @throw([NSException exceptionWithName:@"ASN1_CAN_NOT_READ_TAG"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"can't read the tag",
                                                    @"func": @(__func__),
                                                    @"backtrace": UMBacktrace(NULL,0)
                                                    }
                    ]);
        }
        _asn1_length = [[UMASN1Length alloc]initWithBerData:data atPosition:pos context:context];
        /* FIXME: is this really correct ? */
        if( (_asn1_tag.tagClass == UMASN1Class_Universal) &&
           (_asn1_tag.tagIsPrimitive) &&
           (_asn1_tag.tagNumber == 0) &&
           (_asn1_length.length == 0) )

        {
            return self;
        }
        if(_asn1_length.undefinedLength == NO)
        {
            if(_asn1_tag.tagIsPrimitive)
            {
                /* exact length is known */
                _asn1_data = grab_bytes(data,pos,_asn1_length.length,self );
                _asn1_list = NULL;
            }
            else // isConstructed
            {
                _asn1_data = NULL;
                NSData *constructedData  = NULL;
                constructedData = grab_bytes(data,pos,_asn1_length.length,self );
                _asn1_list = [[NSMutableArray alloc]init];
                NSUInteger p2=0;
                while(p2 < constructedData.length)
                {
                    UMASN1Object *the_list_item = [[UMASN1Object alloc]initWithBerData:constructedData atPosition:&p2 context:context];
                    if(the_list_item)
                    {
                        if(the_list_item.isEndOfContents == NO)
                        {
                            [_asn1_list addObject:the_list_item];
                        }
                    }
                    
                    if(!(_asn1_length.undefinedLength) && (p2 >= constructedData.length))
                    {
                        break;
                    }
                }
            }
        }
        else /* undefined length */
        {
            if(self.asn1_tag.tagIsPrimitive)
            {
                /* a primitive without a length is kind of a suicide mission. we try to recover by simply reading until 00 00 is encountered */
                NSMutableData *this_data = [[NSMutableData alloc]init];
                uint8_t byte1 = grab_byte(data,pos,self);
                while(1)
                {
                    uint8_t byte2 = grab_byte(data,pos,self);
                    if((byte1 == 0) && (byte2==0))
                    {
                        self.asn1_data = this_data;
                        break;
                    }
                    [this_data appendBytes:&byte1 length:1];
                    byte1 = byte2;
                }
            }
            else /* a constructed item . Lets read until we get a end of content marker */
            {
                self.asn1_list = [[NSMutableArray alloc]init];
                while(1)
                {
                    UMASN1Object *the_list_item = [[UMASN1Object alloc]initWithBerData:data atPosition:pos context:context];
                    if((the_list_item == NULL) || (the_list_item.isEndOfContents))
                    {
                        break;
                    }
                    [self.asn1_list addObject:the_list_item];
                }
            }
        }
    }
    @catch(NSException *exception)
    {
        //NSLog(@"Exception in readBerData:atPos:%d on object %@: %@\nData: %@",(int)*pos,[[self class]description],exeption,data);
        @throw(exception);
    }
    return self;
}

- (UMASN1Object *)initWithASN1Object:(UMASN1Object *)obj context:(id)context  encoding:(UMASN1EncodingType)encType
{
    self = [super init];
    if(self)
    {
        self.asn1_tag    = obj.asn1_tag;
        self.asn1_length = obj.asn1_length;
        self.encodingType = encType;
        if(self.asn1_tag.tagIsPrimitive)
        {
            if(self.encodingType == UMASN1EncodingType_unknownEncoded)
            {
                self.encodingType = UMASN1EncodingType_implicitlyEncoded;
            }
            self.asn1_data   = [obj.asn1_data copy];
        }
        else
        {
            self.asn1_list = [obj.asn1_list mutableCopy];
        }
        self = [self processAfterDecodeWithContext:context];
    }
    return self;
}

- (UMASN1Object *)processAfterDecodeWithContext:(id)context
{
    /* this method is normally overriden */
    return self;
}

- (void)processBeforeEncode
{
    /* this method is normally overriden */
    //encodingPreparationDone = YES;
}

/*
- (NSData *)asn1_data
{
    return _asn1_data;
}

- (void)setAsn1_data:(NSData *)d
{
    _asn1_data = d;
    _asn1_length.length = d.length;
    [_asn1_tag setTagIsPrimitive];
    _asn1_list = NULL;
}
*/

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    
    if(_encodingPreparationDone==NO)
    {
        [self processBeforeEncode];
    }
    [s appendString:_asn1_tag.description];
    [s appendString:@"\t"];
    [s appendString:_asn1_length.description];
    [s appendString:@"\t"];
    if(_asn1_tag.tagIsPrimitive)
    {
        if(_asn1_data==NULL)
        {
            [s appendString:@"(null)\n"];
        }
        else if(_asn1_data.length  > 0)
        {
            [s appendString:[_asn1_data description]];
            [s appendString:@"\n"];
        }
        else
        {
            [s appendString:@"<>\n\n"];
        }
    }
    if(_asn1_tag.isConstructed)
    {
        [s appendString:@"\n{\n"];
        for(UMASN1Object *item in _asn1_list)
        {
            NSString *item_description = item.description;
            NSArray *lines = [item_description componentsSeparatedByString:@"\n"];
            for(NSString *line in lines)
            {
                if(![line isEqualToString:@""])
                {
                    [s appendFormat:@"\t%@\n",line];
                }
            }
        }
        [s appendString:@"}"];
    }
    return s;
}


- (NSString *)objectName
{
    return _asn1_tag.name;
}

- (NSString *)objectOperation
{
    return NULL;
}

- (UMASN1Object *)getObjectAtPosition:(NSUInteger)pos
{
    if(_asn1_tag == NULL)
    {
        return NULL;
    }  
    if(!_asn1_tag.isConstructed)
    {
        //NSLog(@"trying to read object at position %lu from a ASN1 object which is not a CONSTRUCTED one",(unsigned long)pos);
        return NULL;
    }

    if(pos >= _asn1_list.count)
    {
        //NSLog(@"trying to read object at position %lu while we only have %lu objets",(unsigned long)pos,(unsigned long)asn1_list.count);
        return NULL;
    }
    UMASN1Object *o = [_asn1_list objectAtIndex:pos];
    return o;
}

- (UMASN1Object *)getObjectWithTagNumber:(NSUInteger)nr
{
    for(UMASN1Object *o in _asn1_list)
    {
        if(o.asn1_tag.tagNumber == nr)
        {
            return o;
        }
    }
    return NULL;
}

- (UMASN1Object *)getPrivateObjectWithTagNumber:(NSUInteger)nr
{
    for(UMASN1Object *o in _asn1_list)
    {
        if((o.asn1_tag.tagNumber == nr) && (o.asn1_tag.tagClass == UMASN1Class_Private))
        {
            return o;
        }
    }
    return NULL;
}

- (UMASN1Object *)getUniversalObjectWithTagNumber:(NSUInteger)nr
{
    for(UMASN1Object *o in _asn1_list)
    {
        if((o.asn1_tag.tagNumber == nr) && (o.asn1_tag.tagClass == UMASN1Class_Universal))
        {
            return o;
        }
    }
    return NULL;
}

- (UMASN1Object *)getApplicationSpecificObjectWithTagNumber:(NSUInteger)nr
{
    for(UMASN1Object *o in _asn1_list)
    {
        if((o.asn1_tag.tagNumber == nr) && (o.asn1_tag.tagClass == UMASN1Class_Application))
        {
            return o;
        }
    }
    return NULL;
}

- (UMASN1Object *)getContextSpecificObjectWithTagNumber:(NSUInteger)nr
{
    for(UMASN1Object *o in _asn1_list)
    {
        if((o.asn1_tag.tagNumber == nr) && (o.asn1_tag.tagClass == UMASN1Class_ContextSpecific))
        {
            return o;
        }
    }
    return NULL;
}

- (UMASN1Object *)getObjectWithTagNumber:(NSUInteger)nr startingAtPosition:(NSUInteger)start
{
    for(UMASN1Object *o in _asn1_list)
    {
        if(start > 0)
        {
            start--;
        }
        else
        {
            if(o.asn1_tag.tagNumber == nr)
            {
                return o;
            }
        }
    }
    return NULL;
}

- (NSString *)bitstringDataAsStringValue
{
    return @"some-bitstring";
}

- (NSString *)integerDataAsStringValue
{
    const uint8_t *bytes = self.asn1_data.bytes;
    NSUInteger len  = self.asn1_data.length;
    NSUInteger value = 0;
    for(NSUInteger i=0;i<len;i++)
    {
        value = value << 8;
        value |= bytes[i];
    }
    return [NSString stringWithFormat:@"%lu",(unsigned long)value];
}

- (NSString *)realDataAsStringValue
{
    return @"some-real";
}

- (NSString *)octetstringDataAsStringValue
{
    NSMutableString *s = [[NSMutableString alloc]init];
    
    const uint8_t *bytes = self.asn1_data.bytes;
    NSUInteger len  = self.asn1_data.length;

    for(NSUInteger i =0;i<len;i++)
    {
        if(i==0)
        {
            [s appendFormat:@"0x%02X",bytes[i]];
        }
        else
        {
            [s appendFormat:@",0x%02X",bytes[i]];
        }
    }
    return s;
}

- (NSString *)rawDataAsStringValue
{
    return [NSString stringWithFormat:@"%@:%@",_asn1_tag.description,[self octetstringDataAsStringValue]];
}

-(NSString *)nullDataAsStringValue
{
    return @"PRESENT";
}

- (NSString *)imsiValue
{
    NSMutableString *s = [[NSMutableString alloc]init];
    const uint8_t *bytes = self.asn1_data.bytes;
    NSUInteger len = self.asn1_data.length;
    
    for(NSUInteger i=0;i<len;i++)
    {
        uint8_t c = bytes[i];
        int a = ( c & 0x0F);
        int b = ( c & 0xF0) >> 4;
        if((i == (len -1)) && (b == 0xF))
        {
            [s appendFormat:@"%c",NIBBLE_TO_HEX(a)];
        }
        else
        {
            [s appendFormat:@"%c%c",NIBBLE_TO_HEX(a),NIBBLE_TO_HEX(b)];
        }
    }
    return s;
}

- (NSString *)isdnValue
{
    const uint8_t *bytes = self.asn1_data.bytes;
    NSUInteger size = self.asn1_data.length;

    return BinaryToNSString(bytes, (int)size);
}

- (NSString *)stringValue
{
    if(_asn1_tag.tagClass==UMASN1Class_Universal)
    {
        if(self.asn1_data==NULL)
        {
            return @"";
        }
        const uint8_t *bytes = self.asn1_data.bytes;
        NSUInteger len  = self.asn1_data.length;
        if(len==0)
        {
            return @"";
        }
        switch (_asn1_tag.tagNumber)
        {
            case UMASN1Primitive_boolean:
                return [NSString stringWithFormat:@"%d",(int)bytes[0]];
            case UMASN1Primitive_integer:
                return [self integerDataAsStringValue];
            case UMASN1Primitive_bitstring:
                return [self bitstringDataAsStringValue];
//          case UMASN1Primitive_real:
//              return [self realDataAsStringValue];
            case UMASN1Primitive_octetstring:
                return [self octetstringDataAsStringValue];
            case UMASN1Primitive_null:
                return [self nullDataAsStringValue];
            default:
                return [self rawDataAsStringValue];
        }
    }
    else
    {
        return [self rawDataAsStringValue];
    }
}

- (NSData *)berEncodedContentData
{
    if(self.asn1_tag.isConstructed==NO)
    {
        return self.asn1_data;
    }
    else
    {
        NSMutableData *content = [[NSMutableData alloc]init];
        for(UMASN1Object *item in self.asn1_list)
        {
            [content appendData: [item berEncoded]];
        }
        return content;
    }
}

- (NSData *)berEncoded
{
    [self processBeforeEncode];

    NSData *identifierData   = [self.asn1_tag berEncoded];
    NSData *contentData      = [self berEncodedContentData];
    [_asn1_length setLength:contentData.length];
    NSData *lengthData       = [self.asn1_length berEncoded];
    NSData *endOfData        = [self.asn1_length berEncodedEndOfData];
    
    NSMutableData *out = [[NSMutableData alloc]init];
    [out appendData:identifierData];
    [out appendData:lengthData];
    [out appendData:contentData];
    [out appendData:endOfData];
    return out;
}

- (id)objectValue
{
    if(_asn1_tag.tagIsPrimitive)
    {
        if(self.asn1_data.length==0)
        {
            return @"";
        }
        else
        {
            /* FIXME: return integer for INTEGER type  instead of its hex bytes */
            return [self.asn1_data hexString];
        }
    }
    else if(_asn1_tag.isConstructed)
    {
        UMSynchronizedSortedDictionary *a = [[UMSynchronizedSortedDictionary alloc]init];
        for(UMASN1Object *o  in _asn1_list)
        {
            a[o.objectName] = o.objectValue;
        }
        return a;
    }
    else
    {
        return @"";
    }
}

+ (uint64_t)classTagNumber
{
    return -1;
}

+ (BOOL)tagMatches:(uint64_t)tag
{
    return tag == [self classTagNumber];
}

- (id)proxyForJson
{
    if(_asn1_tag == NULL)
    {
        return @"(invalid tag)";
    }
    
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];
    d[@"tag"] = @(self.asn1_tag.tagNumber);
    switch(self.asn1_tag.tagClass)
    {
        case UMASN1Class_Universal:
            d[@"class"] = @"Universal";
            break;
        case UMASN1Class_Application:
            d[@"class"] = @"Application";
            break;

        case UMASN1Class_ContextSpecific:
            d[@"class"] = @"ContextSpecific";
            break;
        case UMASN1Class_Private:
            d[@"class"] = @"Private";
            break;
        
    }
    if((_asn1_tag.tagIsPrimitive) && (self.asn1_data))
    {
        d[@"data"] = self.asn1_data;
    }
    else if((_asn1_tag.tagIsConstructed) && (_asn1_list))
    {
        NSMutableArray *a = [[NSMutableArray alloc]init];
        for (UMASN1Object *entry in _asn1_list)
        {
            NSString *s = [entry proxyForJson];
            [a addObject:s];
        }
        d[@"content"] = a;
    }
    return d;
}

- (UMASN1Object *)initWithASN1Object:(UMASN1Object *)obj context:(id)context
{
    return [self initWithASN1Object:obj context:context encoding:UMASN1EncodingType_unknownEncoded];
}

+ (BOOL)tagMatch:(UMASN1Tag *)t
{
    if(t.tagNumber == [self classTagNumber])
    {
        return YES;
    }
    return NO;
}

- (NSString *)jsonString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    NSString *json=NULL;
    json = [writer stringWithObject:self];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

- (NSString *)jsonCompactString
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = NO;
    NSString *json=NULL;
    json = [writer stringWithObject:self];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

+ (void)asn1DefAppendString:(NSMutableString *)o
                        len:(NSInteger)len
                        tag:(NSInteger)tag
                   dictname:(const char *)dictname
                    options:(const char *)options
                       type:(const char *)type
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"    %s",dictname];
    while(s.length < 34)
    {
        [s appendString:@" "];
    }
    [s appendFormat:@"[%ld] %s,\n",tag,type];
    [o appendFormat:@"%@",s];
}

@end
