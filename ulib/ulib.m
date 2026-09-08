//
//  ulib.m
//  ulib
//
//  Created by Andreas Fink on 10/05/14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/ulib.h>
#include "../version.h"

NSString *ulib_version(void)
{
    return @(VERSION);
}

NSString *ulib_build(void)
{
    return @(BUILD);
}

NSString *ulib_builddate(void)
{
    return @(BUILDDATE);
}

NSString *ulib_compiledate(void)
{
    return @(COMPILEDATE);
}

