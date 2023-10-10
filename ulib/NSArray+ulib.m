//
//  NSArray+ulib.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSArray+ulib.h>
#import <ulib/NSString+ulib.h>
#import <ulib/NSObject+ulib.h>
#import <ulib/UMJsonWriter.h>
#import <ulib/UMJsonParser.h>

@implementation NSArray (HierarchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	NSMutableString *output;
	
	output = [NSMutableString stringWithFormat:@"%@Array\n",prefix];
	prefix = [prefix increasePrefix];
	for(NSObject *obj in self)
	{
		[output appendString:[obj hierarchicalDescriptionWithPrefix:prefix]];
	}
	return output;
}

- (NSArray<NSString *>*)sortedStringsArray
{
    return [self  sortedArrayUsingComparator: ^(NSString *a, NSString *b)  {return [a compare:b];} ];
}

- (BOOL)containsString:(NSString *)str
{
    for(NSString *s in self)
    {
        if([str isEqualToString:s])
        {
            return YES;
        }
    }
    return NO;
}


- (NSArray<NSNumber *>*)sortedNumbersArray
{
    return [self  sortedArrayUsingComparator: ^(NSNumber *a, NSNumber *b)  {return [a compare:b];} ];
}


- (NSString *)jsonString
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

- (NSString *)jsonCompactString
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


@end
