//
//  UMLayerSctp.m
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMLayerSctp.h>
#import <ulib/ulib_config.h>

#include <netinet/in.h>
#if defined(__APPLE__)

#include <ulib/sctp.h>

#else

#ifdef HAVE_NETINET_SCTP_H
#include <netinet/sctp.h>
#endif
#endif

#define ULIBSCTP_INTERNAL 1
//#define POWER_DEBUG         1

#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include <poll.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <netdb.h>
#import "UMSocketSCTP.h"
#include <arpa/inet.h>

#import <ulib/UMLayerSctpUser.h>
#import <ulib/UMSctpOverTcp.h>
#import <ulib/UMSctpTask_AdminInit.h>
#import <ulib/UMSctpTask_AdminAttach.h>
#import <ulib/UMSctpTask_AdminDetach.h>
#import <ulib/UMSctpTask_AdminSetConfig.h>
#import <ulib/UMSctpTask_Open.h>
#import <ulib/UMSctpTask_Close.h>
#import <ulib/UMSctpTask_Data.h>
#import <ulib/UMSctpTask_Manual_ForceOutOfService.h>
#import <ulib/UMSctpTask_Manual_InService.h>
#import <ulib/UMSocketSCTPRegistry.h>
#import <ulib/UMSocketSCTPListener2.h>
#import <ulib/UMLayerSctpUserProfile.h>
#import <ulib/UMThroughputCounter.h>
#import <ulib/UMLogFeed.h>
#import <ulib/UMHistoryLog.h>
#import <ulib/UMSleeper.h>

@implementation UMLayerSctp

-(NSString *)layerType
{
    return @"sctp";
}

- (UMLayerSctp *)init
{
    self = [self initWithTaskQueueMulti:NULL name:@"sctp-dummy"];
    if(self)
    {
        _newDestination = YES;
        [self addToLayerHistoryLog:@"init"];
    }
    return self;
}

- (UMLayerSctp *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name
{
    NSString *s = [NSString stringWithFormat:@"sctp/%@",name];
    self = [super initWithTaskQueueMulti:tq name:s];
    if(self)
    {
        _timeoutInMs = 2400;
        _heartbeatSeconds = 30.0;
        _users = [[UMSynchronizedArray alloc]init];
        _status = UMSOCKET_STATUS_OFF;
        _newDestination = YES;
        _inboundThroughputPackets   = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _inboundThroughputBytes     = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _outboundThroughputPackets  = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _outboundThroughputBytes    = [[UMThroughputCounter alloc]initWithResolutionInSeconds: 1.0 maxDuration: 1260.0];
        _reconnectTimerValue = 6.0;
        _reconnectTimer = NULL; /* upper layers should take care of that */
        //_reconnectTimer = [[UMTimer alloc]initWithTarget:self selector:@selector(reconnectTimerFires) object:NULL seconds:_reconnectTimerValue name:@"reconnect-timer" repeats:NO runInForeground:YES];
        NSString *lockName = [NSString stringWithFormat:@"sctp-layer-link-lock(%@)",name];
        _linkLock = [[UMMutex alloc]initWithName:lockName];
        [self addToLayerHistoryLog:@"initWithTaskQueueMulti"];
    }
    return self;
}

#pragma mark -
#pragma mark Task Creators
- (void)adminInit
{
    UMLayerTask *task = [[UMSctpTask_AdminInit alloc]initWithReceiver:self sender:NULL];
    [self queueFromAdmin:task];
}


- (void)adminAttachFor:(id<UMLayerSctpUserProtocol>)caller
               profile:(UMLayerSctpUserProfile *)p
                userId:(id)uid;

{
    UMLayerTask *task =  [[UMSctpTask_AdminAttach alloc]initWithReceiver:self
                                                                  sender:caller
                                                                 profile:p
                                                                  userId:uid];
    [self queueFromAdmin:task];
}

- (void)adminDetachFor:(id<UMLayerSctpUserProtocol>)caller
                userId:(id)uid
{
    UMLayerTask *task =  [[UMSctpTask_AdminDetach alloc]initWithReceiver:self
                                                                  sender:caller
                                                                  userId:uid];
    [self queueFromAdmin:task];
}

- (void)adminSetConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerSctpApplicationContextProtocol>)appContext;
{
    UMLayerTask *task = [[UMSctpTask_AdminSetConfig alloc]initWithReceiver:self config:cfg applicationContext:appContext];
    [self queueFromAdmin:task];
}

- (void)openFor:(id<UMLayerSctpUserProtocol>)caller
{
    [self addToLayerHistoryLog:[NSString stringWithFormat:@"openFor(%@)",caller.layerName]];
    [self openFor:caller sendAbortFirst:NO];
}

- (void)openFor:(id<UMLayerSctpUserProtocol>)caller sendAbortFirst:(BOOL)abortFirst
{
    [self openFor:caller sendAbortFirst:abortFirst reason:NULL];
}

- (void)openFor:(id<UMLayerSctpUserProtocol>)caller sendAbortFirst:(BOOL)abortFirst reason:(NSString *)reason
{
    UMSctpTask_Open *task = [[UMSctpTask_Open alloc]initWithReceiver:self sender:caller];
    task.sendAbortFirst = abortFirst;
    task.reason = reason;
    [self addToLayerHistoryLog:[NSString stringWithFormat:@"openFor(%@) sendAbortFirst=%@ reason=%@",caller.layerName,(abortFirst ? @"YES":@"NO"), (reason ? reason : @"unspecified")]];
    [self queueFromUpper:task];
}

- (void)closeFor:(id<UMLayerSctpUserProtocol>)caller
{
    [self closeFor:caller reason:NULL];
}

- (void)closeFor:(id<UMLayerSctpUserProtocol>)caller reason:(NSString *)reason
{
    
    if(_logLevel <= UMLOG_DEBUG)
    {
        NSString *s = [NSString stringWithFormat:@"queuing closeFor(%@) reason=%@",caller.layerName,reason? reason: @"unspecified"];
        [_logFeed debugText:s];
        [self addToLayerHistoryLog:s];
    }
    UMSctpTask_Close *task = [[UMSctpTask_Close alloc]initWithReceiver:self sender:caller];
    task.reason = reason;
    [self queueFromUpper:task];
}

/* public API for upper interface */

- (void)dataFor:(id<UMLayerSctpUserProtocol>)caller
           data:(NSData *)sendingData
       streamId:(uint16_t)sid
     protocolId:(uint32_t)pid
     ackRequest:(NSDictionary *)ack
{
    [self dataFor:caller
             data:sendingData
         streamId:sid
       protocolId:pid
       ackRequest:ack
      synchronous:NO];
}

/* public API for upper interface */
- (void)dataFor:(id<UMLayerSctpUserProtocol>)caller
           data:(NSData *)sendingData
       streamId:(uint16_t)sid
     protocolId:(uint32_t)pid
     ackRequest:(NSDictionary *)ack
    synchronous:(BOOL)sync

{
    @autoreleasepool
    {
        UMSctpTask_Data *task =
        [[UMSctpTask_Data alloc]initWithReceiver:self
                                          sender:caller
                                            data:sendingData
                                        streamId:@(sid)
                                      protocolId:@(pid)
                                      ackRequest:ack];
        if(sync)
        {
            [task main];
        }
        else
        {
            [self queueFromUpper:task];
        }
    }
}

- (void)foosFor:(id<UMLayerSctpUserProtocol>)caller
{
    [self addToLayerHistoryLog:[NSString stringWithFormat:@"foosFor(%@)",caller.layerName]];
    @autoreleasepool
    {
        UMSctpTask_Manual_ForceOutOfService *task =
        [[UMSctpTask_Manual_ForceOutOfService alloc]initWithReceiver:self sender:caller];
        [self queueFromLowerWithPriority:task];
        self.stopButtonPressed = [NSDate date];
    }
}

- (void)isFor:(id<UMLayerSctpUserProtocol>)caller
{
    [self addToLayerHistoryLog:[NSString stringWithFormat:@"isFor(%@)",caller.layerName]];
    @autoreleasepool
    {
        UMSctpTask_Manual_InService *task =
        [[UMSctpTask_Manual_InService alloc]initWithReceiver:self sender:caller];
        [self queueFromLowerWithPriority:task];
        self.startButtonPressed = [NSDate date];
    }
}

#pragma mark -
#pragma mark Task Executors
/* LAYER API. The following methods are called by queued tasks */
- (void)_adminInitTask:(UMSctpTask_AdminInit *)task
{
    @autoreleasepool
    {
    #if defined(ULIBSCTP_CONFIG_DEBUG)
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"adminInit"]];
        }
    #endif
    }
}

- (void)_adminSetConfigTask:(UMSctpTask_AdminSetConfig *)task
{
    @autoreleasepool
    {
    #if defined(ULIBSCTP_CONFIG_DEBUG)
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"setConfig %@",task.config]];
        }
    #endif
        [self setConfig:task.config applicationContext:task.appContext];
    }
}

- (void)_adminAttachTask:(UMSctpTask_AdminAttach *)task
{
    id<UMLayerSctpUserProtocol> user = (id<UMLayerSctpUserProtocol>)task.sender;

    UMLayerSctpUser *u      = [[UMLayerSctpUser alloc]init];
    u.profile              = task.profile;
    u.user                  = user;
    u.userId                = task.userId;

    [_users addObject:u];
    if(_defaultUser==NULL)
    {
        _defaultUser = u;
    }

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"attached %@",
                        user.layerName]];
    }
#endif
    [user adminAttachConfirm:self
                      userId:u.userId];
}

- (void)_adminDetachTask:(UMSctpTask_AdminDetach *)task
{
    NSArray *usrs = [_users arrayCopy];
    for(UMLayerSctpUser *u in usrs)
    {
        if([u.userId isEqualTo:task.userId])
        {
            [_users removeObject:u];
            [u.user adminDetachConfirm:self
                                userId:u.userId];
            break;
        }
    }
}

