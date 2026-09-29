//
//  UMSocketSCTPRegistry.h
//  ulib
//
//  Created by Andreas Fink on 17.05.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMObject.h>
#import <ulib/UMLogLevel.h>
#import <ulib/UMSynchronizedSortedDictionary.h>

@class UMSocketSCTPListener2;
@class UMLayerSctp;


@interface UMSocketSCTPRegistry : UMObject
{
    NSMutableDictionary     *_entries;

    NSMutableArray                                           *_outgoingLayers;
    NSMutableArray<UMSocketSCTPListener2 *>                   *_incomingListeners;
    NSMutableDictionary<NSNumber *,UMSocketSCTPListener2 *>   *_incomingTcpListeners; /* key is @(port) */
    NSMutableArray          *_incomingLayers; /* once peeled of the listener */
    NSMutableArray          *_outgoingTcpLayers;
    NSMutableArray          *_incomingTcpLayers;
    NSMutableDictionary     *_outgoingLayersByIpsAndPorts;
    NSMutableDictionary     *_outgoingLayersByAssoc;
    UMMutex                 *_registryLock;
    BOOL                    _sendAborts;
    UMLogLevel              _logLevel;
    NSMutableDictionary     *_layersBySessionKey;
}

@property (readwrite,assign,atomic)   UMLogLevel logLevel;
@property (readwrite,assign,atomic)   BOOL sendAborts;


- (NSString *)webStat;

+ (NSString *)keyForPort:(int)port ip:(NSString *)ip;



- (UMSocketSCTPListener2 *)getOrAddListenerForPort:(int)port localIps:(NSArray<NSString *> *)ips;
- (UMSocketSCTPListener2 *)getOrAddListenerForPort:(int)port
                                          localIps:(NSArray<NSString *> *)ips
                                      maxInStreams:(int)maxInStreams
                                       numOStreams:(int)numOStreams
                                   maxInitAttempts:(int)maxInitAttempts
                                       initTimeout:(int)initTimeout;

- (UMSocketSCTPListener2 *)getListenerForPort:(int)port localIp:(NSString *)ip;
- (UMSocketSCTPListener2 *)getListenerForPort:(int)port localIps:(NSArray *)ips;
- (void)addListener:(UMSocketSCTPListener2 *)listener;
- (void)addListener:(UMSocketSCTPListener2 *)listener forPort:(int)port localIp:(NSString *)ip;
- (void)removeListener:(UMSocketSCTPListener2 *)listener;
- (void)removeListener:(UMSocketSCTPListener2 *)listener forPort:(int)port localIp:(NSString *)ips;
- (UMSocketSCTPListener2 *)getOrAddTcpListenerForPort:(int)port;
- (UMSocketSCTPListener2 *)getTcpListenerForPort:(int)port;
- (void)addTcpListener:(UMSocketSCTPListener2 *)listener;
- (void)removeTcpListener:(UMSocketSCTPListener2 *)listener;



- (void)registerSessionKey:(NSString *)session_key forLayer:(UMLayerSctp *)layer;
- (void)unregisterSessionKey:(NSString *)session_key;


- (UMLayerSctp *)layerForSessionKey:(NSString *)sessionKey;

- (void)registerOutgoingLayer:(UMLayerSctp *)layer;
- (void)registerOutgoingTcpLayer:(UMLayerSctp *)layer;
- (void)unregisterOutgoingTcpLayer:(UMLayerSctp *)layer;
- (void)registerOutgoingLayer:(UMLayerSctp *)layer allowAnyRemotePortIncoming:(BOOL)anyPort;

- (void)registerIncomingLayer:(UMLayerSctp *)layer;
- (void)registerIncomingTcpLayer:(UMLayerSctp *)layer;
- (void)unregisterIncomingTcpLayer:(UMLayerSctp *)layer;

- (void)unregisterLayer:(UMLayerSctp *)sctp;
- (UMLayerSctp *)layerForLocalIp:(NSString *)ip1
                       localPort:(int)port1
                        remoteIp:(NSString *)ip2
                      remotePort:(int)port2
                    encapsulated:(BOOL)encap;

- (NSArray *)allListeners;
- (NSArray *)allTcpListeners;
- (NSArray *)allOutboundLayers;
- (NSArray *)allInboundLayers;

- (NSArray *)allOutboundTcpLayers;
- (NSArray *)allInboundTcpLayers;

+ (NSString *)registryKeyForLocalAddr:(NSString *)lo
                            localPort:(int)lp
                           remoteAddr:(NSString *)ra
                           remotePort:(int)rp
                         encapsulated:(BOOL)encap;

- (UMSynchronizedSortedDictionary *)descriptionDict;
@end
