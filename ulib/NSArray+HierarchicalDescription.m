//
//  NSArray+HierarchicalDescription.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSArray+HierarchicalDescription.h>
#import <ulib/NSString+HierarchicalDescription.h>
#import <ulib/NSObject+HierarchicalDescription.h>

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

@end
