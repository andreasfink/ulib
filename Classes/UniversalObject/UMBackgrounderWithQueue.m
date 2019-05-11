//
//  UMBackgrounderWithQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMBackgrounderWithQueue.h"
#import "UMQueue.h"
#import "UMTask.h"
#import "UMSleeper.h"
#import "UMThreadHelpers.h"

@implementation UMBackgrounderWithQueue

- (UMBackgrounderWithQueue *)initWithName:(NSString *)n
{
    self = [super initWithName:n workSleeper:NULL];
    if(self)
    {
        _queue = [[UMQueue alloc]init];
        _sharedQueue = NO;
    }
    return self;
}

- (UMBackgrounderWithQueue *)initWithSharedQueue:(UMQueue *)q
                                            name:(NSString *)n
                                     workSleeper:(UMSleeper *)ws
{
    self = [super initWithName:n workSleeper:ws];
    if(self)
    {
        _queue = q;
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
    @autoreleasepool
    {
        UMTask *task = [_queue getFirst];
        if(task)
        {
            if(_enableLogging)
            {
                NSLog(@"%@: got task %@",self.name,task);
            }
            @autoreleasepool
            {
                [task runOnBackgrounder:self];
            }
            ulib_set_thread_name([NSString stringWithFormat:@"%@ (idle)",self.name]);
            return 1;
        }
    }
    return 0;
}
@end