- (void)_openTask:(UMSctpTask_Open *)task
{
    @autoreleasepool
    {
        [self addToLayerHistoryLog:@"_openTask"];
        BOOL sendAbort = task.sendAbortFirst;
        ummutex_lock(_linkLock);
        @try
        {
            if(self.status == UMSOCKET_STATUS_FOOS)
            {
                if(_logLevel <=UMLOG_DEBUG)
                {
                    NSLog(@"UMSOCKET_STATUS_FOOS");
                }
                [self logMajorError:@"OpenTask: failed due to M-FOOS"];
                [self addToLayerHistoryLog:@"OpenTask: failed due to M-FOOS"];

            }
            else if(self.status == UMSOCKET_STATUS_OOS)
            {
                [self logMinorError:@"already establishing"];
                [self addToLayerHistoryLog:@"OpenTask: already establishing"];
            }
            else if(self.status== UMSOCKET_STATUS_IS)
            {
                [self logMinorError:@"already in service"];
                [self addToLayerHistoryLog:@"OpenTask: already in service"];
            }
            else
            {
                UMSocketError err = UMSocketError_no_error;
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    NSString *addrs = [_configured_local_addresses componentsJoinedByString:@","];
                    [self logDebug:[NSString stringWithFormat:@"getting listener on %@ on port %d",addrs,_configured_local_port]];
                }
                _listener =  [_registry getOrAddListenerForPort:_configured_local_port      localIps:_configured_local_addresses];
                
                _listener = [_registry getOrAddListenerForPort:_configured_local_port
                                                          localIps:_configured_local_addresses
                                                      maxInStreams:_maxInStreams
                                                       numOStreams:_numOStreams
                                                   maxInitAttempts:_maxInitAttempts
                                                       initTimeout:_maxInitTimeout];
            
                

                if(self.listener == NULL)
                {
                    [self logDebug:@"OOPS, _listener is NULL"];
                }
                self.listener.mtu = _mtu;
                self.listener.dscp = _dscp;
                if(_minReceiveBufferSize > _listener.minReceiveBufferSize)
                {
                    _listener.minReceiveBufferSize = _minReceiveBufferSize;
                }
                if(_minSendBufferSize > _listener.minSendBufferSize)
                {
                    _listener.minSendBufferSize = _minSendBufferSize;
                }
                usleep(100000); /* lets give the system a chance to set isListening etc */
                [_listener startListeningFor:self];
                usleep(150000); /* lets give the system a chance to set isListening etc */
                _listenerStarted = _listener.isListening;
                _newDestination = YES;
                usleep(100000);
                _assocId = NULL;
                if(!_isPassive)
                {
                    if(self.logLevel <= UMLOG_DEBUG)
                    {
                        NSString *addrs = [_configured_remote_addresses componentsJoinedByString:@","];
                        NSString *s = [NSString stringWithFormat:@"asking listener to connect to %@ on port %d",addrs,_configured_remote_port];
                        [self logDebug:s];
                        [_layerHistory addLogEntry:s];
                    }
                    if(_directSocket)
                    {
                        if(sendAbort)
                        {
                            for(NSString *addr in _configured_remote_addresses)
                            {
                                @try
                                {
                                    [_listener.umsocket abortToAddress:addr
                                                                  port:_configured_remote_port
                                                                 assoc:_assocId
                                                                stream:0
                                                              protocol:0];
                                }
                                @catch(NSException *e)
                                {
                                }
                            }
                        }
                        [_directSocket close];
                        _directSocket = NULL;
                        [self setStatus:UMSOCKET_STATUS_OFF reason:@"closing old direct socket in openTask"];
                    }
                    NSNumber *tmp_assocId = NULL;
                    err = [_listener connectToAddresses:_configured_remote_addresses
                                                   port:_configured_remote_port
                                               assocPtr:&tmp_assocId
                                                  layer:self];

                    if((err == UMSocketError_no_error) || (err==UMSocketError_in_progress))
                    {
                        if(tmp_assocId !=NULL)
                        {
                            _assocId = tmp_assocId;
                        }
                        [self setStatus:UMSOCKET_STATUS_OOS reason:@"_listener connectToAddress was successfully executed"];
                    }
                    else if(err==UMSocketError_is_already_connected)
                    {
                        if(tmp_assocId !=NULL)
                        {
                            _assocId = tmp_assocId;
                        }
                        [self setStatus:UMSOCKET_STATUS_OOS reason:@"_listener connectToAddress returns isAlreadyConnected"];
                        [self setStatus:UMSOCKET_STATUS_IS reason:@"_listener connectToAddress returns isAlreadyConnected"];
                    }
                    else
                    {
                        NSString *s = [NSString stringWithFormat:@"_listener connectToAddress failed with error %d %@",err,[UMSocket getSocketErrorString:err]];
                        [self setStatus:UMSOCKET_STATUS_OFF reason:s];
                        [self powerdown:s];
                    }
                    if(self.logLevel <= UMLOG_DEBUG)
                    {
                        NSString *e = [UMSocket getSocketErrorString:err];
                        [self logDebug:[NSString stringWithFormat:@"returns %d %@",err,e]];
                    }
                }
                [_registry registerOutgoingLayer:self allowAnyRemotePortIncoming:_allowAnyRemotePortIncoming];
                if(_allowAnyRemotePortIncoming)
                {
                    [_registry registerIncomingLayer:self];
                }
                if(_assocId!=NULL)
                {
                    [_listener registerAssoc:_assocId forLayer:self];
                }
            }
        }
        @catch (NSException *exception)
        {
            [_layerHistory addLogEntry:[NSString stringWithFormat:@"Exception: %@",exception]];
            NSNumber *e = exception.userInfo[@"errno"];
            int err = e.intValue;
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:[NSString stringWithFormat:@"%@ %@",exception.name,exception.reason]];
            }
            if(exception.userInfo)
            {
                if(e)
                {
                    [self logMajorError:[NSString stringWithFormat:@"%@ %@",exception.name,exception.reason]];
                }
            }
            if((err != EINPROGRESS) && (err != EAGAIN))
            {
                [self powerdown:[NSString stringWithFormat:@"errno=%d exception:%@ %@",err,exception.name,exception.reason] ];
            }
        }
        @finally
        {
            ummutex_unlock(_linkLock);
        }
    }
 }

- (void)_closeTask:(UMSctpTask_Close *)task
{
    @autoreleasepool
    {
        NSNumber *socketNumber = NULL;
        [self addToLayerHistoryLog:@"_closeTask"];
        ummutex_lock(_linkLock);
        @try
        {
#if defined(ULIBSCTP_CONFIG_DEBUG)
            if(self.logLevel <=UMLOG_DEBUG)
            {
                id<UMLayerSctpUserProtocol> user = (id<UMLayerSctpUserProtocol>)task.sender;
                [self logDebug:[NSString stringWithFormat:@"closing for %@",user.layerName]];
            }
#endif
            [self powerdown:@"_closeTask"];
            [_directReceiver shutdownBackgroundTask];
            _directReceiver = NULL;
            if(_directSocket)
            {
                socketNumber = @(_directSocket.sock);
                [_directSocket close];
                _directSocket = NULL;
            }
            else if(_listener)
            {
                socketNumber = @(- _listener.umsocket.sock);
            }
            _directSocket = NULL;
            [_listener stopListeningFor:self];
        }
        @catch(NSException *e)
        {
            if(_logLevel <=UMLOG_DEBUG)
            {
                NSLog(@"%@",e);
            }
        }
        @finally
        {
            ummutex_unlock(_linkLock);
        }
#if defined(POWER_DEBUG)
        NSLog(@"%@ closeTask(end)",_layerName);
#endif
        [self reportStatusWithReason:@"closeTask completed" socketNumber:socketNumber];
    }
}


- (void)reportError:(UMSocketError)err taskData:(UMSctpTask_Data *)task
{

    id<UMLayerSctpUserProtocol> user = (id<UMLayerSctpUserProtocol>)task.sender;

    NSString *errString= [UMSocket getSocketErrorString:err];;
    [self addToLayerHistoryLog:[NSString stringWithFormat:@"reportError(%d) %@",err,errString]];
    [self logMajorError:[NSString stringWithFormat:@"%@",errString]];
    if(task.ackRequest)
    {
        NSMutableDictionary *report = [task.ackRequest mutableCopy];
        NSDictionary *ui = @{
                         @"protocolId" : task.protocolId,
                         @"streamId"   : task.streamId,
                         @"data"       : task.data
                         };
        [report setObject:ui forKey:@"sctp_data"];
        NSDictionary *errDict = @{
                              @"exception"  : errString,
                              };
        [report setObject:errDict forKey:@"sctp_error"];
        [user sentAckFailureFrom:self
                    userInfo:report
                       error:errString
                      reason:@""
                   errorInfo:errDict];
    }
}

- (void)_dataTask:(UMSctpTask_Data *)task
{
    UMSleeper *sleeper = [[UMSleeper alloc]initFromFile:__FILE__ line:__LINE__ function:__func__];
    @autoreleasepool
    {
        id<UMLayerSctpUserProtocol> user = (id<UMLayerSctpUserProtocol>)task.sender;
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"DATA: %@",task.data]];
            [self logDebug:[NSString stringWithFormat:@" streamId: %@",task.streamId]];
            [self logDebug:[NSString stringWithFormat:@" protocolId: %@",task.protocolId]];
            [self logDebug:[NSString stringWithFormat:@" ackRequest: %@",(task.ackRequest ? task.ackRequest.description  : @"(not present)")]];
        }
        if(task.data == NULL)
        {
            /* nothing to be done */
            return;
        }
        ummutex_lock(_linkLock);
        @try
        {
            
            UMSocketError uerr = UMSocketError_no_error;
            ssize_t sent_packets = 0;
            int attempts=0;
            /* we try to send as long as no ASSOC down has been received or at least once (as we might not have a direct socket yet */
            int maxatt = 50;
            while((attempts < maxatt) && (self.status==UMSOCKET_STATUS_IS) && (sent_packets<1))
            {
                attempts++;
                if((self.directSocket)  && (self.directSocket.isConnected==YES))
                {
#if defined(ULIBSCTP_CONFIG_DEBUG)
                    if(self.logLevel <= UMLOG_DEBUG)
                    {
                        [self logDebug:[NSString stringWithFormat:@" Calling sctp_sendmsg on _directsocket (%@)",[_configured_remote_addresses componentsJoinedByString:@","]]];
                    }
#endif
                    NSNumber *tmp_assocId = _assocId;
                    uerr = UMSocketError_no_error;
                    sent_packets = [self.directSocket sendToAddresses:_configured_remote_addresses
                                                                 port:_configured_remote_port
                                                             assocPtr:&tmp_assocId
                                                                 data:task.data
                                                               stream:task.streamId
                                                             protocol:task.protocolId
                                                                error:&uerr];
                    if(uerr !=UMSocketError_no_error)
                    {
                        NSString *s = [NSString stringWithFormat:@"sendToAddresses:%@ port:%d assoc:%@ returns error:%d %@",
                                       _configured_remote_addresses,_configured_remote_port,_assocId,uerr,[UMSocket getSocketErrorString:uerr]];
                        [self addToLayerHistoryLog:s];
                    }
                    _assocId = tmp_assocId ;
                }
                else
                {
                    [self.directSocket close];
                    self.directSocket = NULL;
                    NSNumber *tmp_assocId = _assocId;
                    sent_packets = [self.listener sendToAddresses:_configured_remote_addresses
                                                             port:_configured_remote_port
                                                         assocPtr:&tmp_assocId
                                                             data:task.data
                                                           stream:task.streamId
                                                         protocol:task.protocolId
                                                            error:&uerr
                                                            layer:self];
                    _assocId = tmp_assocId;
                }
                /*  we loop until we get errno not EAGAIN or sent_packets returning > 0 */
                if(sent_packets > 0)
                {
                    break;
                }
                else if(uerr == UMSocketError_try_again)
                {
                    
                    /* we have EAGAIN */
                    /* lets try up to 50 times and wait 200ms every 10th time */
                    /* if thats still not succeeding, we declare this connection dead */
                    if(attempts % 10==0)
                    {
                        ummutex_unlock(_linkLock);
                        [sleeper sleepSeconds:0.2];
                        ummutex_lock(_linkLock);
                    }
                    if(attempts < maxatt)
                    {
                        uerr = UMSocketError_no_error;
                        continue;
                    }
                    /* if we get here we have attempted 50 times and failed */
                    /* we can assume this connection dead */
                    NSString *s = @"tried to send 50 times and got UMSocketError_try_again every time";
                    [_layerHistory addLogEntry:s];
                }
                else
                {
                    break;
                }
            } /* end of while */
#if defined(ULIBSCTP_CONFIG_DEBUG)
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:[NSString stringWithFormat:@" sent_packets: %ld",sent_packets]];
            }
