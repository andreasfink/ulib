//
//  TestUmSleeper.m
//  ulib
//
//  Created by Aarno Syvänen on 06.11.14.
//
//

#import <ulib/ulib.h>
#import <XCTest/XCTest.h>

#import "TestUmSleeper.h"
#import "UMSleeper.h"

@implementation TestUmSleeper

- (void)taskWakeupOnSignal:(id)signal
{
    UMSleeper_Signal ourSignal = (UMSleeper_Signal)[signal unsignedIntegerValue];
    runningStatus = running;
    usleep(WAKEUP_TIME);
    [wakeWaiter wakeUp:ourSignal];
    @synchronized(self)
    {
        mustQuit = YES;
        runningStatus = shuttingDown;
    }

}

- (void)taskWakeup
{
    runningStatus = running;
    usleep(WAKEUP_TIME);
    [wakeWaiter wakeUp];
    @synchronized(self)
    {
        mustQuit = YES;
        runningStatus = shuttingDown;
    }
}

- (void)taskSleep
{
    runningStatus = running;
    UMSleeper *sleeper = [[UMSleeper alloc]initFromFile:__FILE__
                                                   line:__LINE__
                                               function:__func__];
    [sleeper sleep:SLEEP_TIME];
    [sleeper terminate];
    @synchronized(self)
    {
        mustQuit = YES;
        runningStatus = shuttingDown;
    }
}

- (void)setUp
{
    [super setUp];
    wakeWaiter = [[UMSleeper alloc]initFromFile:__FILE__
                                           line:__LINE__
                                       function:__func__];
}

- (void)tearDown
{
    [wakeWaiter terminate];
    [super tearDown];
}

- (void)testUMSleeper
{
    BOOL isRunning = YES, isShutDown = YES;
    mustQuit = NO;
    [NSThread detachNewThreadSelector:@selector(taskSleep) toTarget:self withObject:NULL];
    while (runningStatus != running)
        usleep(10000);
    long i = 0;
    while (TRUE)
    {
        if (i > SLEEP_TIME/SLEEP_TICK)
            break;
        
        @synchronized(self)
        {
            if (mustQuit == YES)
                break;
            isRunning = (runningStatus == running);
        }
        XCTAssert(isRunning, @"sleeping thread shoud not be awake");
        usleep(SLEEP_TICK);
        ++i;
    }
    
    XCTAssert(i == SLEEP_TIME/SLEEP_TICK, @"should sleep the sleeping time");
    
    @synchronized(self)
    {
        isShutDown = (runningStatus == shuttingDown);
    }
    XCTAssert(isShutDown, @"sleeping thread shoud be awake");

}

- (void)testWakeup
{
    BOOL isShutDown = NO;
    [NSThread detachNewThreadSelector:@selector(taskWakeup) toTarget:self withObject:NULL];
    while (runningStatus != running)
        usleep(10000);
    [wakeWaiter sleep:SLEEP_TIME];
    
    @synchronized(self)
    {
        isShutDown = (runningStatus == shuttingDown);
    }
    XCTAssert(isShutDown, @"sleeping thread shoud be awake");
}

- (void)testWakeupOnSignal
{
    BOOL isShutDown = NO;
    NSArray *signals = @[[NSNumber numberWithUnsignedInteger:UMSleeper_WakeupSignal], [NSNumber numberWithUnsignedInteger:UMSleeper_AnySignal], [NSNumber numberWithUnsignedInteger:UMSleeper_HasWorkSignal], [NSNumber numberWithUnsignedInteger:UMSleeper_StartupCompletedSignal], [NSNumber numberWithUnsignedInteger:UMSleeper_ShutdownOrderSignal], [NSNumber numberWithUnsignedInteger:UMSleeper_ShutdownCompletedSignal]];
    long i = 0;
    long len = [signals count];
    while (i < len)
    {
        [NSThread detachNewThreadSelector:@selector(taskWakeupOnSignal:) toTarget:self withObject:signals[i]];
        while (runningStatus != running)
            usleep(10000);
        [wakeWaiter sleep:SLEEP_TIME wakeOn:(UMSleeper_Signal)[signals[i] unsignedIntegerValue]];
        
        @synchronized(self)
        {
            isShutDown = (runningStatus == shuttingDown);
        }
        XCTAssert(isShutDown, @"sleeping thread shoud be awake");
        ++i;
    }

}

@end
