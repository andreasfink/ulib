// 
//  UMBackgrounder.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMBackgrounder.h"
#import "UMSleeper.h"
#import "UMLock.h"

#define UMSLEEPER_DEFAULT_SLEEP_TIME 500000 /* 500ms */

@implementation UMBackgrounder

@synthesize name;
@synthesize workSleeper;
@synthesize enableLogging;
@synthesize runningStatus;

- (UMBackgrounder *)init
{
    return [self initWithName:@"(unnamed)"
                  workSleeper:[[UMSleeper alloc]initFromFile:__FILE__
                                                        line:__LINE__
                                                    function:__func__]];
}

- (UMBackgrounder *)initWithName:(NSString *)n
                     workSleeper:(UMSleeper *)ws
{
    self = [super init];
    if(self)
    {
        self.name = n;
        control_sleeper = [[UMSleeper alloc]initFromFile:__FILE__
                                                    line:__LINE__
                                                function:__func__];
        self.workSleeper = ws;
    }
    return self;
}

- (void)startBackgroundTask
{
    if(control_sleeper == NULL)
    {
        @throw([NSException exceptionWithName:@"NOT_INITIALIZED" reason:@"control sleeper in UMBackgrounder is not initialized" userInfo:NULL]);
    }

    @synchronized(self)
    {
        if(self.runningStatus == UMBackgrounder_notRunning)
        {
            self.runningStatus = UMBackgrounder_startingUp;

            [self runSelectorInBackground:@selector(backgroundTask)
                               withObject:NULL
                                     file:__FILE__
                                     line:__LINE__
                                 function:__func__];

//            [NSThread detachNewThreadSelector:@selector(backgroundTask) toTarget:self withObject:NULL];
            int i=0;
            while(i<= 10)
            {
                int s = [control_sleeper sleep:1000000L wakeOn:UMSleeper_StartupCompletedSignal]; /* 1s */
                if(s==UMSleeper_StartupCompletedSignal)
                {
                    return;
                }
                i++;
            }
        }
    }
}

- (void)shutdownBackgroundTask
{
    @synchronized(self)
    {
        if(self.runningStatus != UMBackgrounder_running)
        {
            return;
        }
        
        self.runningStatus = UMBackgrounder_shuttingDown;
        int i=0;
      
        [workSleeper wakeUp:UMSleeper_ShutdownOrderSignal];
        while((self.runningStatus == UMBackgrounder_shuttingDown) && (i<= 100))
        {
            i++;
            [control_sleeper sleep:UMSLEEPER_DEFAULT_SLEEP_TIME wakeOn:UMSleeper_ShutdownCompletedSignal]; /* 500ms */
        }
        if((self.runningStatus == UMBackgrounder_shuttingDown) && (i> 100))
        {
            /* it didnt start successfully in 10 seconds. Something is VERY ODD */
            NSLog(@"shutdownBackgroundTask: failed. Background task did not shut down within 10 seconds");
        }
        self.runningStatus = UMBackgrounder_notRunning;
    }
}

- (void)backgroundTask
{
    BOOL mustQuit = NO;

    if(self.name)
    {
        ulib_set_thread_name(self.name);
    }
    if(self.runningStatus != UMBackgrounder_startingUp)
    {
        return;
    }
    if(workSleeper==NULL)
    {
        self.workSleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
    }
   self.runningStatus = UMBackgrounder_running;

    [control_sleeper wakeUp:UMSleeper_StartupCompletedSignal];

    if(enableLogging)
    {
        NSLog(@"%@: started up successfully",self.name);
    }
    [self backgroundInit];
    while((self.runningStatus == UMBackgrounder_running) && (mustQuit==NO))
    {
        /* waiting for work */
        long long sleepTime = UMSLEEPER_DEFAULT_SLEEP_TIME;
        if(enableLogging)
        {
            sleepTime= UMSLEEPER_DEFAULT_SLEEP_TIME*100;
        }
        int signal = [workSleeper sleep:sleepTime wakeOn:(UMSleeper_HasWorkSignal | UMSleeper_ShutdownOrderSignal) ]; /* 100ms */
        if(enableLogging)
        {
            NSLog(@"%@ woke up with signal %d",self.name,signal);
        }
        if(signal & UMSleeper_ShutdownOrderSignal)
        {
            if(enableLogging)
            {
                NSLog(@"%@: got shutdown order",self.name);
            }
            mustQuit = YES;
        }
        else
        {
            int status = [self work];
            if(status < 0)
            {
                if(enableLogging)
                {
                    NSLog(@"%@: shutdown because work returns %d",self.name,status);
                }
                mustQuit = YES;
            }
        }
    }
    if(enableLogging)
    {
        NSLog(@"%@: shutting down",self.name);
    }
    [self backgroundExit];
    self.runningStatus = UMBackgrounder_notRunning;
    self.workSleeper = NULL;
    [control_sleeper wakeUp:UMSleeper_ShutdownCompletedSignal];
}


- (int)work
{
    NSLog(@"UMBackgrounder work method is not overwritten");
    return -1;
}

- (void)backgroundInit
{
    
}
- (void)backgroundExit
{
}

@end
