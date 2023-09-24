//
//  UMConfigGroup.m
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMConfigGroup.h>

@implementation UMConfigGroup


- (UMConfigGroup *)init
{
    if ((self = [super init]))
    {
        _name = [[NSString alloc] init];
        _vars = [NSMutableDictionary dictionary];
        _configFile = [[NSString alloc] init];
    }
    
    return self;
}

- (NSString *)getString:(NSString *)n
{
    return [_vars objectForKey:n];
}

- (NSInteger)getInteger:(NSString *)n
{
    return [[self getString:n]intValue];
}

- (BOOL)getBoolean:(NSString *)n
{
    return [[self getString:n]boolValue];
}

@end
