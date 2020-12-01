//
//  UMBackgrounderWithQueues.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMBackgrounderWithQueues.h"
#import "UMQueueSingle.h"
#import "UMTaskQueueTask.h"
#import "UMSleeper.h"
#import "UMThreadHelpers.h"
#import "UMQueueMulti.h"

@implementation UMBackgrounderWithQueues

- (UMBackgrounderWithQueues *)initWithSharedQueues:(UMQueueMulti *)q
                                              name:(NSString *)n
                                       workSleeper:(UMSleeper *)ws;
{
    self = [super initWithName:n workSleeper:ws];
    if(self)
    {
        _multiQueue = q;
        _sharedQueue = YES;
    }
    return self;
}

- (void)backgroundInit
{
    ulib_set_thread_name([NSString stringWithFormat:@"%@ (idle)",self.name]);
}

- (void)backgroundExit
{
    ulib_set_thread_name([NSString stringWithFormat:@"%@ (terminating)",self.name]);
}

- (int)work
{
    int r = 0;

    @autoreleasepool
    {
        UMTaskQueueTask *task = [_multiQueue getFirst];
        if(task)
        {
            ulib_set_thread_name(task.name);
            if(_enableLogging)
            {
                NSLog(@"%@: got task %@",self.name,task.name);
            }
            _lastTask = task.name;
            [_multiQueue startWork];
            @autoreleasepool
            {
                [task runOnBackgrounder:self];
            }
            [_multiQueue endWork];
            ulib_set_thread_name([NSString stringWithFormat:@"%@ (idle)",self.name]);
            r = 1;
        }
    }
    return r;
}
@end
