//
//  UMSocket.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMCrypto.h"
#import "UMSocketDefs.h"
#import "UMMutex.h"
#import "UMPacket.h"

#include <sys/types.h>
#include <sys/socket.h>
#include "ulib_config.h"

#ifndef in_port_t   
#define in_port_t   uint16_t
#endif


@class UMHost;
@class UMHistoryLog;

typedef enum SocketBlockingMode
{
    SocketBlockingMode_unknown = 0,
    SocketBlockingMode_isNotBlocking = -1,
    SocketBlockingMode_isBlocking = 1,
} SocketBlockingMode;

#if TARGET_OS_WATCH
@interface UMSocket : UMObject
#else
@interface UMSocket : UMObject<NSNetServiceDelegate>
#endif
{
	UMSocketType		type;
	UMSocketConnectionDirection	direction;
	UMSocketStatus		status;
	UMHost				*_localHost;
	UMHost				*_remoteHost;
	in_port_t			_requestedLocalPort;
	in_port_t			_requestedRemotePort;
	in_port_t			_connectedLocalPort;
	in_port_t			_connectedRemotePort;
	NSString			*_connectedLocalAddress;
	NSString			*_connectedRemoteAddress;
	int					_sock;
    
    int                 _socketDomain;
    int                 _socketFamily;
    int                 _socketProto;
    int                 _socketType; /* STREAM | DATAGRAM | SEQPACKET*/

	BOOL    			_isBound;
	BOOL                _isListening;
	BOOL                _isConnecting;
	BOOL                _isConnected;
	SocketBlockingMode  _blockingMode;
    BOOL                 _hasSocket;
	NSString			*device;
	int					lastPollEvent;
	NSMutableData		*_receiveBuffer;
	int					rx_crypto_enable;
	int					tx_crypto_enable;
	NSString			*lastError;
    UMCrypto			*cryptoStream;
	id					reportDelegate;	/* must have reportStatus:(NSString *) str */
    long                receivebufpos;
    BOOL                useSSL;
    BOOL                sslActive;
    
    NSString            *serverSideCertFilename;
    NSString            *serverSideKeyFilename;
    NSData              *serverSideCertData;
    NSData              *serverSideKeyData;
    BOOL                _isInPollCall;
    void                *ssl;
    NSString            *_socketName;
    UMMutex             *_controlLock;
    UMMutex             *_dataLock;

@protected
    int                 ip_version;
    NSString            *name;
#if !TARGET_OS_WATCH
    NSNetService        *netService;
#endif
    NSString            *advertizeName;
    NSString            *advertizeDomain;
    int                 _configuredMaxSegmentSize;
    int                 _activeMaxSegmentSize;
    id __weak           _customUser; /* a user can use this field as a reference to its user */
    UMHistoryLog         *_historyLog;
}

@property(readwrite,strong,atomic)  NSString    *socketName;
@property(readwrite,strong,atomic)  UMHost      *localHost;
@property(readwrite,strong,atomic)  UMHost      *remoteHost;
@property(readwrite,strong,atomic)  NSString    *connectedLocalAddress;
@property(readwrite,strong,atomic)  NSString    *connectedRemoteAddress;
@property(readwrite,assign,atomic)  in_port_t   connectedLocalPort;
@property(readwrite,assign,atomic)  in_port_t   connectedRemotePort;
@property(readwrite,assign,atomic)  BOOL        isInPollCall;
@property(readwrite,weak)		    id          friend;

@property(readwrite,assign,atomic)  UMSocketType		type;
@property(readwrite,assign,atomic)  UMSocketConnectionDirection	direction;
@property(readwrite,assign,atomic)  UMSocketStatus		status;
@property(readwrite,assign,atomic)  in_port_t			requestedLocalPort;
@property(readwrite,assign,atomic)  in_port_t			requestedRemotePort;
@property(readwrite,assign,atomic)  int					sock;

