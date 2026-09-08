//
//  UMSocketSCTPRegistry.m
//  ulibsctp
//
//  Created by Andreas Fink on 17.05.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMSocketSCTPRegistry.h>
#import <ulib/UMSocketSCTPListener2.h>
#import <ulib/UMLayerSctp.h>

@implementation UMSocketSCTPRegistry

- (UMSocketSCTPRegistry *)init
{
    self = [super init];
    if(self)
    {
        _entries = [[NSMutableDictionary alloc]init];
        _registryLock = [[UMMutex alloc]initWithName:@"umsocket-sctp-registry"];
        _outgoingLayers = [[NSMutableArray alloc]init];
        _incomingLayers = [[NSMutableArray alloc]init];
        _outgoingTcpLayers = [[NSMutableArray alloc]init];
        _incomingTcpLayers = [[NSMutableArray alloc]init];
        _incomingListeners = [[NSMutableArray alloc]init];
        _incomingTcpListeners = [[NSMutableDictionary alloc] init];
        _outgoingLayersByIpsAndPorts = [[NSMutableDictionary alloc]init];
        _layersBySessionKey = [[NSMutableDictionary alloc]init];
        _logLevel = UMLOG_MINOR;

    }
    return self;
}

- (NSArray *)allListeners
{
    NSArray *a = NULL;
    ummutex_lock(_registryLock);
    a = [_incomingListeners copy];
    ummutex_unlock(_registryLock);
    return a;
}

- (NSArray *)allTcpListeners
{
    ummutex_lock(_registryLock);
    NSMutableDictionary *dict =  [_incomingTcpListeners copy];
    NSMutableArray *a = [[NSMutableArray alloc]init];
    for(id k in dict.allKeys)
    {
        [a addObject:dict[k]];
    }
    ummutex_unlock(_registryLock);
    return a;
}


- (NSArray *)allOutboundLayers
{
    ummutex_lock(_registryLock);
    NSArray *a = [_outgoingLayers copy];
    ummutex_unlock(_registryLock);
    return a;
}

- (NSArray *)allInboundLayers
{
    ummutex_lock(_registryLock);
    NSArray *a = [_incomingLayers copy];
    ummutex_unlock(_registryLock);
    return a;
}

- (NSArray *)allOutboundTcpLayers
{
    ummutex_lock(_registryLock);
    NSArray *a = [_outgoingTcpLayers copy];
    ummutex_unlock(_registryLock);
    return a;
}

- (NSArray *)allInboundTcpLayers
{
    ummutex_lock(_registryLock);
    NSArray *a = [_incomingTcpLayers copy];
    ummutex_unlock(_registryLock);
    return a;
}


+ (NSString *)keyForPort:(int)port ip:(NSString *)addr
{
    return [NSString stringWithFormat:@"%d,%@",port,addr];
}


- (UMSocketSCTPListener2 *)getOrAddListenerForPort:(int)port
                                          localIps:(NSArray<NSString *> *)ips
{
    return [self getOrAddListenerForPort:port
                                localIps:ips
                            maxInStreams:0
                             numOStreams:0
                         maxInitAttempts:0
                             initTimeout:0];
}

- (UMSocketSCTPListener2 *)getOrAddListenerForPort:(int)port
                                          localIps:(NSArray<NSString *> *)ips
                                      maxInStreams:(int)maxInStreams
                                       numOStreams:(int)numOStreams
                                   maxInitAttempts:(int)maxInitAttempts
                                       initTimeout:(int)initTimeout
{
    UMSocketSCTPListener2 *listener = NULL;
    ummutex_lock(_registryLock);
    @try
    {
        listener = [self getListenerForPort:port localIps:ips];
        if(listener == NULL)
        {
            listener = [[UMSocketSCTPListener2 alloc]initWithPort:port localIpAddresses:ips];
            listener.logLevel = _logLevel;
            listener.sendAborts = _sendAborts;
            listener.maxInStreams = maxInStreams;
            listener.numOStreams = numOStreams;
            listener.maxInitAttempts = maxInitAttempts;
            listener.initTimeout = initTimeout;
            [self addListener:listener];
            NSLog(@"getOrAddListenerForPort returns new listener %@",listener.name);
        }
    }
    @catch(NSException *e)
    {
        [self handleException:e];
    }
    @finally
    {
        ummutex_unlock(_registryLock);
    }
    return listener;
}