#endif
            if(uerr==UMSocketError_no_error)
            {
                if(sent_packets> 0)
                {
                    [_outboundThroughputPackets increaseBy:1];
                    [_outboundThroughputBytes increaseBy:(uint32_t)task.data.length];
                    NSArray *usrs = [_users arrayCopy];
                    for(UMLayerSctpUser *u in usrs)
                    {
                        if([u.profile wantsMonitor])
                        {
                            [u.user sctpMonitorIndication:self
                                                   userId:u.userId
                                                 streamId:(uint16_t)task.streamId.unsignedIntValue
                                               protocolId:(uint32_t)task.protocolId.unsignedLongValue
                                                     data:task.data
                                                 incoming:NO
                                                   socket:task.socketNumber];
                        }
                    }
                    NSDictionary *ui = @{
                        @"protocolId" : task.protocolId,
                        @"streamId"   : task.streamId,
                        @"data"       : task.data
                    };
                    NSMutableDictionary *report = [task.ackRequest mutableCopy];
                    [report setObject:ui forKey:@"sctp_data"];
                    //report[@"backtrace"] = UMBacktrace(NULL,0);
                    [user sentAckConfirmFrom:self userInfo:report];
                }
            }
            else
            {
                NSString *s = [NSString stringWithFormat:@"Error %d %@",uerr,[UMSocket getSocketErrorString:uerr]];
                [_layerHistory addLogEntry:s];
                if(uerr==UMSocketError_is_already_connected)
                {
                    if(_logLevel <=UMLOG_MINOR)
                    {
                        NSLog(@"already connected");
                    }
                }
                [self reportError:uerr taskData:task];
                [self powerdown:@"error in _dataTask"];
                [self reportStatusWithReason:@"powerdown due to error in dataTask"];
            }
        }
        @finally
        {
            ummutex_unlock(_linkLock);
        }
    }
}

- (void)_foosTask:(UMSctpTask_Manual_ForceOutOfService *)task
{
    @autoreleasepool
    {
        [self addToLayerHistoryLog:@"_foosTask" ];

        ummutex_lock(_linkLock);
        @try
        {
            [self powerdown:@"_foosTask"];
            [self setStatus:UMSOCKET_STATUS_FOOS reason:@"FOOS requested"];
        #if defined(ULIBSCTP_CONFIG_DEBUG)
            if(self.logLevel <=UMLOG_DEBUG)
            {
                [self logDebug:@"FOOS"];
            }
        #endif
        }
        @finally
        {
            ummutex_unlock(_linkLock);
        }
#if defined(POWER_DEBUG)
        NSLog(@"%@ manual FOOS",_layerName);
#endif
        [self reportStatusWithReason:@"FOOS task"];
    }
}

- (void)_isTask:(UMSctpTask_Manual_InService *)task
{
    @autoreleasepool
    {
        [self addToLayerHistoryLog:@"_isTask" ];

        id<UMLayerSctpUserProtocol> user = (id<UMLayerSctpUserProtocol>)task.sender;

        switch(self.status)
        {
            case UMSOCKET_STATUS_FOOS:
                [self setStatus:UMSOCKET_STATUS_OFF reason:@"_isTask"];
                [self reportStatusWithReason:@"isTask status was FOOS so we go OFF"];
                [self openFor:user sendAbortFirst:NO];
                break;
            case UMSOCKET_STATUS_OFF:
                [self openFor:user];
                break;
                
            case UMSOCKET_STATUS_OOS:
                [self reportStatusWithReason:@"isTask started"];
                break;

            case UMSOCKET_STATUS_IS:
                [self reportStatusWithReason:@"isTask reported IS"];
                break; 
            case UMSOCKET_STATUS_LISTENING:
                [self reportStatusWithReason:@"isTask reported LISTENING"];
                break;
        }
    }
}


#pragma mark -
#pragma mark Helpers

- (void)powerdown
{
    [self powerdown:NULL];
}

- (void) powerdown:(NSString *)reason
{
    @autoreleasepool
    {
        if(reason)
        {
            [self addToLayerHistoryLog:[NSString stringWithFormat:@"powerdown (reason=%@)",reason]];
        }
        else
        {
            [self addToLayerHistoryLog:@"powerdown"];
        }
        [self setStatus:UMSOCKET_STATUS_OOS reason:@"powerdown"];
        [self setStatus:UMSOCKET_STATUS_OFF reason:@"powerdown"];
        if(_assocId!=NULL)
        {
            [_listener unregisterAssoc:_assocId forLayer:self];
            _assocId = NULL;
            if(_directSocket)
            {
                [_directSocket close];
                _directSocket = NULL;
                [_listener unregisterAssoc:_assocId forLayer:self];
                _assocId=NULL;
                [_registry unregisterLayer:self];
            }
            if(_directReceiver)
            {
                [_directReceiver shutdownBackgroundTaskFromWithin];
            }
            _directSocket = NULL;
        }
    }
}

- (void) powerdownInReceiverThread
{
    [self powerdownInReceiverThread:NULL];
}

- (void) powerdownInReceiverThread:(NSString *)reason
{
    @autoreleasepool
    {
        [self addToLayerHistoryLog:[NSString stringWithFormat:@"powerdownInReceiverThread %@",reason ? reason : @""]];
    #if defined(ULIBSCTP_CONFIG_DEBUG)
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self.logFeed debugText:[NSString stringWithFormat:@"powerdown"]];
        }
    #endif
        [self setStatus:UMSOCKET_STATUS_OFF reason:@"powerdownInReceiverThread"];
        if(_assocId!=NULL)
        {
            [_listener unregisterAssoc:_assocId forLayer:self];
            _assocId = NULL;
        }
        [_directSocket close];
        _directSocket = NULL;
    }
}

- (void)reportStatus
{
    [self reportStatusWithReason:NULL socketNumber:NULL];
}

- (void)reportStatusWithReason:(NSString *)reason
{
    if(_directSocket)
    {
        [self reportStatusWithReason:reason socketNumber:@(_directSocket.sock)];
    }
    else if(_listener)
    {
        [self reportStatusWithReason:reason socketNumber:@(_listener.umsocket.sock)];
    }
    else
    {
        [self reportStatusWithReason:reason socketNumber:NULL];
    }
}

- (void)reportStatusWithReason:(NSString *)reason socketNumber:(NSNumber *)socketNumber
{
    @autoreleasepool
    {
        NSArray *usrs = [_users arrayCopy];
        for(UMLayerSctpUser *u in usrs)
        {
            if([u.profile wantsStatusUpdates])
            {
                [u.user sctpStatusIndication:self
                                      userId:u.userId
                                      status:self.status
                                      reason:reason
                                      socket:socketNumber];
            }
        }
    }
}


- (void)processReceivedData:(UMSocketSCTPReceivedPacket *)rx
{
    @autoreleasepool
    {
        ummutex_lock(_linkLock);
        @try
        {
                if(rx.err==UMSocketError_try_again)
                {
                    return;
                }
                if(rx.err==UMSocketError_invalid_file_descriptor)
                {
                    if(_logLevel <=UMLOG_DEBUG)
                    {
                        NSLog(@"receiveData: UMSocketError_invalid_file_descriptor returned by receiveSCTP");
                    }
                    [self powerdownInReceiverThread:@"invalid_file_descriptor"];
                    [self reportStatusWithReason:@"processRedeivedData: invalid_file_descriptor" socketNumber:rx.socket];
                }
                
                else if(rx.err==UMSocketError_invalid_file_descriptor)
                {
                    if(_logLevel <=UMLOG_DEBUG)
                    {
                        NSLog(@"receiveData: UMSocketError_invalid_file_descriptor returned by receiveSCTP");
                    }
                    [self powerdownInReceiverThread:@"invalid_file_descriptor"];
                    [self reportStatusWithReason:@"processRedeivedData: invalid_file_descriptor" socketNumber:rx.socket];
                }
                else if(rx.err==UMSocketError_connection_reset)
                {
                    [self logDebug:@"ECONNRESET"];
                    [self powerdownInReceiverThread:@"ECONNRESET"];
                    [self reportStatusWithReason:@"processRedeivedData ECONNRESET" socketNumber:rx.socket];
                }

                else if(rx.err==UMSocketError_connection_aborted)
                {
                    [self logDebug:@"ECONNABORTED"];
                    [self powerdownInReceiverThread:@"ECONNABORTED"];
                    [self reportStatusWithReason:@"processRedeivedData ECONNABORTED" socketNumber:rx.socket];
                }
                else if(rx.err==UMSocketError_connection_refused)
                {
                    [self logDebug:@"ECONNREFUSED"];
                    sleep(1);
                    [self powerdownInReceiverThread:@"ECONNREFUSED"];
                    [self reportStatusWithReason:@"processRedeivedData ECONNREFUSED"];
                }
                else if(rx.err != UMSocketError_no_error)
                {
                    NSString *s = [NSString stringWithFormat:@"processReceivedData: Error %d %@ returned by receiveSCTP",rx.err,[UMSocket getSocketErrorString:rx.err]];
                    [self logMinorError:s];
                    [self powerdownInReceiverThread:s];
                    [self reportStatusWithReason:s socketNumber:rx.socket];
                }
                else /* UMSocketError_no_error */
                {
                    if((_directSocket == NULL) && (rx.assocId!=NULL))
                    {
                        UMSocketError err = UMSocketError_no_error;
                        int e = -1;
                        _directSocket = [_listener peelOffAssoc:rx.assocId error:&err errorNumber:&e];
                        [self addToLayerHistoryLog:[NSString stringWithFormat:@"processReceivedData: peeling off assoc %lu into socket %p/%d err=%d/%@ errno=%d",
                                                    (unsigned long)_assocId.unsignedLongValue,
                                                    _directSocket,
                                                    _directSocket.sock,
                                                    err,[UMSocket getSocketErrorString:err],
                                                    e]];
                        if(_directSocket==NULL)
                        {
                            NSString *s = [NSString stringWithFormat:@"processReceivedData peeloff failed"];
                            [self addToLayerHistoryLog:s];
                        }
                        else if((err != UMSocketError_no_error) && (err !=UMSocketError_in_progress))
                        {
                            [_directSocket close];
                            _directSocket = NULL;
                            [_listener unregisterAssoc:_assocId forLayer:self];
                            _assocId = NULL;
                            NSString *s = [NSString stringWithFormat:@"processReceivedData peeloff failed"];
                            [self logMinorError:s];
                            [self powerdownInReceiverThread:s];
                            [self reportStatusWithReason:s socketNumber:rx.socket];
                            _assocId = NULL;
                        }
                        else
                        {
                            [self startDirectSocketReceiver];
                            if(rx.assocId !=NULL)
                            {
                                _assocId = rx.assocId;
                            }
                        }
                    }
                    if(rx.isNotification)
                    {
                        [self handleEvent:rx.data
                                 streamId:rx.streamId
                               protocolId:rx.protocolId
                                   socket:rx.socket];
                    }
                    else
                    {
                        [self sctpReceivedData:rx.data
                                      streamId:rx.streamId
                                    protocolId:rx.protocolId
                                        socket:rx.socket];
                    }
                }
        }
        @finally
        {
            ummutex_unlock(_linkLock);
        }
    }
}

