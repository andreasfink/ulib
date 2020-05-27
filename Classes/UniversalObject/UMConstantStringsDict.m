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
        _lock = [[UMMutex alloc]initWithName:@"UMConstantStringsDict" saveInObjectStat:NO];
		_dict = [[NSMutableDictionary alloc]init];
	}
	return self;
}

- (const char *)asciiStringFromNSString:(NSString *)str
{
    /* We save constant strings into an array (always adding) and return a cont cptr
     if the string is already there we just return the already existing pointer */
    [_lock lock];
    NSData *d = _dict[str];
    if(d)
    {
        [_lock unlock];
        return     d.bytes;
    }
	const char *cptr = [str cStringUsingEncoding:NSASCIIStringEncoding];
	unsigned long len = strlen(cptr);
    d = [NSData dataWithBytes:cptr length:len+1]; /* We  include the null byte */
    _dict[str] = d;
	[_lock unlock];
	return 	d.bytes;
}
@end
