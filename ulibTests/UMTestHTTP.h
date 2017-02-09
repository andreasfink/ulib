//
//  UMTestHTTP.h
//  ulib
//
//  Created by Aarno Syvänen on 25.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UniversalHTTP.h"
#import "UniversalSocket.h"



#ifdef HAVE_OPENSSL
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif

@interface TestCounter : NSObject
{
    NSLock *lock;
    unsigned long n;
}

@property(readwrite,strong)	NSLock *lock;

/* create a new counter object.*/
- (TestCounter *)init;

/* destroy it */

/* return the current value of the counter and increase counter by one */
- (unsigned long)increase;

/* return the current value of the counter and increase counter by value */
- (unsigned long)increaseWith:(unsigned long)value;

/* return the current value of the counter */
-(unsigned long)value;

/* return the current value of the counter and decrease counter by one */
- (unsigned long)decrease;

/* return the current value of the counter and set it to the supplied value */
- (unsigned long)setTo:(unsigned long)value;

@end

@interface TestMutableArray : UMObject
{
    NSMutableArray *array;
    NSCondition *nonempty;
    NSLock *singleOperationLock;
    NSLock *permanentLock;
    long numProducers;
    long numConsumers;
}

@property(readwrite,strong) NSMutableArray *array;
@property(readwrite,strong) NSCondition *nonempty;
@property(readwrite,strong) NSLock *singleOperationLock;
@property(readwrite,strong) NSLock *permanentLock;
@property(readwrite,assign) long numProducers;
@property(readwrite,assign) long numConsumers;

- (TestMutableArray *) init;
- (id) consume;
- (id)consumeUnlocked;
- (void) removeProducer;
- (void)addObject:(id)item;
- (void)addObjectUnlocked:(id)item;
- (NSUInteger)count;
- (id)objectAtIndex:(NSUInteger)index;
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index;
- (NSString *)description;

@end

@interface UMHTTPCaller : TestMutableArray
{
    UMHTTPMethod method;
    NSString *subsection;
    NSString *section;
    NSString *name;
}

@property(readwrite,assign) UMHTTPMethod method;
@property(readwrite,strong) NSString *subsection;
@property(readwrite,strong) NSString *section;
@property(readwrite,strong) NSString *name;


- (UMHTTPCaller *)init;
- (NSString *)subsection;
- (void)addProducer;
- (void) addLogFile:(NSString *)logFile withSection:(NSString *)type withSubsection:(NSString *)ss withName:(NSString *)n;
/*
 * Signal to a caller (presumably waiting receiveResultWithCaller) that
 * we're entering shutdown phase. This will make receiveResultWithCaller
 * no longer block if the queue is empty.
 */
- (void)signalShutdown;

@end

@class UMSocket;

/*
 * Pool of open, but unused connections to servers or proxies. Key is
 * "servername:port", value is NSMutableArray of UMSocket objects.
 */
@interface UMConnPool : UMObject
{
    NSMutableDictionary *connPool;
    NSLock *connPoolLock;
}

@property(readwrite,strong) NSMutableDictionary *connPool;
@property(readwrite,strong) NSLock *connPoolLock;

- (UMConnPool *)init;
- (NSString *)keyWithRemoteHost:(NSString *)host withPort:(int) port enableSSL:(BOOL)ssl withCertificate:(NSString *)certfile withLocalHost:(NSString *)our_host;
- (UMSocket *) getSocketWith:(NSString *)host withPort:(int)port withSSL:(BOOL) ssl withCertificate:(NSString *)certkeyfile withLocalHost:(NSString *)ourHost;
- (void)checkSocket:(UMSocket *)sock withKey:(NSString *)data whenRunStatusIs:(BOOL)running  andSockError:(BOOL)error andSockEOF:(BOOL)eof;
- (void)putSocket:(UMSocket *)conn withRemoteHost:(NSString *)host withPort:(int)port enableSSL:(int)ssl withCertificate:(NSString *)certfile withLocalHost:(NSString *)our_host;


@end

@interface UMHTTPRequest (UMTestRequest)

- (void)addBasicAuthWithUserName:(NSString *)username andPassword:(NSString *)password;
- (void)requestHeadersCombineWith:(NSMutableArray *)headers;

@end

/*
@interface NSMutableArray (HTTPHeader)

+ (BOOL)nameOf:(NSString *)header is:(NSString *)name;
- (long)removeAllWithName:(NSString *)name;
- (void)getHeaderAtIndex:(long)i withName:(NSString **)name andValue:(NSMutableString **)value;
- (NSString *)findFirstWithName:(NSString *)name;
- (int)readSomeHeadersFrom:(UMSocket *)sock;
- (void)addHeaderWithName:(NSString *)name andValue:(NSString *)value;
- (void)addBasicAuthWithUserName:(NSString *)username andPassword:(NSString *)password;
- (void)proxyAddAuthenticationWithUserName:(NSString *)username andPassword:(NSString *)password;
- (void)getContentType:(NSMutableString **)type andCharset:(NSMutableString **)charset;

@end
*/
@interface NSDictionary (HTTPHeader)

- (NSString *)logDescription;
- (NSMutableArray *) toArray;

@end

@interface TestSocket : UMSocket
{
    BOOL useSsl;
//    SSL *ssl;
//    X509 *peer_certificate;
    SSL_CTX *global_ssl_context;
    SSL_CTX *global_server_ssl_context;
}

@property(readwrite,assign)	BOOL useSsl;

- (TestSocket *)init;
- (void)close;
- (int)SSLSmartShutdown;
- (UMSocketError)initWithSSLWithCertKeyFile:(NSString *)certificate;

@end
