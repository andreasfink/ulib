//
//  UMConstantStringsDict.m
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMConstantStringsDict.h"
#import "UMMutex.h"

static UMConstantStringsDict *global_constant_strings = NULL;

@implementation UMConstantStringsDict

+ (UMConstantStringsDict *)sharedInstance;
{
	if(global_constant_strings == NULL)
	{
		global_constant_strings = [[UMConstantStringsDict alloc]init];
	}
	return global_constant_strings;
}

- (UMConstantStringsDict *)init
{
	self = [super init];
	if(self)
	{
        for(int i=0;i<MAX_CSTRING_DICTS;i++)
        {
            _olock[i] = [[UMMutex alloc]initWithName:@"UMConstantStringsDict" saveInObjectStat:NO];
            _dict[i] = [[NSMutableDictionary alloc]init];
        }
	}
	return self;
}

- (const char *)asciiStringFromNSString:(NSString *)str
{
    /* We save constant strings into an array (always adding) and return a cont cptr
     if the string is already there we just return the already existing pointer
    we spread the dictionary to reduce the chance of locking collisions
    */
    const char *cptr = [str cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned long len = strlen(cptr);
    int sum = 0;
    for(int i=0;i<len;i++)
    {
        sum += cptr[i++];
    }
    int index = sum % MAX_CSTRING_DICTS;
    [_olock[index] lock];
    NSData *d = _dict[index][str];
    if(d)
    {
        [_olock[index] unlock];
        return     d.bytes;
    }
    d = [NSData dataWithBytes:cptr length:len+1]; /* We  include the null byte */
    _dict[index][str] = d;
	[_olock[index] unlock];
	return 	d.bytes;
}

@end