-(void) handleEvent:(NSData *)event
           streamId:(NSNumber *)streamId
         protocolId:(NSNumber *)protocolId
             socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return;
#else
    @autoreleasepool
    {
        ummutex_lock(_linkLock);
        @try
        {
            
            const union sctp_notification *snp;
            snp = event.bytes;
            switch(snp->sn_header.sn_type)
            {
                case SCTP_ASSOC_CHANGE:
                    [self handleAssocChange:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
                case SCTP_PEER_ADDR_CHANGE:
                    [self handlePeerAddrChange:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
                case SCTP_SEND_FAILED:
                    [self handleSendFailed:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
                case SCTP_REMOTE_ERROR:
                    [self handleRemoteError:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
                case SCTP_SHUTDOWN_EVENT:
                    [self handleShutdownEvent:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
                case SCTP_PARTIAL_DELIVERY_EVENT:
                    [self handleAdaptionIndication:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
                case SCTP_ADAPTATION_INDICATION:
                    [self handleAdaptionIndication:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
        #if defined SCTP_AUTHENTICATION_EVENT
                case SCTP_AUTHENTICATION_EVENT:
                    [self handleAuthenticationEvent:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
        #endif
                case SCTP_SENDER_DRY_EVENT:
                    [self handleSenderDryEvent:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;

        #if defined SCTP_STREAM_RESET_EVENT
                case  SCTP_STREAM_RESET_EVENT:
                    [self handleStreamResetEvent:event streamId:streamId protocolId:protocolId socket:socketNumber];
                    break;
        #endif

                default:
                    [self.logFeed majorErrorText:[NSString stringWithFormat:@"SCTP unknown event type: %hu", snp->sn_header.sn_type]];
                    [self.logFeed majorErrorText:[NSString stringWithFormat:@" RX-STREAM: %lu",streamId.unsignedLongValue]];
                    [self.logFeed majorErrorText:[NSString stringWithFormat:@" RX-PROTO: %lu", protocolId.unsignedLongValue]];
                    [self.logFeed majorErrorText:[NSString stringWithFormat:@" RX-DATA: %@",event.description]];
            }
        }
        @finally
        {
            ummutex_unlock(_linkLock);
        }
    }
#endif
}

-(void) handleAssocChange:(NSData *)event
                 streamId:(NSNumber *)streamId
               protocolId:(NSNumber *)protocolId
                   socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return;
#else
    ummutex_lock(_linkLock);
    @try
    {
        const union sctp_notification *snp;
        snp = event.bytes;
        NSUInteger len = event.length;

        if(len < sizeof (struct sctp_assoc_change))
        {
            [self.logFeed majorErrorText:@" Size Mismatch in SCTP_ASSOC_CHANGE"];
        }
        
        NSString *state = @"(UNKNOWN)";
        switch(snp->sn_assoc_change.sac_state)
        {
            case SCTP_COMM_UP:
                state =@"SCTP_COMM_UP";
                break;
            case SCTP_COMM_LOST:
                state =@"SCTP_COMM_LOST";
                break;
            case SCTP_RESTART:
                state =@"SCTP_RESTART";
                break;
            case SCTP_SHUTDOWN_COMP:
                state =@"SCTP_SHUTDOWN_COMP";
                break;
            case SCTP_CANT_STR_ASSOC:
                state =@"SCTP_CANT_STR_ASSOC";
                break;
        }
        [self addToLayerHistoryLog:state];
        
    #if defined(ULIBSCTP_CONFIG_DEBUG)
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"  sac_type: %d",             (int)snp->sn_assoc_change.sac_type]];
            [self logDebug:[NSString stringWithFormat:@"  sac_flags: %d",            (int)snp->sn_assoc_change.sac_flags]];
            [self logDebug:[NSString stringWithFormat:@"  sac_length: %d",           (int)snp->sn_assoc_change.sac_length]];
            [self logDebug:[NSString stringWithFormat:@"  sac_state: %d %@",            (int)snp->sn_assoc_change.sac_state, state]];
            [self logDebug:[NSString stringWithFormat:@"  sac_error: %d",            (int)snp->sn_assoc_change.sac_error]];
            [self logDebug:[NSString stringWithFormat:@"  sac_outbound_streams: %d", (int)snp->sn_assoc_change.sac_outbound_streams]];
            [self logDebug:[NSString stringWithFormat:@"  sac_inbound_streams: %d",  (int)snp->sn_assoc_change.sac_inbound_streams]];
            [self logDebug:[NSString stringWithFormat:@"  sac_assoc_id: %d",         (int)snp->sn_assoc_change.sac_assoc_id]];
        }
    #endif
        if(snp->sn_assoc_change.sac_state==SCTP_COMM_UP)
        {
            uint32_t ass = snp->sn_assoc_change.sac_assoc_id;
            _listener.firstMessage=YES;
            NSString *s=[NSString stringWithFormat:@" SCTP_ASSOC_CHANGE: SCTP_COMM_UP->IS (assocID=%u)",ass];
            [self.logFeed infoText:s];
            [_layerHistory addLogEntry:s];
            s = [NSString stringWithFormat:@"directSocket=%@",_directSocket ? @(_directSocket.sock): @"NULL"];
            [_layerHistory addLogEntry:s];
            s = [NSString stringWithFormat:@"listenerSocket=%@",_listener.umsocket ? @(_listener.umsocket.sock): @"NULL"];
            [_layerHistory addLogEntry:s];
            if((_directSocket==NULL) && (ass>0))
            {
                [_layerHistory addLogEntry:@"doing peeloff"];
                UMSocketError err = UMSocketError_not_known;
                _assocId = @(ass);
                int e = -1;
                _directSocket = [_listener peelOffAssoc:_assocId error:&err errorNumber:&e];
                NSString *s=[NSString stringWithFormat:@"handleAssocChange: peeling off assoc %u into socket %p/%d err=%d/%@ errno=%d",ass,_directSocket,_directSocket.sock,err,[UMSocket getSocketErrorString:err],e];
                [self addToLayerHistoryLog:s];
                if(_directSocket==NULL)
                {
                    NSString *s = [NSString stringWithFormat:@"handleAssocChange peeloff failed"];
                    [self addToLayerHistoryLog:s];
                }
                else if((err != UMSocketError_no_error) && (err !=UMSocketError_in_progress))
                {
                    [_directSocket close];
                    _directSocket = NULL;
                    [_listener unregisterAssoc:_assocId forLayer:self];
                    _assocId=NULL;
                    NSString *s = [NSString stringWithFormat:@"handleAssocChange peeloff failed"];
                    [self logMinorError:s];
                    [self powerdownInReceiverThread:s];
                    [self reportStatusWithReason:s socketNumber:socketNumber];
                    NSLog(@"%@",s);
                }
                else
                {
                    NSString *s = [NSString stringWithFormat:@"handleAssocChange peeloff succeeded"];
                    [self addToLayerHistoryLog:s];
                    [self startDirectSocketReceiver];
                }
            }
            else
            {
                [_layerHistory addLogEntry:@"skipping peeloff"];
            }
            [_reconnectTimer stop];
            [self setStatus:UMSOCKET_STATUS_IS reason:@"COM_UP"];
        }
        else if(snp->sn_assoc_change.sac_state==SCTP_COMM_LOST)
        {
            uint32_t ass = snp->sn_assoc_change.sac_assoc_id;
            _assocId = @(ass);
            if(_directSocket)
            {
                _directSocket.isConnected=NO;
            }
            [self.logFeed infoText:[NSString stringWithFormat:@" SCTP_ASSOC_CHANGE: SCTP_COMM_LOST->OFF (assocID=%u)",ass]];
    #if defined(POWER_DEBUG)
            NSLog(@"%@ SCTP_COMM_LOST",_layerName);
    #endif
            [self powerdownInReceiverThread:@"SCTP_COMM_LOST (closing direct socket)"];
            [self reportStatusWithReason:@"SCTP_COMM_LOST" socketNumber:socketNumber];
    #if defined(ULIBSCTP_CONFIG_DEBUG)
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:[NSString stringWithFormat:@"starting reconnectTimer %8.3lfs",_reconnectTimer.seconds]];
            }
    #endif
            [_reconnectTimer stop];
            [_reconnectTimer start];
        }
        else if(snp->sn_assoc_change.sac_state==SCTP_CANT_STR_ASSOC)
        {
            if(_directSocket)
            {
                _directSocket.isConnected=NO;
            }
            [self.logFeed infoText:@" SCTP_ASSOC_CHANGE: SCTP_CANT_STR_ASSOC"];
    #if defined(POWER_DEBUG)
            NSLog(@"%@ SCTP_CANT_STR_ASSOC",_layerName);
    #endif
            [self powerdownInReceiverThread:@"SCTP_CANT_STR_ASSOC"];
            [self reportStatusWithReason:@"SCTP_CANT_STR_ASSOC" socketNumber:socketNumber];
    #if defined(ULIBSCTP_CONFIG_DEBUG)
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:[NSString stringWithFormat:@"starting reconnectTimer %8.3lfs",_reconnectTimer.seconds]];
            }
    #endif
            [_reconnectTimer stop];
            [_reconnectTimer start];
        }
        else if(snp->sn_assoc_change.sac_error!=0)
        {
            if(_directSocket)
            {
                _directSocket.isConnected=NO;
            }
            [self.logFeed majorError:snp->sn_assoc_change.sac_error withText:@" SCTP_ASSOC_CHANGE: SCTP_COMM_ERROR(%d)->OFF"];
    #if defined(POWER_DEBUG)
            NSLog(@"%@ SCTP_ASSOC_CHANGE: SCTP_COMM_ERROR(%d)",_layerName,snp->sn_assoc_change.sac_error );
    #endif
            NSString *s = [NSString stringWithFormat:@"SCTP_COMM_ERROR(%d) closing direct socket",snp->sn_assoc_change.sac_error];
            [self powerdownInReceiverThread:s];
            [self reportStatusWithReason:s socketNumber:socketNumber];
            [_reconnectTimer stop];
            [_reconnectTimer start];
        }
    }
    @finally
    {
        ummutex_unlock(_linkLock);
    }
#endif
}

