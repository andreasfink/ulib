//
//  UMSleeper.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMMicroSec.h"

typedef int32_t UMSleeper_Signal; /* note Sleeper signal is a bitmask */

#define UMSleeper_WakeupSignal              (UMSleeper_Signal)0x1FFF
#define UMSleeper_AnySignal                 (UMSleeper_Signal)0xFFFF

#define UMSleeper_HasWorkSignal             (UMSleeper_Signal)0x1000
#define UMSleeper_StartupCompletedSignal    (UMSleeper_Signal)0x2000
#define UMSleeper_ShutdownOrderSignal       (UMSleeper_Signal)0x4000
#define UMSleeper_ShutdownCompletedSignal   (UMSleeper_Signal)0x8000

@interface UMSleeper : UMObject
{
    int rxpipe;
    int txpipe;
	int flag;
    BOOL isPrepared;
    const char *ifile;
    long iline;
    const char *ifunction;
}
@property(readwrite,assign,atomic) BOOL isPrepared;
@property(readwrite,assign,atomic) int rxpipe;
@property(readwrite,assign,atomic) int txpipe;


- (UMSleeper *)initFromFile:(const char *)file line:(long)line function:(const char *)function;
- (void) prepare;
- (void) dealloc;
- (int) sleep:(UMMicroSec) microseconds wakeOn:(UMSleeper_Signal)sig;	/* returns signal number (1-0xFFFF) if signal was received, 0 on timer epxiry, -1 on error  */
- (int) sleep:(UMMicroSec) microseconds;	/* returns returns signal number (1-0xFFFF)if interrupted, 0 if timer expired */
- (void) reset;
- (void) wakeUp:(UMSleeper_Signal)signal;
- (void) wakeUp;

@end
