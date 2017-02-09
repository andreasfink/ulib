//
//  NSDictionary+HTTP.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "NSDictionary+UMHTTP.h"

@implementation NSDictionary (UMHTTP)

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

@end