-(void) handleLinkUpTcpEcnap
{
    [self.logFeed infoText:[NSString stringWithFormat:@" SCTP_TCP_ASSOC_CHANGE: SCTP_COMM_UP->IS"]];
    [self setStatus:UMSOCKET_STATUS_IS reason:@"handleLinkUpTcpEcnap"];
    [_reconnectTimer stop];
#if defined(POWER_DEBUG)
    NSLog(@"%@ handleLinkUpTcpEcnap",_layerName);
#endif
    [self reportStatusWithReason:@"handleLinkUpTcpEcnap"];

}

-(void) handleLinkDownTcpEcnap
{
    _listener.firstMessage=YES;
    [self.logFeed infoText:[NSString stringWithFormat:@" SCTP_TCP_ASSOC_CHANGE: SCTP_COMM_LOST->OFF"]];
    [self setStatus:UMSOCKET_STATUS_OFF reason:@"handleLinkDownTcpEcnap"];
#if defined(POWER_DEBUG)
    NSLog(@"%@ handleLinkDownTcpEcnap",_layerName);
#endif

    [self powerdownInReceiverThread:@"handleLinkDownTcpEcnap"];
    [self reportStatusWithReason:@"handleLinkDownTcpEcnap"];
    [_reconnectTimer start];
}

-(void) handlePeerAddrChange:(NSData *)event
                    streamId:(NSNumber *)streamId
                  protocolId:(NSNumber *)protocolId
                      socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return;
#else
    const union sctp_notification *snp;

    char addrbuf[INET6_ADDRSTRLEN];
    const char *ap;
    struct sockaddr_in *sin;
    struct sockaddr_in6 *sin6;

    snp = event.bytes;
    NSUInteger len = event.length;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_PEER_ADDR_CHANGE"];
    }
#endif
    if(len < sizeof (struct sctp_paddr_change))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_PEER_ADDR_CHANGE"];
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  spc_type: %d",    (int)snp->sn_paddr_change.spc_type]];
        [self logDebug:[NSString stringWithFormat:@"  spc_flags: %d",   (int)snp->sn_paddr_change.spc_flags]];
        [self logDebug:[NSString stringWithFormat:@"  spc_length: %d",  (int)snp->sn_paddr_change.spc_length]];
    }
#endif
    if (snp->sn_paddr_change.spc_aaddr.ss_family == AF_INET)
    {
        //struct sockaddr_in *sin;
        sin = (struct sockaddr_in *)&snp->sn_paddr_change.spc_aaddr;
        ap = inet_ntop(AF_INET, &sin->sin_addr, addrbuf, INET6_ADDRSTRLEN);
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"  spc_aaddr: ipv4:%s", ap]];
        }
    }
    else
    {
        sin6 = (struct sockaddr_in6 *)&snp->sn_paddr_change.spc_aaddr;
        ap = inet_ntop(AF_INET6, &sin6->sin6_addr, addrbuf, INET6_ADDRSTRLEN);
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"  spc_aaddr: ipv6:%s", ap]];
        }
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  spc_state: %d",   (int)snp->sn_paddr_change.spc_state]];
        [self logDebug:[NSString stringWithFormat:@"  spc_error: %d",   (int)snp->sn_paddr_change.spc_error]];
        if (snp->sn_paddr_change.spc_aaddr.ss_family == AF_INET)
        {
            [self logDebug:[NSString stringWithFormat:@" SCTP_PEER_ADDR_CHANGE: ipv4:%s",ap]];
        }
        else
        {
            [self logDebug:[NSString stringWithFormat:@" SCTP_PEER_ADDR_CHANGE: ipv6:%s",ap]];
        }
    }
#endif
#endif
}

-(void) handleRemoteError:(NSData *)event
                 streamId:(NSNumber *)streamId
               protocolId:(NSNumber *)protocolId
                   socket:(NSNumber *)socketNumber

{
#if !defined(HAVE_SCTP)
    return;
#else

#if defined(ULIBSCTP_CONFIG_DEBUG)
    const union sctp_notification *snp;
    snp = event.bytes;
#endif
    NSUInteger len = event.length;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_REMOTE_ERROR"];
    }
#endif
    if(len < sizeof (struct sctp_remote_error))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_REMOTE_ERROR"];
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)

    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  sre_type: %d",             (int)snp->sn_remote_error.sre_type]];
        [self logDebug:[NSString stringWithFormat:@"  sre_flags: %d",            (int)snp->sn_remote_error.sre_flags]];
        [self logDebug:[NSString stringWithFormat:@"  sre_length: %d",           (int)snp->sn_remote_error.sre_length]];
        [self logDebug:[NSString stringWithFormat:@"  sre_length: %d",           (int)snp->sn_remote_error.sre_error]];
        [self logDebug:[NSString stringWithFormat:@"  sre_assoc_id: %d",         (int)snp->sn_remote_error.sre_assoc_id]];
        [self logDebug:[NSString stringWithFormat:@"  sre_data: %02X %02X %02X %02x",
                        (int)snp->sn_remote_error.sre_data[0],
                        (int)snp->sn_remote_error.sre_data[1],
                        (int)snp->sn_remote_error.sre_data[2],
                        (int)snp->sn_remote_error.sre_data[3]]];
    }
#endif
#endif
}


-(int) handleSendFailed:(NSData *)event
               streamId:(NSNumber *)streamId
             protocolId:(NSNumber *)protocolId
                 socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return -1;
#else

    const union sctp_notification *snp;
    snp = event.bytes;
    NSUInteger len = event.length;


#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_SEND_FAILED"];
    }
#endif
    if(len < sizeof (struct sctp_send_failed))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_SEND_FAILED"];
#if defined(POWER_DEBUG)
        NSLog(@"%@ SCTP_SEND_FAILED(size mismatch)",_layerName);
#endif
        [self powerdownInReceiverThread:@"Size Mismatch in SCTP_SEND_FAILED"];
        [self reportStatusWithReason:@"Size Mismatch in SCTP_SEND_FAILED"];
        return UMSocketError_not_supported_operation;
    }
    [self.logFeed majorErrorText:@"SCTP_SEND_FAILED"];
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  ssf_type: %d",                (int)snp->sn_send_failed.ssf_type]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_flags: %d",               (int)snp->sn_send_failed.ssf_flags]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_length: %d",              (int)snp->sn_send_failed.ssf_length]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_error: %d",               (int)snp->sn_send_failed.ssf_error]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_assoc_id: %d",            (int)snp->sn_send_failed.ssf_assoc_id]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_stream: %d",   (int)snp->sn_send_failed.ssf_info.sinfo_stream]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_ssn: %d",      (int)snp->sn_send_failed.ssf_info.sinfo_ssn]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_flags: %d",    (int)snp->sn_send_failed.ssf_info.sinfo_flags]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_stream: %d",   (int)snp->sn_send_failed.ssf_info.sinfo_stream]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_context: %d",  (int)snp->sn_send_failed.ssf_info.sinfo_context]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_timetolive: %d",(int)snp->sn_send_failed.ssf_info.sinfo_timetolive]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_tsn: %d",      (int)snp->sn_send_failed.ssf_info.sinfo_tsn]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_cumtsn: %d",   (int)snp->sn_send_failed.ssf_info.sinfo_cumtsn]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_info.sinfo_assoc_id: %d", (int)snp->sn_send_failed.ssf_info.sinfo_assoc_id]];
        [self logDebug:[NSString stringWithFormat:@"  ssf_assoc_id: %d",    (int)snp->sn_send_failed.ssf_assoc_id]];
    }
#endif
    [self.logFeed majorErrorText:[NSString stringWithFormat:@"SCTP sendfailed: len=%u err=%d\n", snp->sn_send_failed.ssf_length,snp->sn_send_failed.ssf_error]];
#if defined(POWER_DEBUG)
    NSLog(@"%@ SCTP_SEND_FAILED len=%u err=%d\n",_layerName,snp->sn_send_failed.ssf_length,snp->sn_send_failed.ssf_error);
#endif
    [self powerdownInReceiverThread:@"SCTP_SEND_FAILED"];
    [self reportStatusWithReason:@"SCTP_SEND_FAILED"];
    return -1;
#endif
}


-(int) handleShutdownEvent:(NSData *)event
                  streamId:(NSNumber *)streamId
                protocolId:(NSNumber *)protocolId
                    socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return -1;
#else

#if defined(ULIBSCTP_CONFIG_DEBUG)
    const union sctp_notification *snp;
    snp = event.bytes;
#endif
    NSUInteger len = event.length;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_SHUTDOWN_EVENT"];
    }
#endif
    if(len < sizeof (struct sctp_shutdown_event))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_SHUTDOWN_EVENT"];
#if defined(POWER_DEBUG)
        NSLog(@"%@  Size Mismatch in SCTP_SHUTDOWN_EVENT",_layerName);
#endif
        [self powerdownInReceiverThread:@"Size Mismatch in SCTP_SHUTDOWN_EVENT"];
        [self reportStatusWithReason:@"Size Mismatch in SCTP_SHUTDOWN_EVENT"];
        return UMSocketError_not_supported_operation;
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  sse_type: %d",     (int)snp->sn_shutdown_event.sse_type]];
        [self logDebug:[NSString stringWithFormat:@"  sse_flags: %d",    (int)snp->sn_shutdown_event.sse_flags]];
        [self logDebug:[NSString stringWithFormat:@"  sse_length: %d",   (int)snp->sn_shutdown_event.sse_length]];
        [self logDebug:[NSString stringWithFormat:@"  sse_assoc_id: %d", (int)snp->sn_shutdown_event.sse_assoc_id]];
    }
#endif
    [self.logFeed warningText:@"SCTP_SHUTDOWN_EVENT->POWERDOWN"];
    
#if defined(POWER_DEBUG)
    NSLog(@"%@  SCTP_SHUTDOWN_EVENT->POWERDOWN",_layerName);
#endif
    [self powerdownInReceiverThread:@"SCTP_SHUTDOWN_EVENT"];
    [self reportStatusWithReason:@"SCTP_SHUTDOWN_EVENT"];
    return -1;
#endif
}


-(int) handleAdaptionIndication:(NSData *)event
                       streamId:(NSNumber *)streamId
                     protocolId:(NSNumber *)protocolId
                         socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return -1;
#else

#if defined(ULIBSCTP_CONFIG_DEBUG)
    const union sctp_notification *snp;
    snp = event.bytes;
#endif
    NSUInteger len = event.length;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_ADAPTATION_INDICATION"];
    }
#endif
    if(len < sizeof(struct sctp_adaptation_event))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_ADAPTATION_INDICATION"];
