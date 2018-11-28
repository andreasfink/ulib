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
- (void)setLogFeed:(UMLogFeed *)lf;

- (UMLogLevel)logLevel;
- (void)setLogLevel:(UMLogLevel)ll;

//@property(readwrite,strong) UMLogFeed *logFeed;
//@property(readwrite,assign) UMLogLevel logLevel;

@end
