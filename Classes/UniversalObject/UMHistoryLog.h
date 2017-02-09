//
//  UMHistoryLog.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"
@class UMHistoryLogEntry;
#define MAX_UMHISTORY_LOG   10240

/*!
 @class UMHistoryLog
 @brief A object to hold the last N log entries of something. N by default is 10240 but can be instantiated with different values. You can log to memory this way and display the last events

 */

@interface UMHistoryLog : UMObject
{
    NSMutableArray  *entries;
    int max;
}

- (UMHistoryLog *)init;
- (UMHistoryLog *)initWithMaxLines:(int)maxlines;
- (UMHistoryLog *)initWithString:(NSString *)s;
- (void)addObject:(id)entry;
- (void)addLogEntry:(NSString *)entry;
- (void)addPrintableString:(NSString *)s;
- (NSArray *)getLogArrayWithOrder:(BOOL)forward;
- (NSString *)getLogForwardOrder;
- (NSString *)getLogBackwardOrder;
- (NSString *)stringLines;

@end
