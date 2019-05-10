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
		_lock = [[UMMutex alloc]init];
		_dict = [[NSMutableDictionary alloc]init];
	}
	return self;
}

- (const char *)asciiStringFromNSString:(NSString *)str
{
	const char *cptr ="\0";
	unsigned long len = 0;

	[_lock lock];
	NSData *d = _dict[str];
	if(d==NULL)
	{
		cptr = [str cStringUsingEncoding:NSASCIIStringEncoding];
		len = strlen(cptr);
		d = [NSData dataWithBytes:cptr length:len+1]; /* We  include the null byte */
		_dict[str] = d;
		cptr = d.bytes;
	}
	[_lock unlock];
	return cptr;
}
@end
