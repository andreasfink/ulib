//
//  UMConfigDatabasePool.m
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

#import <ulib/UMConfigDatabasePool.h>
#import <ulib/UMConfigMacroHelper.h>


@implementation UMConfigDatabasePool

+ (NSString *)groupName
{
    return @"database-pool";
}

- (NSString *)groupName
{
    return [UMConfigDatabasePool groupName];
}


- (UMConfigDatabasePool *)initWithConfig:(NSDictionary *)dict
{
    self = [super initWithConfig:dict];
    if(self)
    {
        [self setConfig:dict];
    }
    return self;
}


- (void)appendConfigToString:(NSMutableString *)o
{
    [super appendConfigToString:o];
#include <ulib/UMConfig_macroAppendConfig.h>
#include <ulib/UMConfigDatabasePool.def.h>
#include <ulib/UMConfig_macroClear.h>
}


- (UMSynchronizedSortedDictionary *)config
{
    UMSynchronizedSortedDictionary *o = [super config];
#include <ulib/UMConfig_macroAppendDict.h>
#include <ulib/UMConfigDatabasePool.def.h>
#include <ulib/UMConfig_macroClear.h>
    return o;
}

- (void)setConfig:(NSDictionary *)o
{
    [self setSuperConfig:o];
#include <ulib/UMConfig_macroSetConfigFromDict.h>
#include <ulib/UMConfigDatabasePool.def.h>
#include <ulib/UMConfig_macroClear.h>
}


- (UMConfigDatabasePool *)copyWithZone:(NSZone *)zone
{
    UMSynchronizedSortedDictionary *currentConfig = [self config];
    return [[UMConfigDatabasePool allocWithZone:zone]initWithConfig:[currentConfig dictionaryCopy]];
}
@end



