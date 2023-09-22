//
//  UMRedisStatus.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>

@interface UMRedisStatus : UMObject
{
    BOOL    _ok;
    BOOL    _exceptionRaised;
    NSString *_statusString;
}

@property (readwrite,assign)    BOOL    ok;
@property (readwrite,assign)    BOOL    exceptionRaised;
@property (readwrite,strong)    NSString *statusString;

@end
