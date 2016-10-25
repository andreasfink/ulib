//
//  TestUmSleeper.h
//  ulib
//
//  Created by Aarno Syvänen on 06.11.14.
//
//

#import <XCTest/XCTest.h>
#import "UMTestCase.h"

#define SLEEP_TIME 10000000       // ten seconds
#define SLEEP_TICK 1000000        // 1 second
#define WAKEUP_TIME 5000000         // 5 seconds

typedef enum test_runningStatus
{
    notRunning      = 0,
    startingUp      = 1,
    running         = 2,
    shuttingDown    = 3,
} test_runningStatus;

@class UMSleeper;

@interface TestUmSleeper : XCTestCase
{
    test_runningStatus runningStatus;
    BOOL mustQuit;
    UMSleeper *wakeWaiter;
}

- (void)taskSleep;
- (void)taskWakeup;

@end

