//
//  UMPlugin.m
//  ulib
//
//  Created by Andreas Fink on 21.04.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMPlugin.h"

@implementation UMPlugin


+ (NSString *)name
{
    return @"undefined";
}

+ (NSDictionary *)info
{
    return @{
             @"name" : [UMPlugin name],
             @"type" : @"undefined"
             };
}

- (void)configUpdate
{

}

- (NSArray *)config
{
    return [_config copy];
}

- (int)setConfig:(NSDictionary *)cfg /* returns 0 on Success */
{
    _config = cfg;
    [self configUpdate];
    return 0;
}


@end

