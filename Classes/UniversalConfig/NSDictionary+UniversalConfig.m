//
//  NSDictionary+UniversalConfig.m
//  ulib
//
//  Created by Andreas Fink on 07.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "NSDictionary+UniversalConfig.h"
#import "NSString+UniversalObject.h"

@implementation NSDictionary (UniversalConfig)

- (BOOL)configEnabledWithYesDefault
{
    NSArray *keys = [self allKeys];
    for(id key in keys)
    {
        if([key isEqualToStringCaseInsensitive:@"enable"])
        {
            id entry = self[key];
            if(entry == NULL)
            {
                return YES;
            }
            return [entry boolValue];
        }
    }
    return YES;
}

- (NSString *)configName
{
    NSArray *keys = [self allKeys];
    for(id key in keys)
    {
        if([key isEqualToStringCaseInsensitive:@"name"])
        {
            id entry = self[key];
            if(entry == NULL)
            {
                return NULL;
            }
            return [entry stringValue];
        }
    }
    return NULL;
}

- (NSString *)configEntry:(NSString *)index
{
    NSArray *keys = [self allKeys];
    for(id key in keys)
    {
        if([key isEqualToStringCaseInsensitive:index])
        {
            id entry = self[key];
            if(entry == NULL)
            {
                return NULL;
            }
            return [entry stringValue];
        }
    }
    return NULL;
}

@end
