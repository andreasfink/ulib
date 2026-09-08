//
//  UMSCTPListener.h
//  ulib
//
//  Created by Andreas Fink on 23.08.22.
//  Copyright © 2022 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMBackgrounder.h>
#import <ulib/UMLogLevel.h>
#import <ulib/UMSynchronizedDictionary.h>
#import <ulib/UMSocket.h>
#import <ulib/UMLayer.h>
#import <ulib/UMLayerSctp.h>

@class UMSocketSCTPReceivedPacket;
@class UMSocketSCTP;

@protocol UMSCTPListenerProcessEventsDelegate
- (void) processError:(UMSocketError)err;
- (void) processHangup;
@end

@protocol UMSCTPListenerProcessDataDelegate
- (void) processReceivedData:(UMSocketSCTPReceivedPacket *)rx;
@end

@protocol UMSCTPListenerReadPacketDelegate
- (UMSocketSCTPReceivedPacket *)receiveSCTP;
@end

/*
 * UMSCTPListener is a background thread which sits on a socket and reads packets from it with the help of the read delegate
 * then it passes the packets to the data delegate. If errors or state changes occur, the event delegate is called.
 * It terminates if the socket receives a hangup or if an error condition forces the delegate to send a terminate command.
 *
 */

@class UMLayerSctp;
@class UMSocketSCTP;

@interface UMSCTPListener : UMBackgrounder
{
    UMLayerSctp                                 *_layer;
    UMLogLevel                                  _logLevel;
    UMSocketSCTP                                *_umsocket;
    id<UMSCTPListenerProcessEventsDelegate>     _eventDelegate;
    id<UMSCTPListenerReadPacketDelegate>        _readDelegate;
    id<UMSCTPListenerProcessDataDelegate>       _processDelegate;
    int                                         _timeoutInMs;
    UMSynchronizedDictionary                    *_assocs;
}

@property(readwrite,strong,atomic)  UMLayer                                    *layer;
@property(readwrite,assign,atomic) UMLogLevel logLevel;
@property(readwrite,strong,atomic)  UMSocketSCTP                               *umsocket;
@property(readwrite,strong,atomic)  id<UMSCTPListenerProcessEventsDelegate>    eventDelegate;
@property(readwrite,strong,atomic)  id<UMSCTPListenerReadPacketDelegate>       readDelegate;
@property(readwrite,strong,atomic)  id<UMSCTPListenerProcessDataDelegate>      processDelegate;

- (UMSCTPListener *)initWithName:(NSString *)name
                          socket:(UMSocketSCTP *)sock
                   eventDelegate:(id<UMSCTPListenerProcessEventsDelegate>)evDel
                    readDelegate:(id<UMSCTPListenerReadPacketDelegate>)readDel
                 processDelegate:(id<UMSCTPListenerProcessDataDelegate>)procDel;


@end

