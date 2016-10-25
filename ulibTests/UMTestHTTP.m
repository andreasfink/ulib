//
//  UMTestHTTP.m
//  ulib
//
//  Created by Aarno Syvänen on 25.04.12.
//  Copyright (c) Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved
//

#import "UMTestHTTP.h"
#import "UMTestHTTPClient.h"
#import "UMTestHTTPEntity.h"
#import "UMConfig.h"
#import "UMTestCase.h"
#import "NSMutableString+UMTestString.h"
#import "NSMutableArray+UMHTTP.h"
#import "UMLogFile.h"
#import "UMLogFeed.h"
/* note this should point to $(SRCROOT)/libressl/osx/include/openssl/ssl.h not the one in the SDK */
#include "openssl/ssl.h"
#include <pthread.h>
#include <ctype.h>

@implementation TestCounter

@synthesize lock;

/* create a new counter object.*/
- (TestCounter *)init
{
    if((self=[super init]))
    {
        self.lock = [[NSLock alloc] init];
        n = 0;
    }
    return self;
}

/* return the current value of the counter and increase counter by one */
- (unsigned long)increase
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    ++n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and increase counter by value */
- (unsigned long)increaseWith:(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    n += value;
    [lock unlock];
    return ret;
}

/* return the current value of the counter */
-(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and decrease counter by one */
- (unsigned long)decrease
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    if (n > 0)
        --n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and set it to the supplied value */
- (unsigned long)setTo:(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    n = value;
    [lock unlock];
    return ret;
}

@end

@implementation TestMutableArray

@synthesize array;
@synthesize nonempty;
@synthesize singleOperationLock;
@synthesize permanentLock;
@synthesize numProducers;
@synthesize numConsumers;

- (TestMutableArray *)init
{
    if((self=[super init]))
    {
        self.array = [[NSMutableArray alloc] init];
        self.singleOperationLock = [[NSLock alloc] init];
        self.permanentLock = [[NSLock alloc] init];
        self.nonempty = [[NSCondition alloc] init];
        self.numProducers = 0;
        self.numConsumers = 0;
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc;
    
    desc = [[NSMutableString alloc] initWithString:@"Test mutable array dump starts\r\n"];
    [desc appendFormat:@"number of producers is %ld\r\n", numProducers];
    [desc appendFormat:@"number of consumers is %ld\r\n", numConsumers];
    [desc appendFormat:@"array itself is %@\r\n", array];
    
    return desc;
}

- (void) removeProducer
{ 
    [nonempty lock];
    --numProducers;
    [nonempty broadcast];
    [nonempty unlock];
}

- (id)consume
{
    id item;
    long len;
    
    [nonempty lock];
    ++numConsumers;
    while ((len = [array count]) == 0 && numProducers > 0) 
        [nonempty wait];
    
    if (len > 0) 
    {
        item  = array[0];
        [array removeObjectAtIndex:0];
    } 
    else
        item = nil;

    --numConsumers;
    [nonempty unlock];
    return item;
}


- (id)consumeUnlocked
{
    id item;
    long len;
    
    len = [array count];
    if (len > 0)
    {
        item = array[0];
        [array removeObjectAtIndex:0];
    } 
    else
        item = nil;
    
    return item;
}

- (void)addObject:(id)item
{
    if (!item)
        return;
    
    [nonempty lock];
    [array addObject:item];
    [nonempty signal];
    [nonempty unlock];
}

- (void)addObjectUnlocked:(id)item
{
    if (!item)
        return;
    
    [array addObject:item];
}

- (NSUInteger)count
{
    return [array count];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return array[index];
}

-(void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if (!anObject)
        return;
    
    [array insertObject:anObject atIndex:index];
}

@end

@implementation UMHTTPCaller

@synthesize method;
@synthesize subsection;
@synthesize section;
@synthesize name;

- (UMHTTPCaller *)init
{
    if((self=[super init]))
    {
       [self addProducer];
    }
    return self;
}

- (void)addProducer
{
    [nonempty lock];
    ++numProducers;
    [nonempty unlock];
}

- (void)signalShutdown
{
    [nonempty lock];
    if (numProducers == 0)
    {
        [nonempty unlock];
        return;
    }
    
    --numProducers;
    [nonempty broadcast];
    [nonempty unlock];
}

- (void) addLogFile:(NSString *)logFile withSection:(NSString *)type withSubsection:(NSString *)ss withName:(NSString *)n
{
    UMLogHandler *handler;
    UMLogFile *dst;
    
    handler = [[UMLogHandler alloc] init];
    dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
    logFeed = [[UMLogFeed alloc] initWithHandler:handler section:type subsection:ss];
    [handler addLogDestination:dst];
    
    self.section = type;
    self.subsection = ss;
    self.name = n;
}

@end

@implementation UMHTTPRequest (UMTestRequest)

- (void)addBasicAuthWithUserName:(NSString *)username andPassword:(NSString *)password
{
    NSMutableString *os;
    
    if (password)
        os = [NSMutableString stringWithFormat:@"%@:%@", username, password];
    else
        os = [NSMutableString stringWithFormat:@"%@", username];
    
    [os binaryToBase64];
    [os stripBlanks];
    [os insertString:@"Basic " atIndex:0];
    [self setRequestHeader:@"Authorization" withValue:os];
}

- (void)requestHeadersCombineWith:(NSMutableArray *)headers
{
    long i;
    NSString *name;
    NSMutableString *value;
    long len;
    
    len = [requestHeaders count];
    /*
     * Avoid doing this scan if old_headers is empty anyway.
     */
    if ([headers count] > 0) {
        for (i = 0; i < len; i++) {
            [headers getHeaderAtIndex:i withName:&name andValue:&value];
            [self removeRequestHeader:name];
        }
    }
    
    [self setRequestHeadersFromArray:headers];
}

@end

/*
@implementation NSMutableArray (HTTPHeader)

- (void)getContentType:(NSMutableString **)type andCharset:(NSMutableString **)charset
{
    NSMutableString *h;
    NSRange semicolon, equals;
    long len;
    
    h = [[self findFirstWithName:@"Content-Type"] mutableCopy];
    if (!h) 
    {
        *type = [NSMutableString stringWithString:@"application/octet-stream"];
        *charset = [NSMutableString string];
    } 
    else 
    {
        [h stripBlanks];
        semicolon = [h rangeOfString:@";"];
        if (semicolon.location == NSNotFound) 
        {
            *type = h;
            *charset = [NSMutableString string];
        } 
        else 
        {
            *charset = [h mutableCopy];
            [*charset deleteCharactersInRange:NSMakeRange(0, semicolon.location + 1)];
            [*charset stripBlanks];
            equals = [*charset rangeOfString:@"="];
            if (equals.location == NSNotFound)
                [*charset deleteCharactersInRange:NSMakeRange(0, [*charset length])];
            else 
            {
                [*charset deleteCharactersInRange:NSMakeRange(0, equals.location + 1)];
                if ([*charset characterAtIndex:0] == '"')
                    [*charset deleteCharactersInRange:NSMakeRange(0, 1)];
                len = [*charset length];
                if ([*charset characterAtIndex:len - 1] == '"')
                    [*charset deleteCharactersInRange:NSMakeRange(len - 1, 1)];
            }
            
            [h deleteCharactersInRange:NSMakeRange(semicolon.location, [h length] - semicolon.location)];
            [h stripBlanks];
            *type = h;
        }
*/
        /*
         * According to HTTP/1.1 (RFC 2616, section 3.7.1) we have to ensure
         * to return charset 'iso-8859-1' in case of no given encoding and
         * content-type is a 'text' subtype.
         */
/*
        if ([*charset length] == 0 &&
            [*type compare:@"text" options:NSCaseInsensitiveSearch range:NSMakeRange(0, 4)] == NSOrderedSame)
            [*charset appendString:@"ISO-8859-1"];
    }
}

- (void)addBasicAuthWithUserName:(NSString *)username andPassword:(NSString *)password
{
    NSMutableString *os;
    
    if (password)
        os = [NSMutableString stringWithFormat:@"%@:%@", username, password];
    else
        os = [NSMutableString stringWithFormat:@"%@", username];
    
    [os binaryToBase64];
    [os stripBlanks];
    [os insertString:@"Basic " atIndex:0];
    [self addHeaderWithName:@"Authorization" andValue:os];
}

- (void)addHeaderWithName:(NSString *)name andValue:(NSString *)value
{
    NSString *h;
    
    if (!name)
        return;
    
    if (!value)
        return;;
    
    h = [NSString stringWithFormat:@"%@: %@", name, value];
    [self addObject:h];
}

+ (BOOL)nameOf:(NSString *)header is:(NSString *)name
{
    NSRange colon;
    NSComparisonResult ret;
    NSRange start;
    
    colon = [header rangeOfString:@":"];
    if (colon.location == NSNotFound)
        return FALSE;
    
    if ((long) [name length]!= colon.location)
        return FALSE;
    
    start = NSMakeRange(0, colon.location);
    ret = [header compare:name options:NSCaseInsensitiveSearch range:start];
    return ret == NSOrderedSame;
}

- (long)removeAllWithName:(NSString *)name
{
    NSString *h;
    long count, i;
    
    if (!name)
        return 0;
    
    i = 0;
    count = 0;
    while (i < [self count]) {
        h = [self objectAtIndex:i];
        if ([NSMutableArray nameOf:h is:name]) {
            [self removeObjectAtIndex:i];
            count++;
        } else
            i++;
    }
    
    return count;
}

- (void)proxyAddAuthenticationWithUserName:(NSString *)username andPassword:(NSString *)password
{
    NSMutableString *os;
    
    if (!username || !password)
        return;
    
    os = [NSMutableString stringWithFormat:@"%@:%@", username, password];
    [os binaryToBase64];
    [os stripBlanks];
    [os replaceCharactersInRange:NSMakeRange(0,0) withString:@"Basic "];
    [self addHeaderWithName:@"Proxy-Authorization" andValue:os];   
}

- (NSString *)findFirstWithName:(NSString *)name
{
    long i, name_len;
    NSString *h;
    NSMutableString *value;
    
    if(!name)
        return nil;
    
    name_len = [name length];
    
    for (i = 0; i < [self count]; ++i) {
        h = [self objectAtIndex:i];
        if ([NSMutableArray nameOf:h is:name]) {
            value = [[h substringWithRange:NSMakeRange(name_len + 1, [h length] - name_len - 1)] mutableCopy];
            [value stripBlanks];
            return value;
        }
    }
    return nil;
}
*/
/*
 * Read some headers, i.e., until the first empty line (read and discard
 * the empty line as well). Return -1 for error, 0 for all headers read,
 * 1 for more headers to follow.
 */
/*
- (int)readSomeHeadersFrom:(UMSocket *)sock
{
    NSMutableString *line, *prev;
    long len;
    NSMutableData *dline;
    UMSocketError sErr;
    char first;
    
    if ((len = [self count]) == 0)
        prev = NULL;
    else
    {
        prev = [self objectAtIndex:len - 1];
    }
    
    for (;;) {
        sErr = [sock receiveLineTo:&dline];
        if (!dline) 
        {  
            if (sErr != UMSocketError_try_again)
                return -1;
            return 1;
        }
        
        if ([dline length] == 0) {
            break;
        }
        
        line = [[NSMutableString alloc] initWithData:dline encoding:NSASCIIStringEncoding];
        first = [line characterAtIndex:0];
        if (isspace(first) && prev) {
            [prev appendString:line];
        } else {
            [self addObject:line];
            prev = line;
        }
    }
    
    return 0;      
}

@end*/
                  
@implementation UMConnPool

@synthesize connPool;
@synthesize connPoolLock;
                  
- (UMConnPool *)init
{
    if((self = [super init]))
    {
        self.connPool = [[NSMutableDictionary alloc] init];
        self.connPoolLock = [[NSLock alloc] init];
    }
    return self;
}

- (void)dealloc
{
    NSArray *keys = [connPool allKeys];
    for (NSString *key in keys)
    {
        NSArray *list = connPool[key];
        TestSocket *socket = list[0];
        [socket close];
    }
}
                                    
- (NSString *)keyWithRemoteHost:(NSString *)host withPort:(int) port enableSSL:(BOOL)ssl withCertificate:(NSString *)certfile withLocalHost:(NSString *)ourHost
{
    return [NSString stringWithFormat:@"%@:%d:%d:%@:%@", host, port, ssl ? : 0, certfile ? certfile : @"", ourHost ? ourHost : @""];
}
                  
- (UMSocket *) getSocketWith:(NSString *)host withPort:(int)port withSSL:(BOOL) ssl withCertificate:(NSString *)certkeyfile withLocalHost:(NSString *)ourHost
{
    NSString *key;
    NSMutableArray *list = NULL;
    TestSocket *sock = NULL;
    int retry;
    UMSocketError sErr;
    UMHost *server;
    
    do {
        retry = 0;
        key = [self keyWithRemoteHost:host withPort:port enableSSL:ssl withCertificate:certkeyfile withLocalHost:ourHost];
        
        [connPoolLock lock];
        list = connPool[key];
        if (list)
            sock = list[0];
        [connPoolLock unlock];
        
        /*
         * Note: we don't hold conn_pool_lock when we check/destroy/unregister
         *       connection because otherwise we can deadlock! And it's even better
         *       not to delay other threads while we check connection.
         */
        if (sock) 
        {
            /*
             * Check whether the server has closed the connection while
             * it has been in the pool.
             */
            sErr = [sock dataIsAvailable:0];
            if (sErr != UMSocketError_no_error) 
            {
                [logFeed debug:0 inSubsection:@"UMTestHTTP" withText:[NSString stringWithFormat:@"getSocketWith: Server closed connection, destroying it <%@><%@><fd:%d>.\r\n", key, sock, [sock sock]]];
                [sock close];
                retry = 1;
                sock = nil;
            }
            
        }
        
    } while(retry == 1);
    
    if (!sock) 
    {
        sock = [[TestSocket alloc] initWithType:UMSOCKET_TYPE_TCP4ONLY];
        if (sock)
        {
            [sock setUseSsl:ssl];
            
            if ([host compare:@"localhost"] == NSOrderedSame)
            {
                server = [[UMHost alloc] initWithLocalhost];
            }
            else
            {
                server = [[UMHost alloc] initWithName:host];
            }
            
            [sock setRemoteHost:server];
            [sock setRequestedRemotePort:port];
            sErr = [sock bind];
            if (sErr == UMSocketError_no_error)
                sErr = [sock connect];
            else 
                goto error;
        }
        else
            goto error;
        
        if (sock && ssl)
        {
            sErr = [sock initWithSSLWithCertKeyFile:certkeyfile];
            if (sErr != UMSocketError_no_error)
                goto error;
        }
        
        [logFeed info:0 inSubsection:@"UMTestHTTP" withText:[NSString stringWithFormat:@"getSocketWith: Opening connection to `%@:%d' (fd=%d).\r\n", host, port, [sock sock]]];
    } else {
        [logFeed info:0 inSubsection:@"UMTestHTTP" withText:[NSString stringWithFormat:@"getSocketWith: Reusing connection to `%@:%d' (fd=%d).\r\n", host, port, [sock sock]]];
    }
    
    return sock;
    
error:
    [sock close];
    sock = nil;
    return nil;
}
                  
- (void)checkSocket:(UMSocket *)sock withKey:(NSString *)data whenRunStatusIs:(BOOL)running andSockError:(BOOL)error andSockEOF:(BOOL)eof
{
    NSString *key = data;
    
    if (!running) 
    {
        return;
    }
    
    /* check if connection still ok */
    if (error || eof)
    {
        NSMutableArray *list;
        [connPoolLock lock];
        list = connPool[key];
        if ([list indexOfObject:sock] != NSNotFound) {
            /*
             * ok, connection was still within pool. So it's
             * safe to destroy this connection.
             */
            if(sock)
            {
                [list removeObject:sock];
            }
            [sock close];
            sock = nil;
        }
        [connPoolLock unlock];
    }
}
                  
- (void)putSocket:(UMSocket *)sock withRemoteHost:(NSString *)host withPort:(int)port enableSSL:(int)ssl withCertificate:(NSString *)certfile withLocalHost:(NSString *)ourHost
{
    NSString *key;
    NSMutableArray *list;
    
    key = [self keyWithRemoteHost:host withPort:port enableSSL:ssl withCertificate:certfile withLocalHost:ourHost];
    [connPoolLock lock];
    list = connPool[key];
    
    if (!list) {
        list = [[NSMutableArray alloc] init];
        connPool[key] = list;
    }
    
    [list addObject:sock];
    [connPoolLock unlock];
}
                  
@end
                  
@implementation TestSocket

@synthesize useSsl;
                  
- (TestSocket *)init
{
    if((self = [super init]))
    {
#ifdef HAVE_LIBSSL
        if (useSsl)
        {
            SSL_library_init();
            SSL_load_error_strings();
            global_ssl_context = SSL_CTX_new(SSLv23_client_method());
            SSL_CTX_set_mode(global_ssl_context, SSL_MODE_ENABLE_PARTIAL_WRITE | SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER);
            ssl = SSL_new(global_ssl_context);

        }
#endif
    }
    return self;
}

- (void)close
{
    [super close];
}
                
- (int)SSLSmartShutdown
{
    int i;
    int rc = 1;
    
    if (!useSsl)
        return 1;
    
    /*
     * Repeat the calls, because SSL_shutdown internally dispatches through a
     * little state machine. Usually only one or two interation should be
     * needed, so we restrict the total number of restrictions in order to
     * avoid process hangs in case the client played bad with the socket
     * connection and OpenSSL cannot recognize it.
     */
    rc = 0;
    for (i = 0; i < 4 /* max 2x pending + 2x data = 4 */; i++) {
        if ((rc = SSL_shutdown(ssl)))
            break;
    }
    return rc;        
}
                  
- (UMSocketError)initWithSSLWithCertKeyFile:(NSString *)certkey
{
    
    if (!useSsl)
        return 0;
    
    /*
     * The current thread's error queue must be empty before
     * the TLS/SSL I/O operation is attempted, or SSL_get_error()
     * will not work reliably.
     */
    ERR_clear_error();
    
    if (certkey) 
    {
        SSL_use_certificate_file(ssl, [certkey UTF8String], SSL_FILETYPE_PEM);
        SSL_use_PrivateKey_file(ssl, [certkey UTF8String], SSL_FILETYPE_PEM);
        if (SSL_check_private_key(ssl) != 1)
            return -1;
    }
    
    return 0;
}
                  
@end                  


@implementation NSDictionary (HTTPHeader)

- (NSString *)logDescription
{
    NSMutableString *desc;
    id hitem, vitem;
    long i, len;
    NSArray *values;
    NSArray *keys;
    
    desc = [[NSMutableString alloc] init];
    i = 0;
    len = [self count];
    values = [self allValues];
    keys = [self allKeys];
    
    while (i < len)
    {
        vitem = values[i];
        hitem = keys[i];
        ++i;
        [desc appendFormat:@"%@: %@", hitem, vitem];
        if (i < len)
            [desc appendString:@" hend "];
    }
    [desc appendString:@" tend "];
    
    return desc;
}

- (NSMutableArray *) toArray;
{
    NSMutableArray *a;
    id hitem, vitem;
    long i, len;
    NSArray *values;
    NSArray *keys;
    NSString *aitem;
    
    a = [NSMutableArray array];
    i = 0;
    len = [self count];
    values = [self allValues];
    keys = [self allKeys];
    
    while (i < len)
    {
        vitem = values[i];
        hitem = keys[i];
        aitem = [NSString stringWithFormat:@"%@: %@", hitem, vitem];
        [a addObject:aitem];
        ++i;
    }
    
    return a;
}

@end