@property(readwrite,assign,atomic)  BOOL    			isBound;
@property(readwrite,assign,atomic)  BOOL                isListening;
@property(readwrite,assign,atomic)  BOOL				isConnecting;
@property(readwrite,assign,atomic)  BOOL	            isConnected;
@property(readwrite,strong,atomic)  NSMutableData *		receiveBuffer; /* use dataLock when accessing */
@property(readwrite,strong,atomic)  NSString *          lastError;
@property(readwrite,strong,atomic)  id					reportDelegate;
@property(readwrite,strong,atomic)  NSString            *name;
@property(readwrite,assign,atomic)  BOOL                hasSocket;
@property(readwrite,strong,atomic)  NSString            *advertizeName;
@property(readwrite,strong,atomic)  NSString            *advertizeType;
@property(readwrite,strong,atomic)  NSString            *advertizeDomain;
@property(readwrite,strong,atomic)  UMCrypto            *cryptoStream;
@property(readwrite,assign,atomic)  BOOL                useSSL;
@property(readwrite,assign,atomic)  BOOL                sslActive;
@property(readwrite,strong,atomic)  UMMutex             *controlLock;
@property(readwrite,strong,atomic)  UMMutex             *dataLock;

@property(readwrite,strong,atomic) NSString            *serverSideCertFilename;
@property(readwrite,strong,atomic) NSString            *serverSideKeyFilename;
@property(readwrite,strong,atomic) NSData              *serverSideCertData;
@property(readwrite,strong,atomic) NSData              *serverSideKeyData;

@property(readonly)                int                 fileDescriptor;
@property(readonly)                void                *ssl;
@property(readwrite,assign,atomic)  int                 socketDomain;
@property(readwrite,assign,atomic)  int 				socketFamily;
@property(readwrite,assign,atomic)  int 				socketProto;
@property(readwrite,assign,atomic)  int 				socketType;

@property(readwrite,assign,atomic)  int                configuredMaxSegmentSize;
@property(readwrite,assign,atomic)  int                activeMaxSegmentSize;
@property (weak) id customUser;
@property(readwrite,strong,atomic) UMHistoryLog        *historyLog;
@property(readwrite,assign,atomic) int                 dscp;

- (UMSocket *) initWithType:(UMSocketType)t;
- (UMSocket *) initWithType:(UMSocketType)t name:(NSString *)name;

