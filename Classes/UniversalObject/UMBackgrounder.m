// 
//  UMBackgrounder.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMBackgrounder.h"
#import "UMSleeper.h"
#import "UMThreadHelpers.h"
#import "UMAssert.h"

#define UMSLEEPER_DEFAULT_SLEEP_TIME 500000LL /* 500ms */

@implementation UMBackgrounder


- (UMBackgrounder *)init
{
    UMAssert(0,@"call initWithName: workSleeper: instead");
    return [self initWithName:@"(unnamed)" workSleeper:NULL];
}

- (UMBackgrounder *)initWithName:(NSString *)n
                     workSleeper:(UMSleeper *)ws
{
    self = [super init];
    if(self)
    {
        if(ws==NULL)
        {
            _workSleeper = [[UMSleeper alloc]initFromFile:__FILE__
                                                      line:__LINE__
                                                  function:__func__];
            [ws prepare];
        }
        else
        {
            _workSleeper = ws;
        }
        self.name = n;
        
        _control_sleeper = [[UMSleeper alloc]initFromFile:__FILE__
                                                    line:__LINE__
                                                function:__func__];
        [_control_sleeper prepare];
        NSString *s = [NSString stringWithFormat:@"UMBackgrounder(%@)",n];
        _startStopLock = [[UMMutex alloc]initWithName:s];
    }
    return self;
}

- (void)startBackgroundTask
{
    @autoreleasepool
    {
        UMAssert(_startStopLock,@"_startStopLock is NULL");
        UMAssert(_control_sleeper,@"_control_sleeper is NULL");
        UMMUTEX_LOCK(_startStopLock);
        @try
        {
            if(self.runningStatus == UMBackgrounder_notRunning)
            {
                self.runningStatus = UMBackgrounder_startingUp;

                [self runSelectorInBackground:@selector(backgroundTask)
                                   withObject:NULL
                                         file:__FILE__
                                         line:__LINE__
                                     function:__func__];
                int i=0;
                while(i<= 10)
                {
                    int s = [_control_sleeper sleep:1000000LL wakeOn:UMSleeper_StartupCompletedSignal]; /* 1s */
                    if(s==UMSleeper_StartupCompletedSignal)
                    {
                        return;
                    }
                    if (s == UMSleeper_Error)
                    {
                        break;
                    }
                    i++;
                }
            }
        }
        @finally
        {
            UMMUTEX_UNLOCK(_startStopLock);
        }
    }
}

- (void)shutdownBackgroundTaskFromWithin
{
    self.runningStatus = UMBackgrounder_shuttingDown;
}

- (void)shutdownBackgroundTask
{
    @autoreleasepool
    {
        UMAssert(_startStopLock,@"_startStopLock is NULL");
        UMAssert(_control_sleeper,@"_control_sleeper is NULL");
        UMMUTEX_LOCK(_startStopLock);
        @try
        {
            if(self.runningStatus != UMBackgrounder_running)
            {
                return;
            }
            
            self.runningStatus = UMBackgrounder_shuttingDown;
            int i=0;
          
            [_workSleeper wakeUp:UMSleeper_ShutdownOrderSignal];
            while((self.runningStatus == UMBackgrounder_shuttingDown) && (i<= 200))
            {
                i++;
                UMSleeper_Signal sig =  [_control_sleeper sleep:UMSLEEPER_DEFAULT_SLEEP_TIME wakeOn:UMSleeper_ShutdownCompletedSignal]; /* 500ms */
                if (sig == UMSleeper_Error)
                {
                    break;
                }
            }
            if((self.runningStatus == UMBackgrounder_shuttingDown) && (i> 200))
            {
                /* it didnt start successfully in 10 seconds. Something is VERY ODD */
                NSLog(@"shutdownBackgroundTask: failed. Background task did not shut down within 10 seconds");
            }
            self.runningStatus = UMBackgrounder_notRunning;
        }
        @finally
        {
            UMMUTEX_UNLOCK(_startStopLock);
        }
    }
}

- (void)backgroundTask
{
    @autoreleasepool
    {

        if(self.name)
        {
            ulib_set_thread_name(self.name);
        }
        if(self.runningStatus != UMBackgrounder_startingUp)
        {
            return;
        }
        if(_workSleeper==NULL)
        {
            self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
            [self.workSleeper prepare];
        }
       self.runningStatus = UMBackgrounder_running;

        [_control_sleeper wakeUp:UMSleeper_StartupCompletedSignal];
        if(_enableLogging)
        {
            NSLog(@"%@: started up successfully",self.name);
        }
        [self backgroundInit];
        BOOL mustQuit=NO;
        BOOL doSleep = NO;
        while((self.runningStatus == UMBackgrounder_running) && (mustQuit==NO))
        {
            @autoreleasepool
            {
                if(doSleep)
                {
                    /* lets sleep for a small while or until woken up due to work */
                    long long sleepTime = UMSLEEPER_DEFAULT_SLEEP_TIME;
                    if(_enableLogging)
                    {
                        sleepTime= UMSLEEPER_DEFAULT_SLEEP_TIME*100;
                    }
                    UMSleeper_Signal signal = [_workSleeper sleep:sleepTime wakeOn:(UMSleeper_HasWorkSignal | UMSleeper_ShutdownOrderSignal) ]; /* 100ms */
                    if (signal == UMSleeper_Error)
                    {
                        mustQuit=YES;
                        break;
                    }
                    if(_enableLogging)
                    {
                        NSLog(@"%@ woke up with signal %d",self.name,signal);
                    }
                    if(signal & UMSleeper_ShutdownOrderSignal)
                    {
                        if(_enableLogging)
                        {
                            NSLog(@"%@: got shutdown order",self.name);
                        }
                        mustQuit = YES;
                    }
                }
                if((!mustQuit) && (self.runningStatus == UMBackgrounder_running))
                {
                    int status;
                    @autoreleasepool
                    {
                        status = [self work]; /* > 0 means we had work processed */
                    }
                    if(status < 0)
                    {
                        if(_enableLogging)
                        {
                            NSLog(@"%@: shutdown because work returns %d",self.name,status);
                        }
                        mustQuit = YES;
                    }
                    if(status>0)
                    {
                        doSleep=NO;
                    }
                    else
                    {
                        doSleep=YES;
                    }
                }
            }
        }
        if(_enableLogging)
        {
            NSLog(@"%@: shutting down",self.name);
        }
        [self backgroundExit];
        self.runningStatus = UMBackgrounder_notRunning;
        self.workSleeper = NULL;
        [_control_sleeper wakeUp:UMSleeper_ShutdownCompletedSignal];
    }
}


- (int)work
{
    @autoreleasepool
    {
        NSLog(@"UMBackgrounder work method is not overwritten");
    }
    return -1;
}

- (void)backgroundInit
{
    
}
- (void)backgroundExit
{
}

@end
