//
//  UMBackgrounderWithQueues.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMBackgrounderWithQueues.h"
#import "UMQueue.h"
#import "UMTask.h"
#import "UMSleeper.h"
#import "UMLock.h"

@implementation UMBackgrounderWithQueues

- (UMBackgrounderWithQueues *)initWithSharedQueues:(NSArray *)q
                                              name:(NSString *)n
                                       workSleeper:(UMSleeper *)ws;
{
    self = [super initWithName:n workSleeper:ws];
    if(self)
    {
        _queues = q;
        sharedQueue = YES;
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
        NSUInteger n = _queues.count;
        NSUInteger i;
        for(i=0;i<n;i++)
        {
            UMQueue *thisQueue = [_queues objectAtIndex:i];
            UMTask *task = [thisQueue getFirst];
            if(task)
            {
                if(enableLogging)
                {
                    NSLog(@"%@: got task %@ on queue %d",self.name,task.name,(int)i);
                }
                @autoreleasepool
                {
                    _lastTask = task.name;
                    [task runOnBackgrounder:self];
                }
                ulib_set_thread_name([NSString stringWithFormat:@"%@ (idle)",self.name]);
                return 1;
            }
        }
    }
    return 0;
}
@end
