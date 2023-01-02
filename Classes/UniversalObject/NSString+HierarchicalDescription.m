//
//  NSString+HierarchicalDescription.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
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


- (NSString *)htmlEscaped
{
    NSMutableString *out = [[NSMutableString alloc]init];
    NSString *s = [self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    s = [s stringByReplacingOccurrencesOfString:@"\t" withString:@"&Tab;"];
    s = [s stringByReplacingOccurrencesOfString:@"\n" withString:@"&NewLine;"];
    s = [s stringByReplacingOccurrencesOfString:@" " withString:@"&nbsp;"];
    s = [s stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    s = [s stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    s = [s stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    return s;
}
@end