#if defined(POWER_DEBUG)
        NSLog(@"%@  Size Mismatch in SCTP_ADAPTATION_INDICATION",_layerName);
#endif
        [self powerdownInReceiverThread:@"Size mismatch in SCTP_ADAPTATION_INDICATION"];
        [self reportStatusWithReason:@"Size mismatch in SCTP_ADAPTATION_INDICATION"];
        return UMSocketError_not_supported_operation;
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  sai_type: %d",           (int)snp->sn_adaptation_event.sai_type]];
        [self logDebug:[NSString stringWithFormat:@"  sai_flags: %d",          (int)snp->sn_adaptation_event.sai_flags]];
        [self logDebug:[NSString stringWithFormat:@"  sai_length: %d",         (int)snp->sn_adaptation_event.sai_length]];
        [self logDebug:[NSString stringWithFormat:@"  sai_adaptation_ind: %d", (int)snp->sn_adaptation_event.sai_adaptation_ind]];
        [self logDebug:[NSString stringWithFormat:@"  sai_assoc_id: %d",       (int)snp->sn_adaptation_event.sai_assoc_id]];
    }
#endif
    return 0;
#endif
}

-(int) handlePartialDeliveryEvent:(NSData *)event
                         streamId:(uint32_t)streamId
                       protocolId:(uint16_t)protocolId
                           socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return -1;
#else

#if defined(ULIBSCTP_CONFIG_DEBUG)
    const union sctp_notification *snp;
    snp = event.bytes;
#endif
    NSUInteger len = event.length;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_PARTIAL_DELIVERY_EVENT"];
    }
#endif
    if(len < sizeof(struct sctp_pdapi_event))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_PARTIAL_DELIVERY_EVENT"];
#if defined(POWER_DEBUG)
        NSLog(@"%@  SCTP_PARTIAL_DELIVERY_EVENT",_layerName);
#endif

        [self powerdownInReceiverThread:@"Size mismatch in SCTP_PARTIAL_DELIVERY_EVENT"];
        [self reportStatusWithReason:@"Size mismatch in SCTP_PARTIAL_DELIVERY_EVENT"];
        return UMSocketError_not_supported_operation;
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  pdapi_type: %d",           (int)snp->sn_pdapi_event.pdapi_type]];
        [self logDebug:[NSString stringWithFormat:@"  pdapi_flags: %d",          (int)snp->sn_pdapi_event.pdapi_flags]];
        [self logDebug:[NSString stringWithFormat:@"  pdapi_length: %d",         (int)snp->sn_pdapi_event.pdapi_length]];
        [self logDebug:[NSString stringWithFormat:@"  pdapi_indication: %d",     (int)snp->sn_pdapi_event.pdapi_indication]];
#ifndef LINUX
        [self logDebug:[NSString stringWithFormat:@"  pdapi_stream: %d",         (int)snp->sn_pdapi_event.pdapi_stream]];
        [self logDebug:[NSString stringWithFormat:@"  pdapi_seq: %d",            (int)snp->sn_pdapi_event.pdapi_seq]];
#endif
        [self logDebug:[NSString stringWithFormat:@"  pdapi_assoc_id: %d",       (int)snp->sn_pdapi_event.pdapi_assoc_id]];
    }
#endif
    return UMSocketError_no_error;
#endif
}

-(int) handleAuthenticationEvent:(NSData *)event
                        streamId:(NSNumber *)streamId
                      protocolId:(NSNumber *)protocolId
                          socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return -1;
#else

#if defined(ULIBSCTP_CONFIG_DEBUG)
    const union sctp_notification *snp;
    snp = event.bytes;
#endif
    NSUInteger len = event.length;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_AUTHENTICATION_EVENT"];
    }
#endif
    if(len < sizeof(struct sctp_authkey_event))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_AUTHENTICATION_EVENT"];
#if defined(POWER_DEBUG)
        NSLog(@"%@  Size Mismatch in SCTP_AUTHENTICATION_EVENT",_layerName);
#endif

        [self powerdownInReceiverThread:@"Size mismatch in SCTP_AUTHENTICATION_EVENT"];
        [self reportStatusWithReason:@"Size mismatch in SCTP_AUTHENTICATION_EVENT"];
        return UMSocketError_not_supported_operation;
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
#if defined(LINUX)
        [self logDebug:[NSString stringWithFormat:@"  auth_type: %d",           (int)snp->sn_authkey_event.auth_type]];
        [self logDebug:[NSString stringWithFormat:@"  auth_flags: %d",          (int)snp->sn_authkey_event.auth_flags]];
        [self logDebug:[NSString stringWithFormat:@"  auth_length: %d",         (int)snp->sn_authkey_event.auth_length]];
        [self logDebug:[NSString stringWithFormat:@"  auth_keynumber: %d",      (int)snp->sn_authkey_event.auth_keynumber]];
        [self logDebug:[NSString stringWithFormat:@"  auth_altkeynumber: %d",   (int)snp->sn_authkey_event.auth_altkeynumber]];
        [self logDebug:[NSString stringWithFormat:@"  auth_indication: %d",     (int)snp->sn_authkey_event.auth_indication]];
        [self logDebug:[NSString stringWithFormat:@"  auth_assoc_id: %d",       (int)snp->sn_authkey_event.auth_assoc_id]];

#else
        [self logDebug:[NSString stringWithFormat:@"  auth_type: %d",           (int)snp->sn_auth_event.auth_type]];
        [self logDebug:[NSString stringWithFormat:@"  auth_flags: %d",          (int)snp->sn_auth_event.auth_flags]];
        [self logDebug:[NSString stringWithFormat:@"  auth_length: %d",         (int)snp->sn_auth_event.auth_length]];
        [self logDebug:[NSString stringWithFormat:@"  auth_keynumber: %d",      (int)snp->sn_auth_event.auth_keynumber]];
        [self logDebug:[NSString stringWithFormat:@"  auth_altkeynumber: %d",   (int)snp->sn_auth_event.auth_altkeynumber]];
        [self logDebug:[NSString stringWithFormat:@"  auth_indication: %d",     (int)snp->sn_auth_event.auth_indication]];
        [self logDebug:[NSString stringWithFormat:@"  auth_assoc_id: %d",       (int)snp->sn_auth_event.auth_assoc_id]];
#endif
    }
#endif
    return UMSocketError_no_error;
#endif
}

#if defined(SCTP_STREAM_RESET_EVENT)
-(int) handleStreamResetEvent:(NSData *)event
                     streamId:(NSNumber *)streamId
                   protocolId:(NSNumber *)protocolId
                       socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return UMSocketError_not_supported_operation;
#else

#if defined(ULIBSCTP_CONFIG_DEBUG)
    const union sctp_notification *snp;
    snp = event.bytes;
#endif
    NSUInteger len = event.length;

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_STREAM_RESET_EVENT"];
    }
#endif
    if(len < sizeof(struct sctp_stream_reset_event))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_STREAM_RESET_EVENT"];
#if defined(POWER_DEBUG)
        NSLog(@"%@  Size Mismatch in SCTP_STREAM_RESET_EVENT",_layerName);
#endif

        [self powerdownInReceiverThread:@"Size mismatch in SCTP_STREAM_RESET_EVENT"];
        [self reportStatusWithReason:@"Size mismatch in SCTP_STREAM_RESET_EVENT"];
        return UMSocketError_not_supported_operation;
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  strreset_type: %d",     (int)snp->sn_strreset_event.strreset_type]];
        [self logDebug:[NSString stringWithFormat:@"  strreset_flags: %d",    (int)snp->sn_strreset_event.strreset_flags]];
        [self logDebug:[NSString stringWithFormat:@"  strreset_length: %d",   (int)snp->sn_strreset_event.strreset_length]];
        [self logDebug:[NSString stringWithFormat:@"  strreset_assoc_id: %d", (int)snp->sn_strreset_event.strreset_assoc_id]];
    }
#endif
    [self setStatus:UMSOCKET_STATUS_OFF reason:@"handleStreamResetEvent"];
#if defined(POWER_DEBUG)
    NSLog(@"%@ handleStreamResetEvent",_layerName);
#endif
    [self reportStatusWithReason:@"SCTP_STREAM_RESET_EVENT"];
    return UMSocketError_no_error;
#endif
}
#endif

-(int) handleSenderDryEvent:(NSData *)event
                   streamId:(NSNumber *)streamId
                 protocolId:(NSNumber *)protocolId
                     socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return -1;
#else
    
#if defined(ULIBSCTP_CONFIG_DEBUG)
    const union sctp_notification *snp;
    snp = event.bytes;
#endif
    NSUInteger len = event.length;
    
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:@"SCTP_SENDER_DRY_EVENT"];
    }
#endif
    if(len < sizeof(struct sctp_sender_dry_event))
    {
        [self.logFeed majorErrorText:@" Size Mismatch in SCTP_SENDER_DRY_EVENT"];
#if defined(POWER_DEBUG)
        NSLog(@"%@ Size Mismatch in SCTP_SENDER_DRY_EVENT",_layerName);
#endif
        [self powerdownInReceiverThread:@"Size mismatch in SCTP_SENDER_DRY_EVENT"];
        [self reportStatusWithReason:@"Size mismatch in SCTP_SENDER_DRY_EVENT"];
        return UMSocketError_not_supported_operation;
    }
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(self.logLevel <= UMLOG_DEBUG)
    {
        [self logDebug:[NSString stringWithFormat:@"  sender_dry_type: %d",     (int)snp->sn_sender_dry_event.sender_dry_type]];
        [self logDebug:[NSString stringWithFormat:@"  sender_dry_flags: %d",    (int)snp->sn_sender_dry_event.sender_dry_flags]];
        [self logDebug:[NSString stringWithFormat:@"  sender_dry_length: %d",   (int)snp->sn_sender_dry_event.sender_dry_length]];
        [self logDebug:[NSString stringWithFormat:@"  sender_dry_assoc_id: %d", (int)snp->sn_sender_dry_event.sender_dry_assoc_id]];
    }
#endif
    return UMSocketError_no_error;
#endif
}