//+ (void) initSSL;
+ (NSString *) statusDescription:(UMSocketStatus)s;
+ (NSString *) directionDescription:(UMSocketConnectionDirection)d;
+ (NSString *) socketTypeDescription:(UMSocketType)t;
- (NSString *) description;
- (NSString *) fullDescription;
- (void) doInitReceiveBuffer;
- (void) deleteFromReceiveBuffer:(NSUInteger)bytes;
- (void) setRemoteHost: (UMHost *) host;
- (void) setRemotePort: (in_port_t) port;
- (UMSocketError)	bind;
- (UMSocketError)	openAsync;
- (UMSocketError)	listen;
- (UMSocketError)	listen: (int) backlog;
- (UMSocketError)	connect;
- (UMSocket *)		accept:(UMSocketError *)ret;
- (UMSocketError)	close;
- (UMSocketError)  waitDataAvailable;
- (UMSocketError)  dataIsAvailable;
- (UMSocketError)  dataIsAvailable:(int)timeoutInMs;
+ (NSArray *)dataIsAvailableOnSockets:(NSArray *)inputSockets timeoutMs:(int)timeoutMs err:(UMSocketError *) err;
- (void) updateName;
- (UMSocketError)  sendBytes:(void *)bytes length:(ssize_t)length;
- (UMSocketError)  sendCString:(char *)str;
- (UMSocketError)  sendString:(NSString *)str;
- (UMSocketError)  sendData:(NSData *)data;
- (UMSocketError)  sendMutableData:(NSMutableData *)data;
- (void) sendNow;
- (int) sendSctp:(void *)bytes length:(ssize_t)len  stream:(NSUInteger) streamID protocol:(NSUInteger) protocolID;
- (int) sendSctpBytes:(void *)bytes length:(int)len;
- (int) sendSctpNSData:(NSData *)data;
- (UMSocketError) receive: (ssize_t)maxSize appendTo:(NSMutableData *)appendToMe;
- (void) reportError:(int)err withString: (NSString *)errString;
- (void) reportStatus: (NSString *)str;
- (UMSocketError) switchToNonBlocking;
- (UMSocketError) switchToBlocking;
- (UMSocket *) copyWithZone:(NSZone *)zone;
- (void) setLocalPort:(in_port_t) port;
- (UMSocketError) receiveToBufferWithBufferLimit: (int) max;
- (UMSocketError) receiveToBufferWithBufferLimit: (int) max read:(ssize_t *)numberOfBytes;
- (UMSocketError) receiveLineToLF:(NSData **)toData;
- (UMSocketError) receiveLineToCR:(NSData **)toData;
- (UMSocketError) receiveLineToCRLF:(NSData **)toData;
- (UMSocketError) receiveLineTo:(NSData **)toData; /* depreciated. use receiveLineToLF instead */
- (UMSocketError) receiveLineTo:(NSData **)toData eol:(NSData *)eol;
- (UMSocketError) receiveEverythingTo:(NSData **)toData;
- (UMSocketError) receiveData:(NSData **)toData fromAddress:(NSString **)address fromPort:(int *)port;
- (UMSocketError) sendData:(NSData *)data toAddress:(NSString *)address toPort:(int)port;
- (UMSocketError) receive:(long)bytes to:(NSData **)receivedData;
- (UMSocketError) receiveSingleChar:(unsigned char *)cptr;
- (UMSocketError) writeSingleChar:(unsigned char)c;

- (void) setEvent: (int) event;
+ (UMSocketError) umerrFromErrno:(int)e;
//+ (UMSocketError) umerrFromSSL:(int)SSL_error;
+ (NSString *) getSocketErrorString:(UMSocketError)e;
- (BOOL)	isTcpSocket;
- (BOOL)	isUdpSocket;
- (BOOL)	isSctpSocket;
- (BOOL)	isUserspaceSocket;
- (NSString *)getRemoteAddress;
- (in_port_t) localPort;
- (UMSocketError) publish;
- (UMSocketError) unpublish;

//- (BOOL)startSslWithCert:(NSString *)certkeyfile;
//- (X509 *)getPeerCertificate;
//- (BOOL)acceptSsl;


+(NSString *)unifyIP:(NSString *)addr;
+(NSString *)deunifyIp:(NSString *)addr;
+(NSString *)deunifyIp:(NSString *)addr type:(int *)t;
-(void)startTLS;

+(void)initSSL;

- (void) initNetworkSocket;
- (UMSocketError) setLinger;
- (UMSocketError) setReuseAddr;
- (UMSocketError) setIPDualStack;
- (UMSocketError) setIPv6Only;
- (UMSocketError) setKeepalive:(BOOL)keepalive;
+ (NSString *)addressOfSockAddr:(struct sockaddr *)sockAddr;
+ (int)portOfSockAddr:(struct sockaddr *)sockAddr;
+ (NSData *)sockaddrFromAddress:(NSString *)theAddr
                           port:(int)thePort
                   socketFamily:(int)socketFamily;
- (int)bindx:(struct sockaddr *)localAddress;

- (UMPacket *)receivePacket;
- (UMSocketError) getSocketError;

- (void)setReceiveBufferSize:(int)bufsize;
- (void)setSendBufferSize:(int)bufsize;
- (int)receiveBufferSize;
- (int)sendBufferSize;

- (void)setDscpString:(NSString *)dscp;
- (NSString *)dscpString;

@end


