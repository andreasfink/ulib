//
//  UMFileTracker.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMFileTrackingInfo.h"

@class UMFileTrackingInfo;
@class ulib;

@interface UMFileTracker : UMObject
{
    NSMutableDictionary *fileTrackingInfos;
}

- (void)add:(UMFileTrackingInfo *)info;
- (void) closeFdes:(int)fdes;
- (void) closeFILE:(FILE *)f;
+ (NSString *)keyFromFdes:(int)fdes;
+ (NSString *)keyFromFILE:(FILE *)f;
- (UMFileTrackingInfo *)infoForFdes:(int)fdes;
- (UMFileTrackingInfo *)infoForFile:(FILE *)f;

+ (UMFileTracker *)sharedInstance;
+ (UMFileTracker *)createSharedInstance;

@end


