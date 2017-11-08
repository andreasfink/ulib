//
//  UMLayerUserProtocol.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMLogLevel.h"

@class UMLogFeed;

@protocol UMLayerUserProtocol<NSObject>

- (UMLogFeed *)logFeed;
- (UMLogLevel)logLevel;

@end
