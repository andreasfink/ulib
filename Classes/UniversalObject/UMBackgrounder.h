//
//  UMBackgrounder.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

/*!
 @class UMBackgrounder
 @brief  UMBackgrounder is an object to have background tasks handled properly.

 To implement a working tasks, subclass it and have it override the method "work".
 "work" should call the sleeper's sleep function when it waits for something
 so it could exit its main thread on the specific signal. "work" is run constantly in a loop
 if a positive value is returned. on 0 it goes to sleep for a short while to call "work" again
 to see if there's more work ot be done. On a negative value it quits the backgroud thread.
 
 to fire up the background thread, call startBackgroundTask.
 to shut it down, call shutdownBackgroundTask
 
 UMBackgrounderWithQueue is a subclass who overrides work with a method to handle individual
 work items through a queue where the work queue can be shared by multiple backgrounders.

 */

#import "UMObject.h"
#import "UMMutex.h"

@class UMSleeper;

typedef enum UMBackgrounder_runningStatus
{
    UMBackgrounder_notRunning      = 0,
    UMBackgrounder_startingUp      = 1,
    UMBackgrounder_running         = 2,
    UMBackgrounder_shuttingDown    = 3,
} UMBackgrounder_runningStatus;


@interface UMBackgrounder : UMObject
{
    NSString                        *_name;
    UMBackgrounder_runningStatus    _runningStatus;
    UMSleeper                       *_control_sleeper; /* feedback from the backgrounder */
    UMSleeper                       *_workSleeper;    /* messages to the backgrounder */
    BOOL                            _enableLogging;
    UMMutex                         *_startStopLock;
}

@property(readwrite,strong,atomic) NSString *name;
@property(readwrite,strong,atomic) UMSleeper *control_sleeper;
@property(readwrite,strong,atomic) UMSleeper *workSleeper;
@property(readwrite,assign,atomic) BOOL enableLogging;
@property(readwrite,assign,atomic) UMBackgrounder_runningStatus runningStatus;

- (UMBackgrounder *)initWithName:(NSString *)n workSleeper:(UMSleeper *)ws;
- (void)startBackgroundTask;
- (void)shutdownBackgroundTask;
- (void)backgroundTask;
- (void)backgroundInit;
- (void)backgroundExit;
- (int)work; /* should return positive value for work items done, 0 for no work done  and -1 for termination */

@end
