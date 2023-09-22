//
//  NSDictionary+HiearchicalDescription.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSDictionary+HierarchicalDescription.h>
#import <ulib/NSString+HierarchicalDescription.h>
#import <ulib/NSString+UMHTTP.h>

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

/* takes every string in the dictionary and does urldecode it */
- (NSDictionary *)urldecodeStringValues
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    NSArray *allKeys = [self allKeys];
    for(id key in allKeys)
    {
        id value = [self objectForKey:key];
        if([value isKindOfClass:[NSString class]])
        {
            value = [((NSString *)value) urldecode];
        }
        if(value)
        {
            dict[key] =value;
        }
    }
    return dict;
}

@end
