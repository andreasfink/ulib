//
//  ulib.h
//  ulib
//
//  Created by Andreas Fink on 16.12.2011.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#ifndef ULIB_H
#define ULIB_H 1
#import "UMRegex.h"
#import "UMAssert.h"
#import "UniversalObject.h"
#import "UniversalConfig.h"
#import "UniversalSocket.h"
#import "UniversalHTTP.h"
#import "UniversalJson.h"
#import "UniversalLog.h"
#import "UniversalLayers.h"
#import "UniversalQueue.h"
#import "UniversalUtilities.h"
#import "UniversalRedis.h"
#import "UMFileTrackingMacros.h"
#import "UniversalTokenizer.h"
#import "UniversalPlugin.h"

@interface ulib : NSObject
{
}
@property(readwrite,strong)     UMFileTracker *fileTracker;

+ (NSString *) ulib_version;
+ (NSString *) ulib_build;
+ (NSString *) ulib_builddate;
+ (NSString *) ulib_compiledate;

@end

#endif
