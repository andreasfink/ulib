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
    NSDate              *_date;
    NSString            *_log;
}

- (UMHistoryLogEntry *)initWithLog:(NSString *)newlog;
- (NSString *)stringValue;

@property(readwrite,strong,atomic) NSDate          *date;
@property(readwrite,strong,atomic) NSString        *log;

@end
