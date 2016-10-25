//
//  UMConfigGroup.m
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMConfigGroup.h"

@implementation UMConfigGroup

@synthesize configFile;
@synthesize line;
@synthesize vars;
@synthesize name;


- (UMConfigGroup *)init
{
    if ((self = [super init]))
    {
        name = [[NSString alloc] init];
        vars = [NSMutableDictionary dictionary];
        configFile = [[NSString alloc] init];
    }
    
    return self;
}

- (NSString *)getString:(NSString *)n
{
    return [vars objectForKey:n];
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
