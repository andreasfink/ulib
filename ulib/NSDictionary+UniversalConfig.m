//
//  NSDictionary+UniversalConfig.m
//  ulib
//
//  Created by Andreas Fink on 07.02.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSDictionary+UniversalConfig.h>
#import <ulib/NSString+UniversalObject.h>

@implementation NSDictionary (UniversalConfig)

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