- (UMSocketSCTPListener2 *)getListenerForPort:(int)port localIps:(NSArray<NSString *> *)ips
{
    NSArray *ips2 = [ips sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *s = [ips2 componentsJoinedByString:@","];
    return [self getListenerForPort:port localIp:s];
}


- (UMSocketSCTPListener2 *)getListenerForPort:(int)port localIp:(NSString *)ip
{
    ummutex_lock(_registryLock);
    NSString *key =[UMSocketSCTPRegistry keyForPort:port ip:ip];
    UMSocketSCTPListener2 *e = _entries[key];
    ummutex_unlock(_registryLock);
    return e;
}

- (void)addListener:(UMSocketSCTPListener2 *)listener
{
    for(NSString *ip in listener.localIpAddresses)
    {
        [self addListener:listener forPort:listener.port localIp:ip];
    }
    NSArray *ips2 = [listener.localIpAddresses sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *s = [ips2 componentsJoinedByString:@","];
    [self addListener:listener forPort:listener.port localIp:s];
}


- (void)addListener:(UMSocketSCTPListener2 *)listener forPort:(int)port localIp:(NSString *)ip
{
    if(listener.tcpEncapsulated)
    {
        [self addTcpListener:listener];
        return;
    }

    ummutex_lock(_registryLock);
    listener.registry = self;
    NSString *key =[UMSocketSCTPRegistry keyForPort:port ip:ip];
    _entries[key]=listener;
    [_incomingListeners removeObject:listener]; /* has to be added only once */
    [_incomingListeners addObject:listener];
    ummutex_unlock(_registryLock);
}


- (void)removeListener:(UMSocketSCTPListener2 *)listener
{
    for(NSString *ip in listener.localIpAddresses)
    {
        [self removeListener:listener forPort:listener.port localIp:ip];
    }
    NSArray *ips2 = [listener.localIpAddresses sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *s = [ips2 componentsJoinedByString:@","];
    [self removeListener:listener forPort:listener.port localIp:s];
}

- (void)removeListener:(UMSocketSCTPListener2 *)listener forPort:(int)port localIp:(NSString *)ip
{
    ummutex_lock(_registryLock);
    listener.registry = NULL;
    NSString *key =[UMSocketSCTPRegistry keyForPort:port ip:ip];
    [_entries removeObjectForKey:key];
    [_incomingListeners removeObject:listener];
    ummutex_unlock(_registryLock);
}


- (UMSocketSCTPListener2 *)getOrAddTcpListenerForPort:(int)port
{
    UMSocketSCTPListener2 *listener  = NULL;
    ummutex_lock(_registryLock);
    @try
    {
        listener = [self getTcpListenerForPort:port];
        if(listener == NULL)
        {
            listener = [[UMSocketSCTPListener2 alloc]initWithPort:port
                                                 localIpAddresses:NULL];
            [self addTcpListener:listener];
        }
    }
    @catch(NSException *e)
    {
        [self handleException:e];
    }
    @finally
    {
        ummutex_unlock(_registryLock);
    }
    return listener;
}

- (UMSocketSCTPListener2 *)getTcpListenerForPort:(int)port
{
    ummutex_lock(_registryLock);
    UMSocketSCTPListener2 *e =  _incomingTcpListeners[@(port)];
    ummutex_unlock(_registryLock);
    return e;
}

- (void)addTcpListener:(UMSocketSCTPListener2 *)listener
{
    ummutex_lock(_registryLock);
    listener.registry = self;
    _incomingTcpListeners[@(listener.port)] = listener;
    ummutex_unlock(_registryLock);
}

- (void)removeTcpListener:(UMSocketSCTPListener2 *)listener
{
    ummutex_lock(_registryLock);
    listener.registry = NULL;
    [_incomingTcpListeners removeObjectForKey:@(listener.port)];
    ummutex_unlock(_registryLock);
}

- (UMSynchronizedSortedDictionary *)descriptionDict;
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];

    NSMutableArray *a1 = [[NSMutableArray alloc]init];
    
    NSArray *arr = _entries.allKeys;
    for(NSString *key in arr)
    {
        [a1 addObject:key];
    }

    dict[@"entries"] = @{ @"count"   : @(arr.count),
                          @"entries" : a1,
                        };

    arr = _outgoingLayers;
    a1 = [[NSMutableArray alloc]init];
    for(UMLayerSctp *layer in _outgoingLayers)
    {
        [a1 addObject:layer.layerName];
    }
    dict[@"outgoing-layers"] = @{ @"count"   : @(a1.count),
                                  @"names" : a1,
                                };

    
    a1 = [[NSMutableArray alloc]init];
    for(UMSocketSCTPListener2 *listener in _incomingListeners)
    {
        [a1 addObject:listener.name];
    }
    dict[@"incoming-listeners"] = @{ @"count"   : @(a1.count),
                                  @"names" : a1,
                                };

    a1 = [[NSMutableArray alloc]init];
    arr = _outgoingLayersByIpsAndPorts.allKeys;
    for(NSString *key in arr)
    {
        [a1 addObject:key];
    }
    
    
    dict[@"outgoing-layers-by-ips-and-ports"] = @{ @"count"   : @(a1.count),
                                                   @"entries" : a1,
                                                };

    return dict;
}

- (NSString *)description
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"-----------------------------------------------------------\n"];
    [s appendFormat:@"UMSocketSCTPRegistry %p\n",self];
    NSArray *arr = _entries.allKeys;

    [s appendFormat:@".entries: %d entries]\n",(int)arr.count];
    for(NSString *key in arr)
    {
        [s appendFormat:@"  [%@]\n",key];
    }

    [s appendFormat:@".outgoingLayers: %d entries]\n",(int)_outgoingLayers.count];
    for(UMLayerSctp *layer in _outgoingLayers)
    {
        [s appendFormat:@"  [%@]\n",layer.layerName];
    }

    [s appendFormat:@".incomingListeners: %d entries]\n",(int)_incomingListeners.count];
    for(UMSocketSCTPListener2 *listener in _incomingListeners)
    {
        [s appendFormat:@"  [%@]\n",listener.name];
    }

    [s appendFormat:@".outgoingLayersByIpsAndPorts: %d entries]\n",(int)_outgoingLayersByIpsAndPorts.count];
    arr = _outgoingLayersByIpsAndPorts.allKeys;
    for(NSString *key in arr)
    {
        UMLayerSctp *xlayer = _outgoingLayersByIpsAndPorts[key];
        [s appendFormat:@"  [%@] -> %@\n",key,xlayer.layerName];
    }

    [s appendFormat:@"-----------------------------------------------------------\n"];
    return s;
}




