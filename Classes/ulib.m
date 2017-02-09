//
//  ulib.m
//  ulib
//
//  Created by Andreas Fink on 10/05/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "ulib.h"
#import "../version.h"

@implementation ulib

@synthesize fileTracker;

+ (NSString *) ulib_version
{
    return @VERSION;
}

+ (NSString *) ulib_build
{
    return @BUILD;
}

+ (NSString *) ulib_builddate
{
    return @BUILDDATE;
}

+ (NSString *) ulib_compiledate
{
    return @COMPILEDATE;
}

@end
