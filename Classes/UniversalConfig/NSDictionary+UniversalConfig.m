//
//  NSDictionary+UniversalConfig.m
//  ulib
//
//  Created by Andreas Fink on 07.02.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "NSDictionary+UniversalConfig.h"
#import "NSString+UniversalObject.h"

@implementation NSDictionary (UniversalConfig)

- (BOOL)configEnabledWithYesDefault
{
    NSString *enable = self[@"enable"];
    if(enable == NULL)
    {
        return YES;
    }
    if(enable.length == 0)
    {
        return YES;
    }
    return [self[@"enable"] boolValue];
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