- (UMLayerSctp *)layerForLocalIp:(NSString *)ip1
                       localPort:(int)port1
                        remoteIp:(NSString *)ip2
                      remotePort:(int)port2
                    encapsulated:(BOOL)encap
{
    if(_logLevel <=UMLOG_DEBUG)
    {
        NSLog(@"layerForLocalIp:%@ localPort:%d remoteIp:%@ remotePort:%d encapsulated:%@",ip1,port1,ip2,port2,encap ? @"YES": @"NO");
    }
    ummutex_lock(_registryLock);
    NSString *key = [UMSocketSCTPRegistry registryKeyForLocalAddr:ip1
                                                        localPort:port1
                                                       remoteAddr:ip2
                                                       remotePort:port2
                                                     encapsulated:encap];
#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(_logLevel <=UMLOG_DEBUG)
    {
        NSLog(@" key=%@",key);
    }
#endif
    UMLayerSctp *layer = _outgoingLayersByIpsAndPorts[key] ;
    ummutex_unlock(_registryLock);

#if defined(ULIBSCTP_CONFIG_DEBUG)
    if(_logLevel <=UMLOG_DEBUG)
    {
        if(layer==NULL)
        {
            NSLog(@"  known keys: %@",[_outgoingLayersByIpsAndPorts allKeys]);
        }
    }
#endif
    return layer;
}

- (void)registerIncomingLayer:(UMLayerSctp *)layer
{
    if(layer)
    {
        ummutex_lock(_registryLock);
        [_incomingLayers removeObject:layer];
        [_incomingLayers addObject:layer];
        ummutex_unlock(_registryLock);
    }
}

- (void)registerIncomingTcpLayer:(UMLayerSctp *)layer
{
    if(layer)
    {
        ummutex_lock(_registryLock);
        [_incomingTcpLayers removeObject:layer];
        [_incomingTcpLayers addObject:layer];
        if(layer.encapsulatedOverTcpSessionKey)
        {
            [self registerSessionKey:layer.encapsulatedOverTcpSessionKey forLayer:layer];
        }
        ummutex_unlock(_registryLock);
    }
}

