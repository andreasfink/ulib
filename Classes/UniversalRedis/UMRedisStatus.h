//
//  UMRedisStatus.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@interface UMRedisStatus : UMObject
{
    BOOL    ok;
    BOOL    exceptionRaised;
    NSString *statusString;
}

@property (readwrite,assign)    BOOL    ok;
@property (readwrite,assign)    BOOL    exceptionRaised;
@property (readwrite,strong)    NSString *statusString;

@end
