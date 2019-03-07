//
//  UMSleeper.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMSleeper.h"
#import "UMFileTrackingMacros.h"

#include <unistd.h>
#include <fcntl.h>
#include <poll.h>

#import "UMThroughputCounter.h"

static void socket_set_blocking(int fd, int blocking)
{
    int flags, newflags;
	
    flags = fcntl(fd, F_GETFL);
    if (blocking)
    {
        newflags = flags & ~O_NONBLOCK;
    }
    else
    {
        newflags = flags | O_NONBLOCK;
    }
    if (newflags != flags)
    {
		fcntl(fd, F_SETFL, newflags);
    }
}

#define RXPIPE 0
#define	TXPIPE 1

@implementation UMSleeper

- (UMSleeper *)initFromFile:(const char *)file line:(long)line function:(const char *)function
{
    self = [super init];
    if(self)
    {
        _isPrepared = NO;
        _ifile = file;
        _iline = line;
        _ifunction = function;
        _prepareLock = [[UMMutex alloc]initWithName:@"sleeper-mutex"];
    }
    return self;
}

- (UMSleeper *)init
{
    return [self initFromFile:__FILE__ line:__LINE__ function:__func__ ];
}

- (void) prepare
{
    if(self.isPrepared==YES)
    {
        return;
    }
    [_prepareLock lock];
    if(self.isPrepared==YES)
    {
        [_prepareLock unlock];
        return;
    }
    int pipefds[2];
    pipefds[0] = -1;
    pipefds[1] = -1;
    if(pipe(pipefds)< 0)
    {
        int eno = errno;

        switch(eno)
        {
            case EMFILE:
                NSLog(@"ERROR: EMFILE Too many file descriptors are in use by the process (Sleeper init)");
                break;
            case ENFILE:
                NSLog(@"ERROR: ENFILE The system file table is full. (Sleeper init)");
                break;
            default:
                NSLog(@"ERROR: %d Cannot allocate wakeup pipe (Sleeper init)",eno);
                break;
        }
        return;
    }
    _rxpipe=pipefds[RXPIPE];
    _txpipe=pipefds[TXPIPE];
    if(_ifile)
    {
        TRACK_FILE_PIPE_FLF(self.rxpipe,@"rxpipe",_ifile,_iline,_ifunction);
        TRACK_FILE_PIPE_FLF(self.txpipe,@"txpipe",_ifile,_iline,_ifunction);
    }
    else
    {
        TRACK_FILE_PIPE(_rxpipe,@"rxpipe");
        TRACK_FILE_PIPE(_txpipe,@"txpipe");
    }
    socket_set_blocking(_rxpipe, 0);
    socket_set_blocking(_txpipe, 0);
    _isPrepared = YES;
    [_prepareLock unlock];
}

- (void) dealloc
{
    if(_isPrepared==NO)
    {
        return;
    }
    if(_rxpipe >=0)
    {
        TRACK_FILE_CLOSE(_rxpipe);
        close(_rxpipe);
    }
    if(_txpipe>=0)
    {
        TRACK_FILE_CLOSE(_txpipe);
        close(_txpipe);
    }
    _rxpipe = -1;
    _txpipe = -1;
    _isPrepared = NO;
}


#ifdef INFTIM
#define POLL_NOTIMEOUT INFTIM
#else
#define POLL_NOTIMEOUT (-1)
#endif

static void flushpipe(int fd)
{
    unsigned char buf[128];
    ssize_t bytes;
    do
	{
        bytes = read(fd, buf, sizeof(buf));
    } while (bytes > 0);
}



//#define SLICE_TIME   (2073600LL*1000LL*1000LL)/* 24 days is about the max which fits into a signed integer */
#define SLICE_TIME (1000LL*1000LL*10LL*60LL)   /* max 10 minutes for testing */

- (UMSleeper_Signal) sleep:(UMMicroSec) microseconds
       wakeOn:(UMSleeper_Signal)sig;	/* returns signal value if signal was received, 0 on timer epxiry, -1 on error  */
{
    struct pollfd pollfd[2];
    int pollresult;
    int wait_time;
    UMMicroSec start_time = [UMThroughputCounter microsecondTime];
    UMMicroSec end_time = start_time + microseconds;
    UMMicroSec now;

    if(microseconds <= 1000LL)
    {
       @throw([NSException exceptionWithName:@"OUT_OF_BOUNDS" reason:@"can not sleep for less than 1ms is kind of ridiculous" userInfo:NULL]);
    }
    
    if(_debug)
    {
        NSLog(@"Going to sleep for %0.3lf seconds or until woken up by signal mask 0x%04x",(double)microseconds / 1000000.0,sig);
    }

    int events = POLLIN | POLLPRI | POLLERR | POLLHUP | POLLNVAL;

#ifdef POLLRDBAND
    events |= POLLRDBAND;
#endif 
    
#ifdef POLLRDHUP
    events |= POLLRDHUP;
#endif
    
    [self prepare];
    if(_rxpipe < 0)
    {
        return -1;
    }

    pollresult = 0;
    while(pollresult == 0)
    {
        now = [UMThroughputCounter microsecondTime];
        UMMicroSec remaining = end_time - now;
        if(remaining <= 0) /* end time reached */
        {
            return pollresult;
        }

        if(remaining <= SLICE_TIME)
        {
            wait_time = (int)(remaining/1000); /* poll wants miliseconds */
        }
        else
        {
            wait_time = (int)SLICE_TIME / 1000;
        }

        memset(&pollfd,0x00,sizeof(pollfd));
        pollfd[0].fd = _rxpipe;
        pollfd[0].events = events;
        pollfd[0].revents = 0;
        pollresult = poll(&pollfd[0], 1, wait_time);
        if(pollresult > 0)
        {
            /* something to read */
            UMSleeper_Signal signalToRead=0xFE;
            ssize_t bytes;
            uint8_t buffer[1];
            bytes = read(self.rxpipe, &buffer, 1);
            if(bytes == 1)
            {
                signalToRead = (buffer[0]);
                if(signalToRead & sig) /* checking if signal's bit is set */
                {
                    if(_debug)
                    {
                        NSLog(@"Signal 0x%01X received",(int)sig);
                    }
                    return (UMSleeper_Signal)signalToRead;
                }
                if(_debug)
                {
                    NSLog(@"Ignoring signal 0x%01X",(int)sig);
                }
            }
        }
        else if(pollresult < 0)
        {
            return UMSleeper_Error;
        }
    }
    return UMSleeper_TimerExpired; /* we get here on timeout only */
}

- (UMSleeper_Signal) sleep:(long long) microseconds	/* returns 1 if interrupted, 0 if timer expired */
{
    return [self sleep:microseconds wakeOn:UMSleeper_AnySignalMask];
};	/* returns signal if signal was received, 0 on timer epxiry, -1 on error  */

- (void) reset
{
    if(_isPrepared)
    {
        flushpipe(_rxpipe);
    }
}

- (void) wakeUp:(UMSleeper_Signal)sig
{
    if(_debug)
    {
        NSLog(@"WakeUp order 0x%04x",sig);
    }

    if(_txpipe >= 0)
    {
        uint8_t bytes[1];
        bytes[0] = sig;
        write(_txpipe, &bytes,1);
    }
}

- (void) wakeUp
{
    [self wakeUp:UMSleeper_WakeupSignal];
}

@end
