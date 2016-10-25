//
//  UMHistoryLog.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"
@class UMHistoryLogEntry;
#define MAX_UMHISTORY_LOG   10240

@interface UMHistoryLog : UMObject /* can not be derivating from UMObject as it uses itself */
{
    NSMutableArray  *entries;
//    UMHistoryLogEntry *first;
//    UMHistoryLogEntry *last;
    int max;
 //   int count;
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
