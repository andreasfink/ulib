//
//  UMTimerBackgrounder.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMTimerBackgrounder.h"
#import "UMLock.h" /* for ulib_set_thread_name */
#import "UMTimer.h"
#import "UMSleeper.h"
#import "UMUtil.h"

static UMTimerBackgrounder *sharedTimerBackgrounder = NULL;

@implementation UMTimerBackgrounder

+(UMTimerBackgrounder *)sharedInstance
{
    if(sharedTimerBackgrounder==NULL)
    {
        sharedTimerBackgrounder = [[UMTimerBackgrounder alloc]init];
        [sharedTimerBackgrounder startBackgroundTask];
    }
    return sharedTimerBackgrounder;
}

- (UMTimerBackgrounder *)init
{
    self = [super initWithName:@"UMTimerBackgrounder"workSleeper:NULL];
    if(self)
    {
        timers = [[NSMutableArray alloc] init];
        _lock = [[UMMutex alloc]init];
    }
    return self;
}

- (void)addTimer:(UMTimer *)t
{
    [_lock lock];
    @try
    {
        if ([t objectToCall] == NULL)
        {
            @throw([NSException exceptionWithName:@"INVALID_TIMER"
                                           reason:@"trying to add timer with no target"
                                         userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
        }
        [timers removeObject:t]; /* in case its already there */
        [timers addObject:t];
    }
    @finally
    {
        [_lock unlock];
    }
}

- (void)removeTimer:(UMTimer *)t
{
    if(t)
    {
        [_lock lock];
        [timers removeObject:t];
        [_lock unlock];
    }
}


- (UMMicroSec)backgroundWorkReturningSleepTime
{
    NSMutableArray *dueTimers = [[NSMutableArray alloc] init];
    int workDone = 0;

    UMMicroSec now = ulib_microsecondTime();
    UMMicroSec nextWakeupIn = 100000; /* we wake up at least every 100ms or earlier */

    [_lock lock];
    @try
    {
        for(UMTimer *t in timers)
        {
            if([t isExpired:now])
            {
                [dueTimers addObject:t];
                workDone++;
            }
            else
            {
                UMMicroSec timeLeft = [t timeLeft:now];
                if(timeLeft < nextWakeupIn)
                {
                    nextWakeupIn = timeLeft;
                }
            }
        }
        for(UMTimer *t in dueTimers)
        {
            [timers removeObject:t];
        }
        for(UMTimer *t in dueTimers)
        {
            if([t isRunning])
            {
                [t fire];
            }
        }
    }
    @finally
    {
        [_lock unlock];
    }
    return nextWakeupIn;
}


- (void)backgroundTask
{
    BOOL mustQuit = NO;
    long long sleepTime = 100000LL; /* 100 ms */
    
    @autoreleasepool
    {
        ulib_set_thread_name(@"UMTimerBackgrounder");
        if(runningStatus != UMBackgrounder_startingUp)
        {
            return;
        }
        if(workSleeper==NULL)
        {
            self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
            [self.workSleeper prepare];
        }
        runningStatus = UMBackgrounder_running;
        [control_sleeper wakeUp:UMSleeper_StartupCompletedSignal];
        [self backgroundInit];
    }
    while((runningStatus == UMBackgrounder_running) && (mustQuit==NO))
    {
        @autoreleasepool
        {
            /* waiting for work */
            sleepTime = [self backgroundWorkReturningSleepTime];
            if(sleepTime < 0)
            {
                mustQuit = YES;
            }
            else
            {
                int signal = [workSleeper sleep:sleepTime wakeOn:(UMSleeper_HasWorkSignal | UMSleeper_ShutdownOrderSignal) ];
                if(signal & UMSleeper_ShutdownOrderSignal)
                {
                    mustQuit = YES;
                }
            }
        }
    }
    @autoreleasepool
    {
        ulib_set_thread_name(@"UMTimerBackgrounder (terminating)");
        runningStatus = UMBackgrounder_notRunning;
        self.workSleeper = NULL;
        [control_sleeper wakeUp:UMSleeper_ShutdownCompletedSignal];
    }
}


@end
