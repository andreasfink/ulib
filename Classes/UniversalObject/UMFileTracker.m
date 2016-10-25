//
//  UMFileTracker.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMFileTracker.h"
#import "UMFileTrackingInfo.h"
#import "UMAssert.h"
#include <sys/time.h>
#include <sys/resource.h>

@class UMFileTracker;

static UMFileTracker *_global_file_tracker = nil;

@implementation UMFileTracker


+ (UMFileTracker *)sharedInstance
{
    return _global_file_tracker;
}

+ (UMFileTracker *)createSharedInstance
{
    if(_global_file_tracker == NULL)
    {
        _global_file_tracker = [[UMFileTracker alloc]init];
    }
    return _global_file_tracker;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        fileTrackingInfos = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (void)add:(UMFileTrackingInfo *)info
{
    @synchronized(self)
    {
        NSString *key = info.key;
        UMAssert(key != NULL,@"key can not be null");
        fileTrackingInfos[key] = info;
    }
}

- (UMFileTrackingInfo *)infoForFdes:(int)fdes
{
    @synchronized(self)
    {
        NSString *key = [UMFileTracker keyFromFdes:fdes];
        UMAssert(key != NULL,@"key can not be null");
        UMFileTrackingInfo *ti = fileTrackingInfos[key];
        return ti;
    }
}

- (UMFileTrackingInfo *)infoForFile:(FILE *)f
{
    @synchronized(self)
    {
        NSString *key = [UMFileTracker keyFromFILE:f];
        UMFileTrackingInfo *ti = fileTrackingInfos[key];
        return ti;
    }
}


- (void) closeFdes:(int)fdes
{
    @synchronized(self)
    {
        [fileTrackingInfos removeObjectForKey:[UMFileTracker keyFromFdes:fdes]];
    }
}

- (void) closeFILE:(FILE *)f
{
    @synchronized(self)
    {
        [fileTrackingInfos removeObjectForKey:[UMFileTracker keyFromFILE:f]];
    }
}

+ (NSString *)keyFromFdes:(int)fdes
{
    return  [NSString stringWithFormat:@"%d",fdes];
}

+ (NSString *)keyFromFILE:(FILE *)f
{
    return [NSString stringWithFormat:@"F:%p",f];
}

- (NSString *)description
{
    @synchronized(self)
    {
        struct rlimit r;

        NSMutableString *s = [[NSMutableString alloc]init];
        [s appendFormat:@"UMFileTracker: %@\n",[super description]];
        NSUInteger count = [fileTrackingInfos count];
        [s appendFormat:@"Current Count: %ld\n",(long)count];
        getrlimit(RLIMIT_NOFILE, &r);
        [s appendFormat:@"Current open number of files limit: %ld\n",(long)r.rlim_cur];
        int i =0;
        for (NSString *key in fileTrackingInfos)
        {
            UMFileTrackingInfo *ti = fileTrackingInfos[key];
            [s appendString: [ti descriptionWithIndex:++i]];
        }
        return s;
    }
}
@end
