//
//  NSData+HiearchicalDescription.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "NSData+HierarchicalDescription.h"
#import "NSString+HierarchicalDescription.h"

@implementation NSData(HiearchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	ssize_t i;
	ssize_t n;
	const uint8_t *ptr;
	
	NSMutableString *s = [NSMutableString stringWithFormat:@"%@NSData",prefix];

	prefix = [prefix increasePrefix];
	
	ptr = [self bytes];
	n   = [self length];
	for(i=0;i<n;i++)
	{
		if((i%16)==0)
			[s appendFormat:@"\n%@",prefix];
		[s appendFormat:@" %02X",ptr[i]];
	}
	[s appendString:@"\n"];
	return s;
}

- (NSString *)dump
{
	return [self stringForDumping];
}

- (NSString *)stringForDumping
{
	ssize_t i;
	ssize_t n;
	const uint8_t *ptr;
	uint8_t	octet;

	ptr = [self bytes];
	n   = [self length];

	NSMutableString *s = [[NSMutableString alloc]init];	
	[s appendFormat:@"NSData [len=%ld] [bytes=",n];
	
	for(i=0;i<n;i++)
	{
		octet = ptr[i];
		[s appendFormat:@" %02X",octet];
	}
	[s appendString:@"]\n"];
	return s;
}

@end
