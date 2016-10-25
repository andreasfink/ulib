//
//  NSString+UMHTTP.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "NSString+UMHTTP.h"


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

@end
