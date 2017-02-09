//
//  UMFileTrackingInfo.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

typedef enum UMFileTrackingInfo_type
{
    UMFileTrackingInfo_typeFDES = 0,
    UMFileTrackingInfo_typeFILE = 1,
    UMFileTrackingInfo_typePIPE = 2,
    UMFileTrackingInfo_typeSOCKET = 3,
} UMFileTrackingInfo_type;

@interface UMFileTrackingInfo : UMObject
{
    UMHistoryLog *_history;
    UMFileTrackingInfo_type type;
    int fdes;
    FILE *f;
    NSString *locationFile;
    long    locationLine;
    NSString *locationFunction;
}

- (NSString *)key;
- (UMFileTrackingInfo *) initWithDescriptor:(int)desc
                     file:(NSString *)file
                     line:(long)line
                     func:(NSString *)func;

- (UMFileTrackingInfo *) initWithPipe:(int)desc
               file:(NSString *)file
               line:(long)line
               func:(NSString *)func;

- (UMFileTrackingInfo *) initWithSocket:(int)desc
                 file:(NSString *)file
                 line:(long)line
                 func:(NSString *)func;

- (UMFileTrackingInfo *) initWithFile:(FILE *)f1
               file:(NSString *)file
               line:(long)line
               func:(NSString *)func;

- (void)addLog:(NSString *)message
          file:(const char *)file
          line:(long)line
          func:(const char *)func;

- (NSString *)descriptionWithIndex:(int)index;

@end
