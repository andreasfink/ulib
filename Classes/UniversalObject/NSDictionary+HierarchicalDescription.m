//
//  NSDictionary+HiearchicalDescription.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "NSDictionary+HierarchicalDescription.h"
#import "NSString+HierarchicalDescription.h"

@implementation NSDictionary (HiearchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	NSMutableString *output;
	NSArray *keys;
	
	output = [NSMutableString stringWithFormat:@"%@Dictionary\n",prefix];
	prefix = [prefix increasePrefix];

	keys = [self allKeys];
	for(id key in keys)
	{
		id value = [self valueForKey:key];
		[output appendFormat:@"%@Key: %@\n",prefix,[key hierarchicalDescriptionWithPrefix:@""]];
		[output appendFormat:@"%@Value: %@\n",prefix,[value hierarchicalDescriptionWithPrefix:@""]];
	}
	return output;
}

@end
