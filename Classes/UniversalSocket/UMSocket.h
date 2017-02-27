//
//  UMSocket.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMCrypto.h"
#import "UMSocketDefs.h"

#include <sys/types.h>
#include <sys/socket.h>
#include "ulib_config.h"

#ifndef in_port_t   
#define in_port_t   uint16_t
#endif


@class UMHost;

#if defined(TARGET_OS_WATCH)
@interface UMSocket : UMObject
#else
@interface UMSocket : UMObject<NSNetServiceDelegate>
#endif
{
	UMSocketType		type;
	UMSocketConnectionDirection	direction;
	UMSocketStatus		status;
	UMHost				*localHost;
	UMHost				*remoteHost;
	in_port_t			requestedLocalPort;
	in_port_t			requestedRemotePort;
	in_port_t			connectedLocalPort;
	in_port_t			connectedRemotePort;
	NSString			*_connectedLocalAddress;
	NSString			*_connectedRemoteAddress;
	int					_sock;
    int                 _family;
	int					_isBound;
	int					_isListening;
	int					_isConnecting;
	int					_isConnected;
	int					_isNonBlocking;
    int                 _hasSocket;
	NSString			*device;
	int					lastPollEvent;
	NSMutableData		*receiveBuffer;
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

    void                *ssl;

@private
    int                 ip_version;
    NSString            *name;
#if !defined(TARGET_OS_WATCH)
    NSNetService        *netService;
#endif
    NSString            *advertizeName;
    NSString            *advertizeDomain;
}

@property(readwrite,strong)		UMHost				*localHost;
@property(readwrite,strong)		UMHost				*remoteHost;
@property(readwrite,strong)		NSString			*connectedLocalAddress;
@property(readwrite,strong)		NSString			*connectedRemoteAddress;
@property(readwrite,assign)		in_port_t			connectedLocalPort;
@property(readwrite,assign)		in_port_t			connectedRemotePort;

@property(readwrite,assign)		UMSocketType		type;
@property(readwrite,assign)		UMSocketConnectionDirection	direction;
@property(readwrite,assign)		UMSocketStatus		status;
@property(readwrite,assign)		in_port_t			requestedLocalPort;
@property(readwrite,assign)		in_port_t			requestedRemotePort;
@property(readwrite,assign,atomic)		int					sock;

@property(readwrite,assign,atomic)		int					isBound;
@property(readwrite,assign,atomic)		int					isListening;
@property(readwrite,assign,atomic)		int					isConnecting;
@property(readwrite,assign,atomic)		int					isConnected;
@property(readwrite,strong)		NSMutableData *		receiveBuffer;
@property(readwrite,strong)		NSString *          lastError;
@property(readwrite,strong)		id					reportDelegate;
@property(readwrite,strong)		NSString *name;
@property(readwrite,assign,atomic)     int                 hasSocket;
@property(readwrite,strong)		NSString *advertizeName;
@property(readwrite,strong)		NSString *advertizeType;
@property(readwrite,strong)		NSString *advertizeDomain;
@property(readwrite,strong)  	UMCrypto *cryptoStream;
@property(readwrite,assign)     BOOL                useSSL;
@property(readwrite,assign)     BOOL                sslActive;

@property(readwrite,strong) NSString            *serverSideCertFilename;
@property(readwrite,strong) NSString            *serverSideKeyFilename;
@property(readwrite,strong) NSData              *serverSideCertData;
@property(readwrite,strong) NSData              *serverSideKeyData;

@property(readonly) int fileDescriptor;
@property(readonly) void *ssl;




//+ (void) initSSL;
+ (NSString *) statusDescription:(UMSocketStatus)s;
+ (NSString *) directionDescription:(UMSocketConnectionDirection)d;
+ (NSString *) socketTypeDescription:(UMSocketType)t;
- (NSString *) description;
- (NSString *) fullDescription;
- (UMSocket *) initWithType:(UMSocketType)type;
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
- (void) switchToNonBlocking;
- (void) switchToBlocking;
//- (BOOL) isNonBlocking;
//- (void) setIsNonBlocking:(int)i;
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
+(NSString *)deunifyIp:(NSString *)addr type:(int *)t;
-(void)startTLS;

+(void)initSSL;

@end


