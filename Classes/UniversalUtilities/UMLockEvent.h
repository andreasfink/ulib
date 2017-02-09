//
//  UMLockEvent.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"

@interface UMLockEvent : UMObject
{
    const char *action;
    const char *file;
    long line;
    const char *func;
    long long microsecond_time;
    uint64_t threadId;
    NSString *threadName;
    NSString *backtrace;
}

@property(readwrite,strong) NSString *threadName;
@property(readwrite,strong) NSString *backtrace;


- (UMLockEvent *)initFromFile:(const char *)pfile line:(long)pline function:(const char *)pfunc action:(const char *)paction
                     threadId:(uint64_t)ptid threadName:(NSString *)pname bt:(BOOL) usebt;

@end
