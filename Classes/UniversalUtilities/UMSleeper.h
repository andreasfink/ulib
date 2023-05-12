//
//  UMSleeper.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMMicroSec.h"

typedef uint8_t UMSleeper_Signal; /* note Sleeper signal is a bitmask */

#define UMSleeper_AnySignalMask             (UMSleeper_Signal)0xFF
#define UMSleeper_Error                     (UMSleeper_Signal)0xFE
#define UMSleeper_TimerExpired              (UMSleeper_Signal)0x00

#define UMSleeper_WakeupSignal              (UMSleeper_Signal)0x01
#define UMSleeper_HasWorkSignal             (UMSleeper_Signal)0x02
#define UMSleeper_StartupCompletedSignal    (UMSleeper_Signal)0x04
#define UMSleeper_ShutdownOrderSignal       (UMSleeper_Signal)0x08
#define UMSleeper_ShutdownCompletedSignal   (UMSleeper_Signal)0x10
 
@interface UMSleeper : UMObject
{
    int         _rxpipe;
    int         _txpipe;
    BOOL        _isPrepared;
    const char  *_ifile;
    long        _iline;
    const char  *_ifunction;
    UMMutex     *_lock;
    BOOL        _debug;
}
@property(readwrite,assign,atomic) BOOL isPrepared;
@property(readwrite,assign,atomic) int rxpipe;
@property(readwrite,assign,atomic) int txpipe;
@property(readwrite,assign,atomic) BOOL debug;

- (UMSleeper *)initFromFile:(const char *)file line:(long)line function:(const char *)function;
- (void) prepare;
- (void) dealloc;
- (UMSleeper_Signal) sleep:(UMMicroSec) microseconds wakeOn:(UMSleeper_Signal)sig;	/* returns signal number if signal was received, 0 on timer epxiry, or UMSleeper_Error  */
- (UMSleeper_Signal) sleep:(UMMicroSec) microseconds;	/* returns returns signal number (1-0xFFFF)if interrupted, 0 if timer expired */

- (UMSleeper_Signal) sleepSeconds:(double)sec;
- (void) reset;
- (void) wakeUp:(UMSleeper_Signal)signal;
- (void) wakeUp;

@end
