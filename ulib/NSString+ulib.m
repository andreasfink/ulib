//
//  NSString+ulib.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSString+ulib.h>
#import <ulib/UMAssert.h>
#import <ulib/NSData+ulib.h>
#import <ulib/NSDate+ulib.h>
#import <ulib/UMJsonWriter.h>
#import <ulib/UMJsonParser.h>

#include <openssl/bio.h>
#include <openssl/evp.h>
#include <arpa/inet.h>
#if defined(FREEBSD)
#include <netinet/in.h>
#endif

@implementation NSString(HierarchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	return [NSString stringWithFormat:@"%@String: %@",prefix,self];
}

- (NSString *)increasePrefix
{
	return [NSString stringWithFormat:@"\t%@",self];
}

- (NSString *)removeFirstAndLastChar
{
	ssize_t n;
	n = [self length];
	n = n - 2;
	if(n<0)
		n = 0;
	return [self substringWithRange:NSMakeRange(1,n)];
}


- (NSString *)htmlEscaped
{
    NSString *s = [self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    s = [s stringByReplacingOccurrencesOfString:@"\t" withString:@"&Tab;"];
    s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@"&NewLine;"];
    s = [s stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];
    s = [s stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    s = [s stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    s = [s stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    return s;
}



static inline int nibbleToInt(const char a)
{
    if((a>='0') && (a<='9'))
        return (a-'0');
    if((a>='a') && (a<='f'))
        return (a-'a'+10);
    if((a>='A') && (a<='F'))
        return (a-'A'+10);
    return 0;
}


- (NSArray *)splitByFirstCharacter:(unichar)uc
{
    ssize_t len;
    ssize_t i;
    unichar c;
    len = [self length];
    for(i=0;i<len;i++)
    {
        c =[self characterAtIndex:i];
        if(c==uc)
        {
            return @[[self substringToIndex:i],
                     [self substringFromIndex:i+1]];
        }
    }
    //not found?
    return @[self,@""];
}

- (NSString *)urldecode
{
    NSString *result = [(NSString *)self stringByReplacingOccurrencesOfString:@"+" withString:@" "];

#if defined(__APPLE__)
    result = [result stringByRemovingPercentEncoding];
#else
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#endif
    return result;
}

- (NSData *)dataValue
{
    return [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}


- (NSData *)urldecodeData
{
    const char *c = self.UTF8String;
    size_t len  = strlen(c);
    size_t i;
    int status = 0;
    unsigned char nibble = 0;
    NSMutableData *out = [[NSMutableData alloc]init];
    for(i=0;i<len;i++)
    {
        if(status==0)
        {
            if(c[i]=='+')
            {
                char space=' ';
                [out appendBytes:&space length:1];
            }
            else if(c[i]=='%')
            {
                status = 1;
            }
            else
            {
                [out appendBytes:&c[i] length:1];
            }
        }
        else if(status==1)
        {
            if(c[i]=='%')
            {
                [out appendBytes:&c[i] length:1];
                status = 0;
            }
            else
            {
                nibble = nibbleToInt(c[i]);
                status = 2;
            }

        }
        else if(status==2)
        {
            nibble = nibble << 4;
            nibble += nibbleToInt(c[i]);
            status = 0;
            [out appendBytes:&nibble length:1];
            nibble = 0;
        }
    }
    return out;
}

- (NSString *) urlencode
{
    static NSCharacterSet *allowedInUrl;
    if(allowedInUrl == NULL)
    {
        allowedInUrl = [NSCharacterSet characterSetWithCharactersInString:@"!$&'()*,-.0123456789;=ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~"];
    }

    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data urlencode];
}

- (NSData *)decodeBase64
{
#ifdef __APPLE__
    return [[NSData alloc]initWithBase64EncodedString:self
                                              options:NSDataBase64DecodingIgnoreUnknownCharacters];
#else
    NSString *decode = [self stringByAppendingString:@"\n"];
    NSData *data = [decode dataUsingEncoding:NSASCIIStringEncoding];

    // Construct an OpenSSL context
    BIO *command = BIO_new(BIO_f_base64());
    BIO *context = BIO_new_mem_buf((void *)[data bytes],(int)[data length]);

    // Tell the context to encode base64
    context = BIO_push(command, context);

    // Encode all the data
    NSMutableData *outputData = [NSMutableData data];

#define BUFFSIZE 256
    int len;
    char inbuf[BUFFSIZE];
    while ((len = BIO_read(context, inbuf, BUFFSIZE)) > 0)
    {
        [outputData appendBytes:inbuf length:len];
    }

    BIO_free_all(context);
    [data self]; // extend GC lifetime of data to here

    return outputData;
#endif
}



- (NSString *)jsonString;
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = YES;
    NSString *json = [writer stringWithObject:self];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

- (NSString *)jsonCompactString;
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    writer.humanReadable = NO;
    NSString *json = [writer stringWithObject:self];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

- (BOOL)isIPv4
{
    if([self hasPrefix:@"ipv4:"])
    {
        return YES;
    }
    struct in_addr addr4;
    
    int result = inet_pton(AF_INET,self.UTF8String, &addr4);
    if(result==1)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isIPv6
{
    if([self hasPrefix:@"ipv6:"])
    {
        return YES;
    }

    struct in6_addr addr6;

    int result = inet_pton(AF_INET6,self.UTF8String, &addr6);
    if(result==1)
    {
        return YES;
    }
    return NO;
}


- (NSData *)binaryIPAddress
{
    if([self isIPv4])
    {
        return [self binaryIPAddress4];
    }
    return [self binaryIPAddress6];
}

- (NSData *)binaryIPAddress4
{
    uint32_t addr4;

    int result = inet_pton(AF_INET,self.UTF8String, (struct in_addr *)&addr4);
    if(result==1)
    {
        return [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
    }
    return 0;
}

- (NSData *)binaryIPAddress6
{
    struct in6_addr addr6;

    int result = inet_pton(AF_INET6,self.UTF8String, &addr6);
    if(result==1)
    {
        return [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
    }
    return 0;
}


- (NSString *)sqlEscaped
{
    if(self == NULL)
    {
        return @"";
    }
    
    
    NSString *s = self;
    /* we always escape the lower 32 chars */
    s = [s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];

    s = [s stringByReplacingOccurrencesOfString:@"\x00" withString:@"\\x00"];
    s = [s stringByReplacingOccurrencesOfString:@"\x01" withString:@"\\x01"];
    s = [s stringByReplacingOccurrencesOfString:@"\x02" withString:@"\\x02"];
    s = [s stringByReplacingOccurrencesOfString:@"\x03" withString:@"\\x03"];
    s = [s stringByReplacingOccurrencesOfString:@"\x04" withString:@"\\x04"];
    s = [s stringByReplacingOccurrencesOfString:@"\x05" withString:@"\\x05"];
    s = [s stringByReplacingOccurrencesOfString:@"\x06" withString:@"\\x06"];
    s = [s stringByReplacingOccurrencesOfString:@"\x07" withString:@"\\x07"];
    s = [s stringByReplacingOccurrencesOfString:@"\x08" withString:@"\\x08"];
    s = [s stringByReplacingOccurrencesOfString:@"\x09" withString:@"\\x09"];
    s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    s = [s stringByReplacingOccurrencesOfString:@"\x0b" withString:@"\\x0b"];
    s = [s stringByReplacingOccurrencesOfString:@"\x0c" withString:@"\\x0c"];
    s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    s = [s stringByReplacingOccurrencesOfString:@"\x0e" withString:@"\\x0e"];
    s = [s stringByReplacingOccurrencesOfString:@"\x0f" withString:@"\\x0f"];
    
    s = [s stringByReplacingOccurrencesOfString:@"\x10" withString:@"\\x10"];
    s = [s stringByReplacingOccurrencesOfString:@"\x11" withString:@"\\x11"];
    s = [s stringByReplacingOccurrencesOfString:@"\x12" withString:@"\\x12"];
    s = [s stringByReplacingOccurrencesOfString:@"\x13" withString:@"\\x13"];
    s = [s stringByReplacingOccurrencesOfString:@"\x14" withString:@"\\x14"];
    s = [s stringByReplacingOccurrencesOfString:@"\x15" withString:@"\\x15"];
    s = [s stringByReplacingOccurrencesOfString:@"\x16" withString:@"\\x16"];
    s = [s stringByReplacingOccurrencesOfString:@"\x17" withString:@"\\x17"];
    s = [s stringByReplacingOccurrencesOfString:@"\x18" withString:@"\\x18"];
    s = [s stringByReplacingOccurrencesOfString:@"\x19" withString:@"\\x19"];
    s = [s stringByReplacingOccurrencesOfString:@"\x1a" withString:@"\\x1a"];
    s = [s stringByReplacingOccurrencesOfString:@"\x1b" withString:@"\\x1b"];
    s = [s stringByReplacingOccurrencesOfString:@"\x1c" withString:@"\\x1c"];
    s = [s stringByReplacingOccurrencesOfString:@"\x1d" withString:@"\\x1d"];
    s = [s stringByReplacingOccurrencesOfString:@"\x1e" withString:@"\\x1e"];
    s = [s stringByReplacingOccurrencesOfString:@"\x1f" withString:@"\\x1f"];

    s = [s stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    s = [s stringByReplacingOccurrencesOfString:@"`" withString:@"\\`"];
    s = [s stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return s;
}

- (NSString *)onlyHex
{
    NSMutableString *onlyHexChars = [[NSMutableString alloc]init];
    NSUInteger n= self.length;
    NSUInteger i;
    for(i=0;i<n;i++)
    {
        unichar c = [self characterAtIndex:i];
        if((c >='0') && (c<='9'))
        {
            [onlyHexChars appendFormat:@"%c",(char)c];
        }
        else if((c >='A') && (c<='F'))
        {
            [onlyHexChars appendFormat:@"%c",(char)c];
        }
        else if((c >='a') && (c<='f'))
        {
            [onlyHexChars appendFormat:@"%c",(char)c-'a'+'A'];
        }
    }
    return onlyHexChars;
}

- (NSData *)unhexedData
{
    NSData *d = [[self onlyHex] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *result = [d unhexedData];
    return result;
}

- (NSString *)cquoted
{
    NSUInteger len = [self length];
    NSMutableString *out = [[NSMutableString alloc]initWithCapacity:len];
    int i;
    for(i=0;i<len;i++)
    {
        unichar uc  = [self characterAtIndex:i];
        switch(uc)
        {
            case '\0':
                [out appendString:@"\\0"];
                break;
            case '\'':
                [out appendString:@"\\'"];
                break;
            case '\"':
                [out appendString:@"\\\""];
                break;
            case '\n':
                [out appendString:@"\\n"];
                break;
            case '\t':
                [out appendString:@"\\t"];
                break;
            case '\r':
                [out appendString:@"\\r"];
                break;
            case '\\':
                [out appendString:@"\\\\"];
                break;
            default:
                [out appendFormat:@"%C",uc];
                break;
        }
    }
    return out;
}

- (NSString *)printable
{
#define MAXLINELEN  1024

    char s2[MAXLINELEN];
    memset(&s2,0x00,sizeof(s2));
    
    
    const char *s = self.UTF8String;
    size_t len = strlen(s);
    if(len >= MAXLINELEN)
    {
        len = MAXLINELEN-1;
    }
    
    size_t i;
    size_t j;
    const char nibbles[] = "0123456789ABCDEF";
    j = 0;
    for(i=0;i<len;i++)
    {
        char c = s[i];
        if(c == '\n')
        {
            s2[j++]='\\';
            s2[j++]='n';
        }
        else if (c=='\r')
        {
            s2[j++]='\\';
            s2[j++]='r';
        }
        else if (c=='\t')
        {
            s2[j++]='\\';
            s2[j++]='t';
        }
        else if (c=='\\')
        {
            s2[j++]='\\';
            s2[j++]='\\';
        }
        else if(isprint(c))
        {
            s2[j++] = c;
        }
        else
        {
            s2[j++]='\\';
            s2[j++]='x';
            s2[j++]= nibbles[(c & 0xF0) >> 4];
            s2[j++]= nibbles[(c & 0x0F) >> 0];
        }
        if(j >= (MAXLINELEN-5))
        {
            break;
        }
    }
    s2[j++]='\0';
    NSString *r = @(s2);
    return r;
}


- (NSString *)fileNameRelativeToPath:(NSString *)path
{
    if((([self length]>1) && ([self characterAtIndex:0]=='/')) || (path==NULL))
    {
        return self;
    }
    return [NSString stringWithFormat:@"%@/%@",path,self];
}

- (NSString *) prefixLines:(NSString *)prefix
{
    NSMutableString *s = [[NSMutableString alloc]init];
    NSArray *lines = [self componentsSeparatedByCharactersInSet:[UMObject newlineCharacterSet]];
    for(NSString *line in lines)
    {
        [s appendFormat:@"%@%@\n",prefix,line];
    }
    return s;
}

- (NSString *)stringValue
{
    return self;
}

- (NSDate *)dateValue
{
    return [NSDate dateWithStandardDateString:self];
}

+ (NSString *)stringWithStandardDate:(NSDate *)d
{
    if(d==NULL)
    {
        return @"0000-00-00 00:00:00.000000";
    }
    return [d stringValue];
}

- (NSString *)hexString
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    return [data hexString];
}

- (BOOL)hasCaseInsensitiveSuffix:(NSString *)suffix
{
    if(self.length < suffix.length)
    {
        return NO;
    }
    NSString *part = [suffix substringToIndex:suffix.length];
    if([part caseInsensitiveCompare:suffix]==NSOrderedSame)
    {
        return YES;
    }
    return NO;
}

- (BOOL)hasCaseInsensitivePrefix:(NSString *)prefix
{
    if(self.length < prefix.length)
    {
        return NO;
    }
    NSString *part = [prefix substringFromIndex:(self.length - prefix.length)];
    if([part caseInsensitiveCompare:prefix]==NSOrderedSame)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isEqualToStringCaseInsensitive:(NSString *)b
{
    NSString *a = [self lowercaseString];
    b = [b lowercaseString];
    return [a isEqualToString:b];
}

- (NSData *)sha1
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data sha1];
}

- (NSData *)sha224
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data sha224];
}

- (NSData *)sha256
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data sha256];
}

- (NSData *)sha384
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data sha384];
}

- (NSData *)sha512
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data sha512];
}

