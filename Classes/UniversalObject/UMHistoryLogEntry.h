//
//  UMHistoryLogEntry.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@class UMHistoryLogEntry;

@interface UMHistoryLogEntry : UMObject
{
    NSString            *log;
}

- (UMHistoryLogEntry *)initWithLog:(NSString *)newlog;

@property(readwrite,strong) NSString            *log;

@end
