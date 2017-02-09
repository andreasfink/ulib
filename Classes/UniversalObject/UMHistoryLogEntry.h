//
//  UMHistoryLogEntry.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"


/*!
 @class UMHistoryLogEntry
 @brief An entry into a UMHistoryLog

 */

@class UMHistoryLogEntry;

@interface UMHistoryLogEntry : UMObject
{
    NSString            *log;
}

- (UMHistoryLogEntry *)initWithLog:(NSString *)newlog;

@property(readwrite,strong) NSString            *log;

@end
