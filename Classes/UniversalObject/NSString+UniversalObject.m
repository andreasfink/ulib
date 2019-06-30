//
//  NSString+UniversalObject.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "NSString+UniversalObject.h"
#import "NSData+UniversalObject.h"
#import "NSDate+stringFunctions.h"
#import "UMAssert.h"


NSString *sqlEscapeNSString(NSString *input)
{
	if(input)
    {
		return [input sqlEscaped];
    }
	return @"";
}


@implementation NSString (UniversalObject)

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
@end

