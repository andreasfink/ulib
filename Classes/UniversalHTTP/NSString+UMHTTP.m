//
//  NSString+UMHTTP.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "NSString+UMHTTP.h"
#include <openssl/bio.h>
#include <openssl/evp.h>


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


@implementation NSString (UMHTTP)

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
        allowedInUrl = [NSCharacterSet characterSetWithCharactersInString:@"!$&'()*,-.0123456789:;=ABCDEFGHIJKLMNOPQRSTUVWXYZ[]_abcdefghijklmnopqrstuvwxyz~"];
    }

    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    const char *bytes = data.bytes;

    NSMutableString *out = [[NSMutableString alloc]init];
    NSInteger i;
    NSInteger len = [data length];
    for(i=0;i<len;i++)
    {
        unsigned char c = bytes[i];
        if([allowedInUrl characterIsMember:(unichar)c])
        {
            [out appendFormat:@"%c",c];
        }
        else
        {
            [out appendFormat:@"%%%02x",(int)c];
        }
    }
    return out;
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
@end
