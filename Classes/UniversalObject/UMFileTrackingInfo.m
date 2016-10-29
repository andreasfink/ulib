//
//  UMFileTrackingInfo.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMFileTrackingInfo.h"
#import "UMFileTracker.h"
#import "UMHistoryLog.h"

/*!
 @class UMFileTrackingInfo
 @brief A object holding the data used by UMFileTracker.
 */

@implementation UMFileTrackingInfo

- (NSString *)key
{
    if (type == UMFileTrackingInfo_typeFILE)
    {
        return [UMFileTracker keyFromFILE:f];
    }
    return [UMFileTracker keyFromFdes:fdes];
}

-(UMFileTrackingInfo *)initWithDescriptor:(int)desc file:(NSString *)file line:(long)line func:(NSString *)func
{
    self = [super init];
    if(self)
    {
        _history =[[UMHistoryLog alloc]init];
        type = UMFileTrackingInfo_typeFDES;
        fdes = desc;
        locationFile = file;
        locationLine = line;
        locationFunction = func;
    }
    return self;
}

-(UMFileTrackingInfo *)initWithPipe:(int)desc
             file:(NSString *)file
             line:(long)line
             func:(NSString *)func
{
    self = [super init];
    if(self)
    {
        _history =[[UMHistoryLog alloc]init];
        type = UMFileTrackingInfo_typePIPE;
        fdes = desc;
        locationFile = file;
        locationLine = line;
        locationFunction = func;
    }
    return self;
}

-(UMFileTrackingInfo *)initWithSocket:(int)desc
                                 file:(NSString *)file
                                 line:(long)line
                                 func:(NSString *)func
{
    self = [super init];
    if(self)
    {
        _history =[[UMHistoryLog alloc]init];
        type = UMFileTrackingInfo_typeSOCKET;
        fdes = desc;
        locationFile = file;
        locationLine = line;
        locationFunction = func;
    }
    return self;
}

-(UMFileTrackingInfo *)initWithFile:(FILE *)f1 file:(NSString *)file line:(long)line func:(NSString *)func
{
    self = [super init];
    if(self)
    {
        _history =[[UMHistoryLog alloc]init];
        type = UMFileTrackingInfo_typeFILE;
        f = f1;
        locationFile = file;
        locationLine = line;
        locationFunction = func;
    }
    return self;
}

- (NSString *)descriptionWithIndex:(int)index
{
    @synchronized(self)
    {
        NSMutableString *s = [[NSMutableString alloc]init];
        switch(type)
        {
            case UMFileTrackingInfo_typeFDES:
                [s appendFormat:@"FDES:%d\r\n",fdes];
                break;
            case UMFileTrackingInfo_typeFILE:
                [s appendFormat:@"FILE:%p\r\n",f];
                break;
            case UMFileTrackingInfo_typePIPE:
                [s appendFormat:@"PIPE:%d\r\n",fdes];
                break;
            case UMFileTrackingInfo_typeSOCKET:
                [s appendFormat:@"SOCKET:%d\r\n",fdes];
                break;
        }
        [s appendFormat:@"%d:%@:%ld:%@\r\n",index,locationFile,(long)locationLine,locationFunction];
        if(_history)
        {
            NSArray *logEntries = [_history getLogArrayWithOrder:YES];
            for(NSString *entry in logEntries)
            {
                [s appendFormat:@"    %@\r\n",entry];
            }
        }
        return s;
    }
}

- (void)addLog:(NSString *)message  file:(const char *)file
                                    line:(long)line
                                    func:(const char *)func
{
    @synchronized(self)
    {
        [self addObjectHistory:message.UTF8String file:file line:line function:func];
    }
}

- (void)addObjectHistory:(const char *)message
                    file:(const char *)file
                    line:(long)line
                function:(const char *)func
{
    @synchronized(self)
    {
        NSString *s = [NSString stringWithFormat:@"%08lX file:%s, line:%ld, func.%s: %s",(unsigned long)self,file,line,func,message];
        [_history addLogEntry:s];
    }
}

@end
