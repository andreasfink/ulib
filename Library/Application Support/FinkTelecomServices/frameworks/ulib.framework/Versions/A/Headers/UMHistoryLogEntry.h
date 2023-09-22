//
//  UMHistoryLogEntry.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <ulib/UMObject.h>


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
- (NSString *)stringValueWithoutDate;

@property(readwrite,strong,atomic) NSDate          *date;
@property(readwrite,strong,atomic) NSString        *log;

@end
