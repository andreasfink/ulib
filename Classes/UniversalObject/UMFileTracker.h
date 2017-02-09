//
//  UMFileTracker.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMFileTrackingInfo.h"

@class UMFileTrackingInfo;
@class ulib;

/*!
 @class UMFileTracker
 @brief A debugging helper object to track usage of files. Useful if you run out of file descriptors and you cant find which file you opened where and forgot to close.
 This goes togehter with the macros from UMFileTrackingMacros.h:
 
 TRACK_FILE_FOPEN(f,c)
 TRACK_FILE_FCLOSE(f)
 TRACK_FILE_DESCRIPTOR(f,c)
 TRACK_FILE_SOCKET(f,c)
 TRACK_FILE_PIPE(f,c)
 TRACK_FILE_PIPE_FLF(f,c,a,b,d)
 TRACK_FILE_CLOSE(fdes)
 TRACK_FILE_ADD_COMMENT_FOR_FDES(fdes,c)
 TRACK_FILE_ADD_COMMENT_FOR_FILE(f,c)

*/


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


