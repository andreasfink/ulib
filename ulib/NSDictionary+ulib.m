//
//  NSDictionary+HiearchicalDescription.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSDictionary+ulib.h>
#import <ulib/NSString+ulib.h>
#import <ulib/UMJsonWriter.h>
#import <ulib/UMJsonParser.h>

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


- (NSString *)logDescription
{
    NSMutableString *desc;
    id hitem, vitem;
    long i, len;
    NSArray *values;
    NSArray *keys;
    
    desc = [[NSMutableString alloc] init];
    i = 0;
    len = [self count];
    values = [self allValues];
    keys = [self allKeys];
    
    while (i < len)
    {
        vitem = [values objectAtIndex:i];
        hitem = [keys objectAtIndex:i];
        ++i;
        [desc appendFormat:@"%@: %@", hitem, vitem];
        if (i < len)
            [desc appendString:@" hend "];
    }
    [desc appendString:@" tend "];
    
    return desc;
}

- (NSMutableArray *) toArray;
{
    NSMutableArray *a;
    id hitem, vitem;
    long i, len;
    NSArray *values;
    NSArray *keys;
    NSString *aitem;
    
    a = [NSMutableArray array];
    i = 0;
    len = [self count];
    values = [self allValues];
    keys = [self allKeys];
    
    while (i < len)
    {
        vitem = [values objectAtIndex:i];
        hitem = [keys objectAtIndex:i];
        aitem = [NSString stringWithFormat:@"%@: %@", hitem, vitem];
        [a addObject:aitem];
        ++i;
    }
    
    return a;
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
    writer.humanReadable = NO;
    NSString *json = [writer stringWithObject:self];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

- (BOOL)configEnabledWithYesDefault
{

    id enable = self[@"enable"];
    if(enable == NULL)
    {
        return YES;
    }
    if([enable isKindOfClass:[NSString class]])
    {
        NSString *s = (NSString *)enable;
        if(s.length == 0)
        {
            return YES;
        }
    }
    return [enable boolValue];
}

- (NSString *)configName
{
    return [self[@"name"] stringValue];
}

- (NSString *)configEntry:(NSString *)index
{
    return [self[index] stringValue];
}

@end
