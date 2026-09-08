//
//  UMSCTPListener.m
//  ulib
//
//  Created by Andreas Fink on 23.08.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMSCTPListener.h>
#import <ulib/UMSocketSCTP.h>
#import <ulib/UMSocketSCTPReceivedPacket.h>
#import <ulib/UMLayerSctp.h>

#include <poll.h>

@implementation UMSCTPListener


- (UMSCTPListener *)initWithName:(NSString *)name
                          socket:(UMSocketSCTP *)sock
                   eventDelegate:(id<UMSCTPListenerProcessEventsDelegate>)evDel
                    readDelegate:(id<UMSCTPListenerReadPacketDelegate>)readDel
                 processDelegate:(id<UMSCTPListenerProcessDataDelegate>)procDel

{
    self = [super initWithName:name workSleeper:NULL];
    if(self)
    {
        self.name = name;
        _timeoutInMs = 500; /* 300 msec */
        _umsocket = sock;
        _eventDelegate = evDel;
        _readDelegate = readDel;
        _processDelegate = procDel;
        _assocs = [[UMSynchronizedDictionary alloc]init];
        NSLog(@"UMSCTPListener initWithName:%@",_name);
    }
    return self;
}

- (void)backgroundInit
{
    NSLog(@"UMSCTPListener backgroundInit:%@",_name);
    ulib_set_thread_name(_name);
    NSLog(@"starting %@",_name);
}

- (void)backgroundExit
{
    NSLog(@"UMSCTPListener backgroundExit:%@",_name);
    NSString *s = [NSString stringWithFormat:@"%@ (terminating)",_name];
    ulib_set_thread_name(s);
    NSLog(@"terminating %@",s);
}

- (int)work
{
    int ret = 1;
    UMSocketError err = [self waitAndHandleData];
    if(err==UMSocketError_not_a_socket)
    {
        ret=-1;
        [_eventDelegate processHangup];
    }
    if(err==UMSocketError_has_data_and_hup)
    {
        ret = -1; /* it has already sent the processHangup event */
    }
    return ret;
}

- (UMSocketError) waitAndHandleData
{
    UMSocketError returnValue = UMSocketError_no_error;
    

    if(_umsocket==NULL)
    {
        NSLog(@"calling waitAndHandleData returns because _umsocket is NULL");
        return UMSocketError_not_a_socket;
    }
    struct pollfd   pollfds[2];
    memset(pollfds, 0x00,sizeof(pollfds));
    pollfds[0].fd = _umsocket.fileDescriptor;
    pollfds[0].events = POLLIN | POLLERR | POLLHUP;

    if(_timeoutInMs < 100)
    {
        _timeoutInMs = 100;
    }
    if(_timeoutInMs > 10000)
    {
        _timeoutInMs = 10000;
    }
    //NSLog(@"  waitAndHandleData(_timeoutInMs=%d)",_timeoutInMs);
    int ret1 = poll(pollfds, 1, _timeoutInMs);
    if (ret1 < 0)
    {
        int eno = errno;
        if((eno==EINPROGRESS) || (eno == EINTR) || (eno==EAGAIN)  || (eno==EBUSY))
        {
            returnValue = UMSocketError_no_data;
        }
        else
        {
            returnValue = [UMSocket umerrFromErrno:eno];
        }
    }
    else if (ret1 == 0)
    {
        returnValue = UMSocketError_no_data;
    }
    else /* ret1 > 0 */
    {
        /* we have some event to handle. */
        returnValue = UMSocketError_no_error;

        int revent = pollfds[0].revents;
        int revent_error = UMSocketError_no_error;
        int revent_hup = 0;
        int revent_dohup = 0;
        int revent_has_data = 0;
        if(revent & POLLERR)
        {
            revent_error = [_umsocket getSocketError];
            [_eventDelegate processError:revent_error];
            if(     (revent_error != UMSocketError_no_error)
                &&  (revent_error != UMSocketError_no_data)
                &&  (revent_error !=UMSocketError_in_progress))
            {
                revent_dohup = 1;
            }
        }
        if(revent & POLLHUP)
        {
            revent_hup = 1;
        }
        if(revent & (POLLIN | POLLPRI))
        {
            revent_has_data = 1;
        }
        if(revent_has_data)
        {
            UMSocketSCTPReceivedPacket *rx = NULL;
            rx = [_readDelegate receiveSCTP];
            [_processDelegate processReceivedData:rx];
            if((revent_hup) || (revent_dohup))
            {
                returnValue = UMSocketError_has_data_and_hup;
            }
            else
            {
                returnValue = UMSocketError_has_data;
            }
        }
        if((revent_hup) || (revent_dohup))
        {
            [_eventDelegate processHangup];
        }
    }
    return returnValue;
}

@end
#endif
