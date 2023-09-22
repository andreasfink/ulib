//
//  UMBackgrounderWithQueue.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMBackgrounderWithQueue.h>
#import <ulib/UMQueueSingle.h>
#import <ulib/UMTaskQueueTask.h>
#import <ulib/UMSleeper.h>
#import <ulib/UMThreadHelpers.h>

@implementation UMBackgrounderWithQueue

- (UMBackgrounder *)init
{
    return [self initWithName:@"(unnamed)"];
}

- (UMBackgrounderWithQueue *)initWithName:(NSString *)n
{
    self = [super initWithName:n workSleeper:NULL];
    if(self)
    {
        _queue = [[UMQueueSingle alloc]init];
        _sharedQueue = NO;
    }
    return self;
}

- (UMBackgrounderWithQueue *)initWithSharedQueue:(UMQueueSingle *)q
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
        UMTaskQueueTask *task = [_queue getFirst];
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
