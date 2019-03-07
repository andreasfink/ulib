//
//  UMTimerBackgrounder.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMTimerBackgrounder.h"
#import "UMThreadHelpers.h"
#import "UMTimer.h"
#import "UMSleeper.h"
#import "UMUtil.h"

static UMTimerBackgrounder *_sharedTimerBackgrounder = NULL;

@implementation UMTimerBackgrounder

+ (UMTimerBackgrounder *)sharedInstance
{
    @synchronized (self)
    {
        if(_sharedTimerBackgrounder==NULL)
        {
            _sharedTimerBackgrounder = [[UMTimerBackgrounder alloc]init];
            [_sharedTimerBackgrounder startBackgroundTask];
        }
    }
    return _sharedTimerBackgrounder;
}

- (UMTimerBackgrounder *)init
{
    self = [super initWithName:@"UMTimerBackgrounder" workSleeper:NULL];
    if(self)
    {
        _timers = [[NSMutableArray alloc] init];
        _timersLock =[[UMMutex alloc]initWithName:@"timers-lock"];
    }
    return self;
}

- (void)addTimer:(UMTimer *)t
{
    if (t.objectToCall == NULL)
    {
        @throw([NSException exceptionWithName:@"INVALID_TIMER"
                                       reason:@"trying to add timer with no target"
                                     userInfo:@{    @"backtrace":   UMBacktrace(NULL,0) }]);
    }
    [_timersLock lock];
    [_timers removeObject:t]; /* in case its already there */
    [_timers addObject:t];
    [_timersLock unlock];
}

- (void)removeTimer:(UMTimer *)t
{
    if(t)
    {
        [_timersLock lock];
        [_timers removeObject:t];
        [_timersLock unlock];
    }
}


- (UMMicroSec)backgroundWorkReturningSleepTime
{
    NSMutableArray *dueTimers = [[NSMutableArray alloc] init];
    int workDone = 0;

    UMMicroSec now = ulib_microsecondTime();
    UMMicroSec nextWakeupIn = 1000000; /* we wake up at least every second or earlier */
    [_timersLock lock];
    for(UMTimer *t in _timers)
    {
        UMMicroSec timeLeft = [t timeLeft:now];
        if(timeLeft < 0)
        {
            [dueTimers addObject:t];
            workDone++;
        }
        else if(timeLeft < nextWakeupIn)
        {
            nextWakeupIn = timeLeft;
        }
    }
    for(UMTimer *t in dueTimers)
    {
        [_timers removeObject:t];
    }
    [_timersLock unlock];
    for(UMTimer *t in dueTimers)
    {
        if([t isRunning])
        {
            [t fire];
        }
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
        if(_runningStatus != UMBackgrounder_startingUp)
        {
            return;
        }
        if(_workSleeper==NULL)
        {
            self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
            [self.workSleeper prepare];
        }
        _runningStatus = UMBackgrounder_running;
        [self.control_sleeper wakeUp:UMSleeper_StartupCompletedSignal];
        [self backgroundInit];
    }
    while((_runningStatus == UMBackgrounder_running) && (mustQuit==NO))
    {
        @autoreleasepool
        {
            /* waiting for work */
            sleepTime = [self backgroundWorkReturningSleepTime];
            if(sleepTime < 0)
            {
                mustQuit = YES;
            }
            else if(sleepTime > 1000LL) /* sleeping less than 1ms is an overkill. So this would turn into a busy loop for 1ms */
            {
                int signal = [_workSleeper sleep:sleepTime wakeOn:(UMSleeper_HasWorkSignal | UMSleeper_ShutdownOrderSignal) ];
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
        _runningStatus = UMBackgrounder_notRunning;
        self.workSleeper = NULL;
        [self.control_sleeper wakeUp:UMSleeper_ShutdownCompletedSignal];
    }
}

@end
