//
//  UMLockEvent.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMLockEvent.h"
#import "UMUtil.h"
#import "UMThroughputCounter.h"

@implementation UMLockEvent

@synthesize backtrace;
@synthesize threadName;

-(UMLockEvent *)initFromFile:(const char *)pfile line:(long)pline function:(const char *)pfunc action:(const char *)paction threadId:(uint64_t)ptid threadName:(NSString *)pname bt:(BOOL) usebt
{
    self = [super init];
    if(self)
    {
        action = paction;
        file = pfile;
        line = pline;
        func = pfunc;
        microsecond_time = [UMThroughputCounter microsecondTime];
        threadId = ptid;
        self.threadName = pname;
        if(usebt)
        {
            self.backtrace = UMBacktrace(NULL,0);
        }
    }
    return self;
}

@end
