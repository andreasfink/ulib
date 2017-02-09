//
//  UMTestCase.h
//  ulib
//
//  Created by Aarno Syvänen on 20.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ulib/UMLogHandler.h"

@class UMLogEntry;

@interface UMTestHandler : UMLogHandler

- (long)LogAnEntryAndGiveSize:(UMLogEntry *)logEntry;

@end
