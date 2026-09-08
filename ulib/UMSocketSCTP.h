//
//  UMSocketSCTP.h
//  ulib
//
//  Created by Andreas Fink on 14.05.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/ulib.h>
#import <ulib/UMLayerSctpUserProtocol.h>
#import <ulib/UMLayerSctpApplicationContextProtocol.h>
#import <ulib/UMSocketSCTPReceivedPacket.h>

@class UMSocketSCTPListener2;

struct sctp_sndrcvinfo;


typedef enum SCTP_SocketType_enum
{
    SCTP_SOCKET_TYPE_LISTENER_SCTP  = 0,
    SCTP_SOCKET_TYPE_LISTENER_TCP   = 1,
    SCTP_SOCKET_TYPE_OUTBOUND       = 2,
    SCTP_SOCKET_TYPE_INBOUND        = 3,
    SCTP_SOCKET_TYPE_OUTBOUND_TCP   = 4,
    SCTP_SOCKET_TYPE_INBOUND_TCP    = 5,
} SCTP_SocketType_enum;

@protocol UMSocketSCTP_notificationDelegate
- (UMSocketError) handleEvent:(NSData *)data
                        sinfo:(struct sctp_sndrcvinfo *)sinfo;
@end

@protocol UMSocketSCTP_dataDelegate
- (UMSocketError) sctpReceivedData:(NSData *)data
                          streamId:(NSNumber *)streamId
                        protocolId:(NSNumber *)protocolId
                            socket:(NSNumber *)socketNumber;
@end


    
@interface UMSocketSCTP : UMSocket
{
    NSArray         *_requestedLocalAddresses;
    NSArray         *_useableLocalAddresses;
    NSArray         *_connectedLocalAddresses;
    NSArray         *_requestedRemoteAddresses;
    NSArray         *_connectedRemoteAddresses;
    int             _msg_notification_mask;
    double          _heartbeatSeconds;
    NSTimeInterval  _connectionRepeatTimer;
    UMSocketSCTPListener2 *_listener;
    BOOL            _continuousConnectionAttempts;
    BOOL            _connectx_pending;
    NSData          *_localAddressesSockaddr;
    int             _localAddressesSockaddrCount;
    int             _maxSeg;
    int             _maxInStreams;
    int             _numOStreams;
    int             _maxInitAttempts;
    int             _initTimeout;
	NSNumber		*_xassoc;
    BOOL            _pathMtuDiscovery;
}

@property(readwrite,strong) NSArray        *requestedLocalAddresses;
@property(readwrite,strong) NSArray        *connectedLocalAddresses;
@property(readwrite,strong) NSArray        *requestedRemoteAddresses;
@property(readwrite,strong) NSArray        *connectedRemoteAddresses;
@property(readwrite,assign) int            msg_notification_mask;
@property(readwrite,assign) double            heartbeatSeconds;
@property(readwrite,strong) id<UMSocketSCTP_notificationDelegate>   notificationDelegate;
@property(readwrite,strong) id<UMSocketSCTP_dataDelegate>           dataDelegate;
@property(readwrite,assign) BOOL            continuousConnectionAttempts;
@property(readwrite,assign) NSTimeInterval  connectionRepeatTimer;
@property(readwrite,assign) int maxInStreams;
@property(readwrite,assign) int numOStreams;
@property(readwrite,assign) int maxInitAttempts;
@property(readwrite,assign) int initTimeout;

@property(readwrite,strong)	NSNumber		*xassoc;


- (int)maxSegment;
- (void)setMaxSegment:(int)newMaxSeg;

- (UMSocketError) bind;
- (UMSocketError) enableEvents;
- (UMSocketError) enableFutureAssoc;

- (UMSocketSCTP *) acceptSCTP:(UMSocketError *)ret;
- (UMSocketSCTP *) peelOffAssoc:(NSNumber *)assoc
						  error:(UMSocketError *)errptr
                    errorNumber:(int *)e;

- (UMSocketError) connect;
- (UMSocketError) connectAssocPtr:(NSNumber **)assoc;
- (UMSocketError) connectToAddresses:(NSArray *)addrs
                                port:(int)remotePort
                            assocPtr:(NSNumber **)assoc
                               layer:(UMLayer *)layer;



+ (NSData *)sockaddrFromAddresses:(NSArray *)theAddrs
                             port:(int)thePort
                            count:(int *)count_out /* returns struct sockaddr data in NSData */
                     socketFamily:(int)socketFamily;

- (ssize_t) sendToAddresses:(NSArray *)addrs
                       port:(int)port
                   assocPtr:(NSNumber **)assoc
                       data:(NSData *)data
                     stream:(NSNumber *)streamId
                   protocol:(NSNumber *)protocolId
                      error:(UMSocketError *)err2;



- (UMSocketError) abortToAddress:(NSString *)addr
                            port:(int)remotePort
                           assoc:(NSNumber *)assoc
                          stream:(NSNumber *)streamId
                        protocol:(NSNumber *)protocolId;

/*
- (ssize_t)sendSCTP:(NSData *)data
             stream:(NSNumber *)streamId
           protocol:(NSNumber *)protocolId
              error:(UMSocketError *)err;
 */
- (UMSocketSCTPReceivedPacket *)receiveSCTP;

- (UMSocketError) dataIsAvailableSCTP:(int)timeoutInMs
                            dataAvail:(int *)hasData
                               hangup:(int *)hasHup;
- (UMSocketError) getSocketError;
- (UMSocketError) setReusePort;
- (UMSocketError) setNoDelay;
- (UMSocketError) setInitParams;

- (void)setMtu:(int)newMtu;
- (UMSocketError)configureMtu:(int)newMtu;
- (UMSocketError)updateMtu:(int)newMtu;
- (UMSocketError)setHeartbeat:(BOOL)enable;
- (NSArray *)getRemoteIpAddressesForAssoc:(uint32_t)assoc;
- (int)bindx:(struct sockaddr *)localAddress;

- (int) currentMtu;
- (BOOL) isPathMtuDiscoveryEnabled;
- (UMSocketError)setPathMtuDiscovery:(BOOL)enable;


@end
#endif