- (void)unregisterIncomingTcpLayer:(UMLayerSctp *)layer
{
    if(layer)
    {
        ummutex_lock(_registryLock);
        [_incomingTcpLayers removeObject:layer];
        if(layer.encapsulatedOverTcpSessionKey)
        {
            [self unregisterSessionKey:layer.encapsulatedOverTcpSessionKey];
        }
        ummutex_unlock(_registryLock);
    }
}


- (void)registerOutgoingLayer:(UMLayerSctp *)layer
{
    [self registerOutgoingLayer:layer allowAnyRemotePortIncoming:NO];

}

- (void)registerOutgoingTcpLayer:(UMLayerSctp *)layer
{
    if(layer)
    {
        ummutex_lock(_registryLock);
        [_outgoingTcpLayers removeObject:layer];
        [_outgoingTcpLayers addObject:layer];
        if(layer.encapsulatedOverTcpSessionKey)
        {
            [self registerSessionKey:layer.encapsulatedOverTcpSessionKey forLayer:layer];
        }
        ummutex_unlock(_registryLock);
    }
}

- (void)unregisterOutgoingTcpLayer:(UMLayerSctp *)layer
{
    if(layer)
    {
        ummutex_lock(_registryLock);
        [_outgoingTcpLayers removeObject:layer];
        if(layer.encapsulatedOverTcpSessionKey)
        {
            [self unregisterSessionKey:layer.encapsulatedOverTcpSessionKey];
        }
        ummutex_unlock(_registryLock);
    }
}

- (void)registerOutgoingLayer:(UMLayerSctp *)layer allowAnyRemotePortIncoming:(BOOL)anyPort
{
    if(layer)
    {
        ummutex_lock(_registryLock);
        @try
        {

            /* we register every local IP / remote IP pair combination */

            NSArray *localAddrs = layer.configured_local_addresses;
            NSArray *remoteAddrs = layer.configured_remote_addresses;
            for(NSString *localAddr in localAddrs)
            {
                for(NSString *remoteAddr in remoteAddrs)
                {
                    NSString *key = [UMSocketSCTPRegistry registryKeyForLocalAddr:localAddr
                                                                        localPort:layer.configured_local_port
                                                                       remoteAddr:remoteAddr
                                                                       remotePort:layer.configured_remote_port
                                                                     encapsulated:layer.encapsulatedOverTcp];
                    _outgoingLayersByIpsAndPorts[key] = layer;
                    if(anyPort)
                    {
                        NSString *key = [UMSocketSCTPRegistry registryKeyForLocalAddr:localAddr
                                                                            localPort:layer.configured_local_port
                                                                           remoteAddr:remoteAddr
                                                                           remotePort:0
                                                                         encapsulated:layer.encapsulatedOverTcp];
                        _outgoingLayersByIpsAndPorts[key] = layer;
                    }
                }
            }
            [_outgoingLayers removeObject:layer];
            [_outgoingLayers addObject:layer];
        }
        @catch(NSException *e)
        {
            [self handleException:e];
        }
        @finally
        {
            ummutex_unlock(_registryLock);
        }
    }
}


- (void)registerSessionKey:(NSString *)session_key forLayer:(UMLayerSctp *)layer
{
    if(layer.encapsulatedOverTcpSessionKey)
    {
        ummutex_lock(_registryLock);
        _layersBySessionKey[session_key] = layer;
        ummutex_unlock(_registryLock);
    }
}

- (void)unregisterSessionKey:(NSString *)session_key
{
    ummutex_lock(_registryLock);
    [_layersBySessionKey removeObjectForKey:session_key];
    ummutex_unlock(_registryLock);
}