- (UMSocketError) sctpReceivedData:(NSData *)data
                          streamId:(NSNumber *)streamId
                        protocolId:(NSNumber *)protocolId
                            socket:(NSNumber *)socketNumber
{
#if !defined(HAVE_SCTP)
    return -1;
#else

    if(data.length == 0)
    {
        [self addToLayerHistoryLog:@"sctpReceiveData with data==NULL. Ignored"];
        return UMSocketError_no_error;
    }
    @autoreleasepool
    {
        [_inboundThroughputPackets increaseBy:1];
        [_inboundThroughputBytes increaseBy:(int)data.length];

    #if defined(ULIBSCTP_CONFIG_DEBUG)
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:[NSString stringWithFormat:@"RXT: got %u bytes on stream %u protocol_id: %u data:%@",
                            (unsigned int)data.length,
                            (unsigned int)streamId.unsignedIntValue,
                            (unsigned int)protocolId.unsignedIntValue,
                            data.hexString]];
        }
    #endif
        if(_defaultUser == NULL)
        {
            [self logDebug:@"RXT: USER instance not found. Maybe not bound yet?"];
#if defined(POWER_DEBUG)
            NSLog(@"%@ RXT: USER instance not found. Maybe not bound yet?",_layerName);
#endif
            [self powerdownInReceiverThread:@"USER instance not found. Maybe not bound yet"];
            [self reportStatusWithReason:@"USER instance not found. Maybe not bound yet"];
            return UMSocketError_no_buffers;
        }

        /* if for whatever reason we have not realized we are in service yet, let us realize it now */
        if(self.status!= UMSOCKET_STATUS_IS)
        {
    #if defined(ULIBSCTP_CONFIG_DEBUG)
            if(self.logLevel <= UMLOG_DEBUG)
            {
                [self logDebug:[NSString stringWithFormat:@"force change status to IS"]];
            }
    #endif
#if defined(POWER_DEBUG)
            NSLog(@"%@ receiving data: force change status to IS",_layerName);
#endif
            [self setStatus:UMSOCKET_STATUS_IS reason:@"sctpReceiveData"];
            [self reportStatusWithReason:@"sctpReceiveData"];
        }

        NSArray *usrs = [_users arrayCopy];
        for(UMLayerSctpUser *u in usrs)
        {
            if( [u.profile wantsProtocolId:protocolId]
               || [u.profile wantsStreamId:streamId])
            {
    #if defined(ULIBSCTP_CONFIG_DEBUG)
                if(self.logLevel <= UMLOG_DEBUG)
                {
                    [self logDebug:[NSString stringWithFormat:@"passing data '%@' to USER[%@]",data.description,u.user.layerName]];
                }
    #endif
                [u.user sctpDataIndication:self
                                    userId:u.userId
                                  streamId:streamId.unsignedShortValue
                                protocolId:protocolId.unsignedIntValue
                                      data:data
                                    socket:socketNumber];
            }
            if([u.profile wantsMonitor])
            {
                [u.user sctpMonitorIndication:self
                                       userId:u.userId
                                     streamId:streamId.unsignedShortValue
                                   protocolId:protocolId.unsignedIntValue
                                         data:data
                                     incoming:YES
                                       socket:socketNumber];
            }
        }
        return UMSocketError_no_error;
    }
#endif
}

#pragma mark -
#pragma mark Config Handling
- (void)setConfig:(NSDictionary *)cfg applicationContext:(id<UMLayerSctpApplicationContextProtocol>)appContext
{
    @autoreleasepool
    {

        if(_registry==NULL)
        {
            NSLog(@"Error: configuring a SCTP object which does not have .registry initialized to a global UMSocketSCTPRegistry object");
            exit(0);
        }
        [self readLayerConfig:cfg];
        if(cfg[@"allow-any-remote-port-inbound"])
        {
            _allowAnyRemotePortIncoming = [cfg[@"allow-any-remote-port-inbound"] boolValue];
        }
        else
        {
            _allowAnyRemotePortIncoming = NO;
        }
        if (cfg[@"local-ip"])
        {
            id local_ip_object = cfg[@"local-ip"];
            if([local_ip_object isKindOfClass:[NSString class]])
            {
                NSString *line = (NSString *)local_ip_object;
                self.configured_local_addresses = [line componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t;"]];
            }
            else if([local_ip_object isKindOfClass:[UMSynchronizedArray class]])
            {
                UMSynchronizedArray *ua = (UMSynchronizedArray *)local_ip_object;
                self.configured_local_addresses = [ua.array copy];
            }
            else if([local_ip_object isKindOfClass:[UMSynchronizedArray class]])
            {
                UMSynchronizedArray *arr = (UMSynchronizedArray *)local_ip_object;
                self.configured_local_addresses = [arr arrayCopy];
            }
            else if([local_ip_object isKindOfClass:[NSArray class]])
            {
                NSArray *arr = (NSArray *)local_ip_object;
                self.configured_local_addresses = [arr copy];
            }
        }
        else
        {
            NSLog(@"Warning: no local-ip defined for sctp %@",self.layerName);
        }
        if (cfg[@"local-port"])
        {
            _configured_local_port = [cfg[@"local-port"] intValue];
        }
        if (cfg[@"remote-ip"])
        {
            id remote_ip_object = cfg[@"remote-ip"];
            if([remote_ip_object isKindOfClass:[NSString class]])
            {
                NSString *line = (NSString *)remote_ip_object;
                self.configured_remote_addresses = [line componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" \t;"]];
            }
            else if([remote_ip_object isKindOfClass:[UMSynchronizedArray class]])
            {
                UMSynchronizedArray *ua = (UMSynchronizedArray *)remote_ip_object;
                self.configured_remote_addresses = [ua.array copy];
            }
            else if([remote_ip_object isKindOfClass:[UMSynchronizedArray class]])
            {
                UMSynchronizedArray *arr = (UMSynchronizedArray *)remote_ip_object;
                self.configured_remote_addresses = [arr arrayCopy];
            }
            else if([remote_ip_object isKindOfClass:[NSArray class]])
            {
                NSArray *arr = (NSArray *)remote_ip_object;
                self.configured_remote_addresses = [arr copy];
            }
        }
        if (cfg[@"remote-port"])
        {
            _configured_remote_port = [cfg[@"remote-port"] intValue];
        }
        if (cfg[@"passive"])
        {
            _isPassive = [cfg[@"passive"] boolValue];
        }
        if (cfg[@"heartbeat"])
        {
            _heartbeatSeconds = [cfg[@"heartbeat"] doubleValue];
        }
        if (cfg[@"reconnect-timer"])
        {
            _reconnectTimerValue = [cfg[@"reconnect-timer"] doubleValue];
            _reconnectTimer.seconds = _reconnectTimerValue;
        }

        if ([cfg[@"sctp-over-tcp"] boolValue]==YES)
        {
            _encapsulatedOverTcp = YES;
        }
        if (cfg[@"sctp-over-tcp-session-key"])
        {
            _encapsulatedOverTcpSessionKey = [cfg[@"sctp-over-tcp-session-key"] stringValue];
        }
        if (cfg[@"mtu"])
        {
            _mtu = [cfg[@"mtu"] intValue];
        }
        else
        {
            _mtu = 1416; /* usually safer default  than 1500 due to ipsec */
        }
        if (cfg[@"dscp"])
        {
            _dscp = [cfg[@"dscp"] stringValue];
        }

        if (cfg[@"max-init-timeout"])
        {
            _maxInitTimeout = [cfg[@"max-init-timeout"] intValue];
        }
        else
        {
            _maxInitTimeout = 15; /* we send INIT every 15 sec */
        }
        
        if (cfg[@"use-peeloff"])
        {
            _usePeelOff = [cfg[@"use-peeloff"] boolValue];
        }
        else
        {
             _usePeelOff = YES;
        }
        if (cfg[@"max-init-attempts"])
        {
            _maxInitAttempts = [cfg[@"max-init-attempts"] intValue];
        }
        else
        {
            _maxInitAttempts = 12; /* we try up to 12 titmes (3 minutes at 15sec intervalls) */
        }
        
        if (cfg[@"max-in-streams"])
        {
            _maxInStreams = [cfg[@"max-in-streams"] intValue];
        }
        else
        {
            _maxInStreams = 0;
        }
        
        if (cfg[@"num-of-streams"])
        {
            _numOStreams = [cfg[@"num-of-streams"] intValue];
        }
        else
        {
            _numOStreams = 0;
        }

        if (cfg[@"min-receive-buffer-size"])
        {
            _minReceiveBufferSize = [cfg[@"min-receive-buffer-size"] intValue];
        }
        if (cfg[@"min-send-buffer-size"])
        {
            _minSendBufferSize = [cfg[@"min-send-buffer-size"] intValue];
        }
    #ifdef ULIB_SCTP_DEBUG
        if(_logLevel <=UMLOG_DEBUG)
        {
            NSLog(@"configured_local_addresses=%@",configured_local_addresses);
            NSLog(@"configured_remote_addresses=%@",configured_remote_addresses);
        }
    #endif
    }
}

- (NSDictionary *)config
{
    @autoreleasepool
    {
        NSMutableDictionary *config = [[NSMutableDictionary alloc]init];
        [self addLayerConfig:config];
        config[@"local-ip"] = [_configured_local_addresses componentsJoinedByString:@" "];
        config[@"local-port"] = @(_configured_local_port);
        config[@"remote-ip"] = [_configured_remote_addresses componentsJoinedByString:@" "];
        config[@"remote-port"] = @(_configured_remote_port);
        config[@"passive"] = _isPassive ? @YES : @ NO;
        config[@"heartbeat"] = @(_heartbeatSeconds);
        config[@"reconnect-timer"] = @(_reconnectTimerValue);
        config[@"mtu"] = @(_mtu);
        if(_dscp)
        {
            config[@"dscp"] = _dscp;
        }
        config[@"max-init-timeout"] = @(_maxInitTimeout);
        config[@"max-init-attempts"] = @ (_maxInitAttempts);
        config[@"max-in-streams"] = @(_maxInStreams);
        config[@"num-of-streams"] = @ (_numOStreams);
        config[@"sctp-over-tcp"] = @(_encapsulatedOverTcp);
        return config;
    }
}

- (NSDictionary *)apiStatus
{
    @autoreleasepool
    {
        NSMutableDictionary *d = [[NSMutableDictionary alloc]init];
        switch(self.status)
        {
            case UMSOCKET_STATUS_FOOS:
                d[@"status"] = @"M-FOOS";
                break;
            case UMSOCKET_STATUS_OFF:
                d[@"status"] = @"OFF";
                break;
            case UMSOCKET_STATUS_OOS:
                d[@"status"] = @"OOS";
                break;
            case UMSOCKET_STATUS_IS:
                d[@"status"] = @"IS";
                break;
            default:
                d[@"status"] = [NSString stringWithFormat:@"unknown(%d)",self.status];
                break;
        }
        d[@"name"] = self.layerName;
        
        d[@"configured-local-port"] = @(_configured_local_port);
        d[@"configured-remote-port"] = @(_configured_remote_port);
        d[@"active-local-port"] = @(_active_local_port);
        d[@"active-remote-port"] = @(_active_remote_port);

        if(_configured_local_addresses.count > 0)
        {
            d[@"configured-local-addresses"] = [_configured_local_addresses copy];
        }
        if(_configured_remote_addresses.count>0)
        {
            d[@"configured-remote-addresses"] = [_configured_remote_addresses copy];
        }
        if(_active_local_addresses.count)
        {
            d[@"active-local-addresses"] = [_active_local_addresses copy];
        }
        if(_active_remote_addresses.count)
        {
            d[@"active-remote-addresses"] = [_active_remote_addresses copy];
        }
        d[@"is-passive"] = _isPassive ? @(YES) : @(NO);
        d[@"poll-timeout-in-ms"] = @(_timeoutInMs);
        d[@"heartbeat"] = @(_heartbeatSeconds);
        d[@"mtu"] = @(_mtu);
        if(_dscp)
        {
            d[@"dscp"] = _dscp;
        }
        return d;
    }
}

