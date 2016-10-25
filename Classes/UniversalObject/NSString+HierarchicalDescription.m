//
//  NSString+HierarchicalDescription.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "NSString+HierarchicalDescription.h"


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

@end