- (void)unregisterLayer:(UMLayerSctp *)layer
{
    if(layer)
    {
        ummutex_lock(_registryLock);
        @try
        {
            /* we unregister every local IP / remote IP pair combination */
            
            NSArray *localAddrs = layer.configured_local_addresses;
            NSArray *remoteAddrs = layer.configured_remote_addresses;
            for(NSString *localAddr in localAddrs)
            {
                for(NSString *remoteAddr in remoteAddrs)
                {
                    NSString *key = [UMSocketSCTPRegistry registryKeyForLocalAddr:localAddr
                                                                        localPort:layer.configured_local_port
                                                                       remoteAddr:remoteAddr
                                                                       remotePort:layer.configured_remote_port
                                                                     encapsulated:layer.encapsulatedOverTcp];
                    [self unregisterSessionKey:key];
                }
            }
            [_outgoingLayers removeObject:layer];
            [_incomingLayers removeObject:layer];
            [_outgoingTcpLayers removeObject:layer];
            [_incomingTcpLayers removeObject:layer];
            if(layer.encapsulatedOverTcpSessionKey)
            {
                [self unregisterSessionKey:layer.encapsulatedOverTcpSessionKey];
            }
        }
        @catch(NSException *e)
        {
            [self handleException:e];
        }
        @finally
        {
            ummutex_unlock(_registryLock);
        }
    }
}


- (NSString *)webStat
{
    NSMutableString *s = [[NSMutableString alloc]init];
    ummutex_lock(_registryLock);
    [s appendString:@"<html>\n"];
    [s appendString:@"<header>\n"];
    [s appendString:@"    <link rel=\"stylesheet\" href=\"/css/style.css\" type=\"text/css\">\n"];
    [s appendFormat:@"    <title>Debug: SCTP Registry Statistic</title>\n"];
    [s appendString:@"</header>\n"];
    [s appendString:@"<body>\n"];

    [s appendString:@"<h2>Debug: SCTP Registry Statistic</h2>\n"];
    [s appendString:@"<UL>\n"];
    [s appendString:@"<LI><a href=\"/\">main</a></LI>\n"];
    [s appendString:@"<LI><a href=\"/debug\">debug</a></LI>\n"];
    [s appendString:@"</UL>\n"];

    [s appendString:@"<table class=\"object_table\">\n"];
    [s appendString:@"    <tr>\r\n"];
    [s appendString:@"        <th class=\"object_title\">Object Type</th>\r\n"];
    [s appendString:@"        <th class=\"object_title\">Count</th>\r\n"];
    [s appendString:@"    </tr>\r\n"];

    [s appendString:@"    <tr>\r\n"];
    [s appendFormat:@"        <td class=\"object_name\">_entries</td>\r\n"];
    [s appendFormat:@"        <td class=\"object_value\">%d</th>\r\n",(int)_entries.count];
    [s appendString:@"    </tr>\r\n"];

    [s appendString:@"    <tr>\r\n"];
    [s appendFormat:@"        <td class=\"object_name\">_outgoingLayers</td>\r\n"];
    [s appendFormat:@"        <td class=\"object_value\">%d</th>\r\n",(int)_outgoingLayers.count];
    [s appendString:@"    </tr>\r\n"];

    [s appendString:@"    <tr>\r\n"];
    [s appendFormat:@"        <td class=\"object_name\">_incomingListeners</td>\r\n"];
    [s appendFormat:@"        <td class=\"object_value\">%d</th>\r\n",(int)_incomingListeners.count];
    [s appendString:@"    </tr>\r\n"];

    [s appendString:@"    <tr>\r\n"];
    [s appendFormat:@"        <td class=\"object_name\">_outgoingLayersByIpsAndPorts</td>\r\n"];
    [s appendFormat:@"        <td class=\"object_value\">%d</th>\r\n",(int)_outgoingLayersByIpsAndPorts.count];
    [s appendString:@"    </tr>\r\n"];
    [s appendString:@"</table>\r\n"];
    [s appendString:@"</body>\r\n"];
    [s appendString:@"</html>\r\n"];
    ummutex_unlock(_registryLock);
    return s;
}

- (UMLayerSctp *)layerForSessionKey:(NSString *)sessionKey
{
    ummutex_lock(_registryLock);
    UMLayerSctp *layer = _layersBySessionKey[sessionKey];
    ummutex_unlock(_registryLock);
    return layer;
}


+ (NSString *)registryKeyForLocalAddr:(NSString *)lo
                            localPort:(int)lp
                           remoteAddr:(NSString *)ra
                           remotePort:(int)rp
                         encapsulated:(BOOL)encap
{
    NSString *key = [NSString stringWithFormat:@"%@/%d->%@/%d(%@)",lo,lp,ra,rp,encap ? @"tcp" : @"sctp"];
    return key;
}

- (void)handleException:(NSException *)e
{
    if(_logLevel <=UMLOG_MINOR)
    {
        NSLog(@"Exception: %@",e);
    }
}

@end
    
#endif
