//
//  NSArray+HierarchicalDescription.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "NSArray+HierarchicalDescription.h"
#import "NSString+HierarchicalDescription.h"
#import "NSObject+HierarchicalDescription.h"

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

@end