- (void)stopDetachAndDestroy
{
    /* FIXME: do something here */
}

- (NSString *)statusString
{
    return [UMSocket statusDescription:self.status];
}

-(void)dealloc
{
    if(_listenerStarted==YES)
    {
        
        [_listener stopListeningFor:self];
    }
    _listener = NULL;
}

- (void)reconnectTimerFires
{
    
    @autoreleasepool
    {
        [self addToLayerHistoryLog:@"reconnectTimerFires"];
        [self openFor:NULL sendAbortFirst:NO reason:@"reconnect-timer-fires"];
        
#if 0
    #if defined(ULIBSCTP_CONFIG_DEBUG)
        if(self.logLevel <= UMLOG_DEBUG)
        {
            [self logDebug:@"reconnectTimerFires"];
        }
    #endif
        [_reconnectTimer stop];
        if(_isPassive)
        {
            [_listener startListeningFor:self];
            usleep(150000); /* lets give the system a chance to update "isListening */
            _listenerStarted = _listener.isListening;
        }
        else
        {
            if(self.status != UMSOCKET_STATUS_IS)
            {
                NSNumber *xassocId = NULL;
                [_listener connectToAddresses:_configured_remote_addresses
                                         port:_configured_remote_port
                                     assocPtr:&xassocId
                                        layer:self];
                if(xassocId != NULL)
                {
                    _assocId = xassocId;
                    UMSocketError e = UMSocketError_no_error;
                    UMSocketSCTP *direct = [_listener peelOffAssoc:_assocId error:&e];
                    if((e==UMSocketError_no_error) && (direct))
                    {
                        _directSocket = direct;
                    }
                }
                [_listener registerAssoc:_assocId forLayer:self];
            }
        }
#endif
    }
}

- (void)processError:(UMSocketError)err socket:(UMSocket *)socket inArea:(NSString *)area
{
    if(err==UMSocketError_no_data)
    {
       return;
    }
    if(err==UMSocketError_no_error)
    {
        return;
    }
    @autoreleasepool
    {
        if(_logLevel <=UMLOG_MINOR)
        {
            NSLog(@"processError %d %@ received in UMLayerSctp %@",err, [UMSocket getSocketErrorString:err], _layerName);
        }
#if defined(POWER_DEBUG)
            NSLog(@"%@ processError: %d %@",_layerName,err, [UMSocket getSocketErrorString:err]);
#endif
        if(err==UMSocketError_invalid_file_descriptor)
        {
            if(_directSocket == socket)
            {
                _directSocket = NULL;
                NSString *s = [NSString stringWithFormat:@"processError *IGNORED* (%d,%@) fd=%d inArea %@",err,[UMSocket getSocketErrorString:err],_directSocket.sock,area];
                [_layerHistory addLogEntry:s];
                [self reportStatusWithReason:s];
            }
            else
            {
                NSString *s = [NSString stringWithFormat:@"got error UMSocketError_invalid_file_descriptor on socket %p (%d) but _directSocket is %p (%d). Ignoring",socket,socket.sock,_directSocket,_directSocket.sock];
                [_layerHistory addLogEntry:s];
            }
        }
        else
        {
            [self powerdown:[NSString stringWithFormat:@"processError (%d,%@) fd=%d inArea %@",err,[UMSocket getSocketErrorString:err],_directSocket.sock,area]];
        }
    }
}

- (void)processHangup
{
    @autoreleasepool
    {
        if(_logLevel <=UMLOG_DEBUG)
        {
            NSLog(@"processHangup received in UMLayerSctp %@",_layerName);
        }
#if defined(POWER_DEBUG)
            NSLog(@"%@ processHangup",_layerName);
#endif
        [self powerdown:@"processHangup"];
        [self reportStatusWithReason:@"processHangup"];
    }
}

- (ssize_t) sendEncapsulated:(NSData *)data
                       assoc:(NSNumber *)assoc
                     stream:(NSNumber *)streamId
                   protocol:(NSNumber *)protocolId
                      error:(UMSocketError *)err2
                       flags:(int)flags
{
    UMSocketError err = UMSocketError_no_error;

    sctp_over_tcp_header header;
    memset(&header,0,sizeof(header));
    header.header_length = htonl(sizeof(header));
    header.payload_length = htonl(data.length);
    header.protocolId = htonl(protocolId.unsignedLongValue);
    header.streamId = htons(streamId.unsignedShortValue);
    header.flags = htons(flags);

    
    NSMutableData *data2 = [[NSMutableData alloc]initWithBytes:&header length:sizeof(header)];
    if(data)
    {
        [data2 appendData:data];
    }
    err = [_directTcpEncapsulatedSocket sendData:data2];
    
    if(err2)
    {
        *err2 = err;
    }
    if(err == UMSocketError_no_error)
    {
        return data2.length;
    }
    return -1;
}

- (BOOL)isPathMtuDiscoveryEnabled
{
    return _directSocket.isPathMtuDiscoveryEnabled;
}

- (int)currentMtu
{
    return _directSocket.currentMtu;
}

- (UMSynchronizedSortedDictionary *)sctpStatusDict
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    
    dict[@"name"] = self.layerName;
    dict[@"listener"] = _listener.name;
    if(_directSocket)
    {
        dict[@"direct-socket"] = [_directSocket description];
    }
    else
    {
        dict[@"direct-socket"] = @"(null)";
    }
    dict[@"configured-local-port"] = @(_configured_local_port);
    dict[@"configured-remote-port"] = @(_configured_remote_port);
    dict[@"active-local-port"] = @(_active_local_port);
    dict[@"active-remote-port"] = @(_active_remote_port);

    if(_configured_local_addresses)
    {
        dict[@"configured-local-addresses"] = _configured_local_addresses;
    }
    if(_configured_remote_addresses)
    {
        dict[@"configured-remote-addresses"] = _configured_remote_addresses;
    }
    if(_active_local_addresses)
    {
        dict[@"active-local-addresses"] = _active_local_addresses;
    }
    if(_active_remote_addresses)
    {
        dict[@"active-remote-addresses"] = _active_remote_addresses;
    }
    if(_reconnectTimer)
    {
        dict[@"reconnect-timer"] = [_reconnectTimer timerDescription];
    }
    dict[@"reconnect-timer-value"] = @(_reconnectTimerValue);
    dict[@"heartbeat-seconds"] = @(_heartbeatSeconds);

    dict[@"poll-timeout"] = @(_timeoutInMs/1000.0);
    dict[@"passive"] = @(_isPassive);
    if(_dscp)
    {
        dict[@"dscp"] = _dscp;
    }
    dict[@"listener-started"] = @(_listenerStarted);
    dict[@"is-invalid"] = @(_isInvalid);
    dict[@"new-Destination"] = @(_newDestination);
    dict[@"max-init-timeout"] = @(_maxInitTimeout);
    dict[@"max-init-attempts"] = @(_maxInitAttempts);

    switch(self.status)
    {
        case UMSOCKET_STATUS_FOOS:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_FOOS";
            break;
        case UMSOCKET_STATUS_OFF:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_OFF";
            break;
        case UMSOCKET_STATUS_OOS:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_OOS";
            break;
        case UMSOCKET_STATUS_IS:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_IS";
            break;
        case UMSOCKET_STATUS_LISTENING:
            dict[@"sctp-socket-status"] = @"UMSOCKET_STATUS_LISTENING";
            break;
    }
    dict[@"encapsualted-over-tcp"] = @(_encapsulatedOverTcp);
    if(_encapsulatedOverTcpSessionKey)
    {
        dict[@"encapsualted-over-tcp-session-key"] = _encapsulatedOverTcpSessionKey;
    }
    dict[@"min-receive-buffer-size"] = @(_minReceiveBufferSize);
    dict[@"min-send-buffer-size"] = @(_minSendBufferSize);
    
    NSMutableArray *a = [[NSMutableArray alloc]init];
    for(UMLayerSctpUser *u in _users)
    {
        UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
        dict[@"name"] = u.user.layerName;
        [a addObject:dict];
    }
    dict[@"users"] = a;
    dict[@"last-events"] = [_layerHistory getLogArrayWithDatesAndOrder:YES];
    return dict;
}


-(void)setStatus:(UMSocketStatus)s reason:(NSString *)reason
{
    UMSocketStatus oldStatus = _status;
    _status = s;
    if(oldStatus != _status)
    {
        [self reportStatusWithReason:reason];
        [self addToLayerHistoryLog:[NSString stringWithFormat:@"status change from %@ to %@ because of %@",
                        [UMLayerSctp socketStatusString:oldStatus],
                        [UMLayerSctp socketStatusString:s],reason ] ];
    }
}

-(UMSocketStatus)status
{
    return _status;
}

+(NSString *)socketStatusString:(UMSocketStatus)s
{
    switch(s)
    {
        case UMSOCKET_STATUS_FOOS:
            return @"M-FOOS";
        case UMSOCKET_STATUS_OFF:
            return  @"OFF";
        case UMSOCKET_STATUS_OOS:
            return @"OOS";
            break;
        case UMSOCKET_STATUS_IS:
            return @"IS";
        default:
            return @"(bogous)";
            break;
    }
}

/* this starts a separate background task on the peeled off directSocket to receive packets */
- (void)startDirectSocketReceiver
{
    if(_directSocket==NULL)
    {
        NSString *s = [NSString stringWithFormat:@"can not start receiver on socket NULL for assoc %@",_assocId];
        [_layerHistory addLogEntry:s];
        NSLog(@"%@",s);
        return;
    }

    NSString *name = [NSString stringWithFormat:@"RX:%@",_layerName];
    _directReceiver = [[UMSCTPListener alloc]initWithName:name
                                             socket:_directSocket
                                      eventDelegate:(id<UMSCTPListenerProcessEventsDelegate>)self
                                       readDelegate:(id<UMSCTPListenerReadPacketDelegate>)self
                                    processDelegate:(id<UMSCTPListenerProcessDataDelegate>)self];
    _directReceiver.logFeed = self.logFeed;
    _directReceiver.logLevel = self.logLevel;

    NSString *s = [NSString stringWithFormat:@"starting receiver on socket %p/%d assoc %@",_directSocket,_directSocket.sock,_assocId];
    [_layerHistory addLogEntry:s];
    NSLog(@"%@",s);
    [_directReceiver startBackgroundTask];
}

- (UMSocketSCTPReceivedPacket *)receiveSCTP
{
    UMSocketSCTPReceivedPacket *rx = [_directSocket receiveSCTP];
    return rx;
}

- (void)processError:(UMSocketError)err
{
    return [self processError:err socket:_directSocket inArea:@"directSocketReceiver"];
}

@end