- (BOOL)webBoolValue
{
    if([self caseInsensitiveCompare:@"on"]==NSOrderedSame)
    {
        return YES;
    }
    if([self caseInsensitiveCompare:@"off"]==NSOrderedSame)
    {
        return NO;
    }
    if([self caseInsensitiveCompare:@"checked"]==NSOrderedSame)
    {
        return YES;
    }
    if([self caseInsensitiveCompare:@"selected"]==NSOrderedSame)
    {
        return YES;
    }
    if([self caseInsensitiveCompare:@"on"]==NSOrderedSame)
    {
        return YES;
    }
    if([self caseInsensitiveCompare:@""]==NSOrderedSame)
    {
        return NO;
    }
    return [self boolValue];
}

- (NSString *)trim
{
    return [self stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
}

- (NSInteger)intergerValueSupportingHex
{
    if([self hasPrefix:@"0x"])
    {
        NSString *d = [self substringFromIndex:2];
        NSData *d2 = [d unhexedData];
        const uint8_t *bytes = d2.bytes;
        NSInteger n = 0;
        for(NSInteger i=0; i<d2.length;i++)
        {
            n = (n << 8) | bytes[i];
        }
        return n;
    }
    else
    {
        return [self integerValue];
    }
}


/* this is used to clean names. They are all returned in lowercase
  only lowercase is allowed. Uppercase is converted
  . is not allowed in first place
  Allowed punctioations are - _ + , = %
*/
- (NSString *)filterNameWithMaxLength:(int)maxlen
{
    UMAssert(maxlen>0,@"maximum length must be bigger than zero");
    UMAssert(maxlen<255,@"maximum length can not be 255 or above");
    char out[256];
    out[255] = '\0';
    NSInteger i;
    NSInteger j = 0;
    NSInteger n = self.length;
    if(n>maxlen)
    {
        n = maxlen;
    }
    memset(out,0x00,sizeof(out));
    for(i=0;i<n;i++)
    {
        unichar c = [self characterAtIndex:i];
        if((c>='a') && (c<='z'))
        {
            out[j++]=c;
        }
        else if((c>='A') && (c<='Z'))
        {
            out[j++]=c-'A'+'a';
        }
        else if((c>='0') && (c<='9'))
        {
            out[j++]=c;
        }
        else
        {
            switch(c)
            {
                case '.':
                    if(i>0)
                    {
                        out[j++]=c;
                    }
                    break;
                case '_':
                case '-':
                case '+':
                case ',':
                case '=':
                case '%':
                    out[j++]=c;
                    break;
                default:
                    break;
            }
        }
    }
    NSString *result = @(out);
    return result;
}
- (NSString *)randomizeX
{
    NSMutableString *out = [[NSMutableString alloc]init];
    NSInteger count = self.length;
    for(NSInteger i=0;i<count;i++)
    {
        unichar uc = [self characterAtIndex:i];
        if((uc=='X') || (uc=='x'))
        {
            uc = '0' + (rand() % 10);
        }
        NSString *s = [[NSString alloc]initWithCharacters:&uc length:1];
        [out appendString:s];
    }
    return out;
}


- (BOOL)isEqualToStringSupportingX:(NSString *)str;
{
    if ([self isEqualToString:str])
    {
        return YES;
    }
    NSInteger count1 = self.length;
    NSInteger count2 = str.length;
    if(count1 != count2)
    {
        return NO;
    }
    for(NSInteger i=0;i<count1;i++)
    {
        unichar uc1 = [self characterAtIndex:i];
        unichar uc2 = [str characterAtIndex:i];
        if((uc1=='X') || (uc1=='x') || (uc2=='X') || (uc2=='x'))
        {
            continue;
        }
        if(uc1 != uc2)
        {
            return NO;
        }
    }
    return YES;

}
@end

NSString *sqlEscapeNSString(NSString *input)
{
    if(input)
    {
        return [input sqlEscaped];
    }
    return @"";
}

