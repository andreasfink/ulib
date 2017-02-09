//
//  UMFileTrackingMacros.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>

#import "UMFileTracker.h"
#import "UMFileTrackingInfo.h"


#define TRACK_FILE_FOPEN(f,c)  \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        UMFileTrackingInfo *fi = [[UMFileTrackingInfo alloc]initWithFile:f file:@(__FILE__) line:(long)__LINE__ func:@(__func__)]; \
        [fi addLog:c file:__FILE__ line:__LINE__ func:__func__]; \
        [ft add:fi ]; \
    } \
}


#define TRACK_FILE_FCLOSE(f) \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        [ft closeFILE:f]; \
    } \
}


#define TRACK_FILE_DESCRIPTOR(f,c)  \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        UMFileTrackingInfo *fi = [[UMFileTrackingInfo alloc]initWithDescriptor:f file:@(__FILE__) line:(long)__LINE__ func:@(__func__)]; \
        [fi addLog:c file:__FILE__ line:__LINE__ func:__func__]; \
        [ft add:fi ]; \
    } \
}

#define TRACK_FILE_SOCKET(f,c)  \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        UMFileTrackingInfo *fi = [[UMFileTrackingInfo alloc]initWithSocket:f file:@(__FILE__) line:(long)__LINE__ func:@(__func__)]; \
        [fi addLog:c file:__FILE__ line:__LINE__ func:__func__]; \
        [ft add:fi ]; \
    } \
}

#define TRACK_FILE_PIPE(f,c)  \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        UMFileTrackingInfo *fi = [[UMFileTrackingInfo alloc]initWithPipe:f file:@(__FILE__) line:(long)__LINE__ func:@(__func__)]; \
        [fi addLog:c file:__FILE__ line:__LINE__ func:__func__]; \
        [ft add:fi]; \
    } \
}

#define TRACK_FILE_PIPE_FLF(f,c,a,b,d)  \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        UMFileTrackingInfo *fi = [[UMFileTrackingInfo alloc]initWithPipe:f file:@(a) line:(long)b func:@(d)]; \
        [fi addLog:c file:a line:b func:d]; \
        [ft add:fi]; \
    } \
}


#define TRACK_FILE_CLOSE(fdes) \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if (ft)\
    { \
        [ft closeFdes:fdes]; \
    } \
}


#define TRACK_FILE_ADD_COMMENT_FOR_FDES(fdes,c) \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        UMFileTrackingInfo *fi = [ft infoForFdes:fdes]; \
        [fi addLog:c file:__FILE__ line:__LINE__ func:__func__]; \
    } \
}

#define TRACK_FILE_ADD_COMMENT_FOR_FILE(f,c) \
{ \
    UMFileTracker *ft = [UMFileTracker sharedInstance]; \
    if(ft) \
    { \
        UMFileTrackingInfo *fi = [ft infoForFILE:f]; \
        [fi addLog:c file:__FILE__ line:__LINE__ func:__func__]; \
    } \
}

