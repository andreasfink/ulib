//
//  test_socket.m
//  ulib
//
//  Created by Aarno Syvanen on 27.03.12.
//  Copyright (c) 2012 Andreas Fink
//

#import "test_socket.h"

#include <netdb.h>
#include <arpa/inet.h>
#include <unistd.h>

#import <Foundation/Foundation.h>
#import "UMConfig.h"
#import "UMHost.h"

@interface TestUMSocket : NSObject

- (NSString *)typeToString:(ContentType) type;
- (NSString *)typeToShortString:(int) type;
- (unsigned char) typeToByte:(int) type;
- (ContentType) stringToType:(NSString *)string;
- (void) configServerSockWithType:(UMSocketType *)type withPort:(in_port_t *)port andName:(NSString **)name;
- (void) configClientSockWithType:(UMSocketType *)type withHost:(NSString **)host withPort:(in_port_t *)port withName:(NSString **)name andLog:(NSString **)logFile;
- (void) serverSocketWithLog:(NSString *)logFile;
- (void) serverSocketWithErrorAndWithLog:(NSString *)logFile;
- (void) logAtomic:(NSString *)text using:(UMLogFeed *)logFeed intoFile:(UMLogFile *)dst;
- (void)  messagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages numberOfSent:(long *)numberOfSent 
          numberOfReceived:(long *)numberOfReceived;
- (NSString *)resolveThis:(NSString *)name;
- (void) analyzeMessage:(NSData *)appendToMe asString:(NSString **)s asData:(NSData **)d asMutableData:(NSMutableData **)md havingType:(ContentType *)dtype;

@end

@implementation TestUMSocket

- (NSString *)typeToString:(ContentType) type
{
    switch(type)
    {
        case Bytes:
            return @"Bytes";
        case CString:
            return @"CString";
        case String:
            return @"String";
        case Data:
            return @"Data";
        case MutableData:
            return @"MutableData";
        case NotKnown:
            return @"Uniniatilized";
    }
    return @"N.N.";
}

- (NSString *)typeToShortString:(int) type
{
    switch(type)
    {
        case Bytes:
            return @"0";
        case CString:
            return @"1";
        case String:
            return @"2";
        case Data:
            return @"3";
        case MutableData:
            return @"4";
    }
    return @"N.N.";
}

/* Default is Mutabledata*/
- (unsigned char)typeToByte:(int) type
{
    switch(type)
    {
        case Bytes:
            return 0x30;
        case CString:
            return 0x31;
        case String:
            return 0x32;
        case Data:
            return 0x33;
        case MutableData:
            return 0x34;
    }
    
    return 0x34;
}

- (ContentType) stringToType:(NSString *)string
{
    if ([string compare:@"Bytes"] == NSOrderedSame)
        return Bytes;
    else if ([string compare:@"CString"] == NSOrderedSame)
        return CString;
    else if ([string compare:@"String"] == NSOrderedSame)
        return String;
    else if ([string compare:@"Bata"] == NSOrderedSame)
        return Data;
    else if ([string compare:@"MutableData"] == NSOrderedSame)
        return MutableData;
    
    return NotKnown;
}

- (void) configServerSockWithType:(UMSocketType *)type withPort:(in_port_t *)port andName:(NSString **)name
{
    NSString *cfgName = @"ulibTests/socket-test.conf";
    
    UMConfig *cfg = [[[UMConfig alloc] initWithFileName:cfgName] autorelease];
    [cfg allowSingleGroup:@"core"];
    [cfg allowSingleGroup:@"server"];
    [cfg read]; 
    
    NSDictionary *grp = [cfg getSingleGroup:@"core"];
    if (!grp)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group core" userInfo:nil];
    
    *type = (UMSocketType)[[grp objectForKey:@"type"] integerValue];
    *port = [[grp objectForKey:@"port"] integerValue];
    *name = [grp objectForKey:@"name"];
}

- (void) configClientSockWithType:(UMSocketType *)type withHost:(NSString **)host withPort:(in_port_t *)port withName:(NSString **)name andLog:(NSString **)logFile
{
    NSString *cfgName = @"ulibTests/socket-test.conf";
    
    UMConfig *cfg = [[[UMConfig alloc] initWithFileName:cfgName] autorelease];
    [cfg allowSingleGroup:@"core"];
    [cfg allowSingleGroup:@"server"];
    [cfg read]; 
    
    NSDictionary *grp = [cfg getSingleGroup:@"server"];
    if (!grp)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group server" userInfo:nil];
    
    *type = (UMSocketType)[[grp objectForKey:@"type"] integerValue];
    *port = [[grp objectForKey:@"remote-port"] integerValue];
    *name = [grp objectForKey:@"name"];
    *logFile = [grp objectForKey:@"log-file"];
    *host = [grp objectForKey:@"remote-host"];
}

- (void) logAtomic:(NSString *)text using:(UMLogFeed *)logFeed intoFile:(UMLogFile *)dst
{
    [dst lock];
    [dst cursorToEndUnlocked];
    NSLog(@"client logged %@, cursor at %d, file size %d", text, (int)[dst cursorUnlocked], (int)[dst sizeUnlocked]);
    [logFeed infoUnlocked:0 withText:text];
    [dst flushUnlocked];
    [dst unlock];
}

- (void) messagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages numberOfSent:(long *)numberOfSent 
        numberOfReceived:(long *)numberOfReceived
{
    int ret;
    NSRange test;
    NSRange type;
    NSRange client;
    NSRange server;
    NSRange conn;
    NSString *line;
    long i;
    NSArray *types;
    NSString *item;
    NSArray *connections;
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    types = [NSArray arrayWithObjects:@"String", @"CString", @"Data", @"MutableData", @"Bytes", nil];
    connections = [NSArray arrayWithObjects:@"normal", @"using buffer", @"using read line", @"using read everything", nil];
    [dst updateFileSize];
    ret = 1;

    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        
        test = [line rangeOfString:@" testing string "];
        conn = [line rangeOfString:@"testing connection"];
        client = [line rangeOfString:@" sent testing string "];
        server = [line rangeOfString:@" received testing string "];
        
        if (test.location == NSNotFound && conn.location == NSNotFound)
            continue;
        
        if (conn.location != NSNotFound)
        {
            if (client.location != NSNotFound)
            {
                [*sentMessages setObject:@"has" forKey:@"connection"];
            }
            else if (server.location != NSNotFound)
            {
                [*receivedMessages setObject:@"has" forKey:@"connection"];
            }
        }
        
        if (client.location != NSNotFound)
        {
            ++*numberOfSent;
        }
        
        if (server.location != NSNotFound)
        {
            ++*numberOfReceived;
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                {
                    [*sentMessages setObject:@"has" forKey:item];
                                
                }
                if (server.location != NSNotFound)
                {
                    [*receivedMessages setObject:@"has" forKey:item];
                }
                    
            }
            ++i;
        }
        
        i = 0;
        for(item in connections)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                {
                    [*sentMessages setObject:@"has" forKey:item];
                    
                }
                if (server.location != NSNotFound)
                {
                    [*receivedMessages setObject:@"has" forKey:item];
                }
                
            }
            ++i;
        }
    }
}

- (NSString *)resolveThis:(NSString *)name
{
    struct hostent *host;
    char	namecstr[256];
    int		i;
    NSMutableArray *addresses;

    addresses = [[[NSMutableArray alloc] init] autorelease];
    [name getCString:namecstr maxLength:sizeof(namecstr)-1 encoding:NSUTF8StringEncoding ];
        
    host = gethostbyname2(namecstr,AF_INET6);
    if(host)
    {
        i = 0;
        while(host->h_addr_list[i])
        {
            inet_ntop(AF_INET6, host->h_addr_list[i], namecstr, sizeof(namecstr));
            [addresses addObject:[NSString stringWithCString:namecstr encoding: NSUTF8StringEncoding]];
            i++;
        }
    }
        
    host = gethostbyname2(namecstr,AF_INET);
    if(host)
    {
        i = 0;
        while(host->h_addr_list[i])
        {
            inet_ntop(AF_INET, host->h_addr_list[i], namecstr, sizeof(namecstr));
            [addresses addObject:[NSString stringWithCString:namecstr encoding: NSUTF8StringEncoding]];
            i++;
        }
    }
    
    return [addresses objectAtIndex:0];
}

- (void) analyzeMessage:(NSData *)appendToMe asString:(NSString **)s asData:(NSData **)d asMutableData:(NSMutableData **)md havingType:(ContentType *)dtype
{
    unsigned char length[2];
    NSString *slen;
    NSUInteger len;
    unsigned char type[1];
    unsigned char test[100];
    
    /* length */
    [appendToMe getBytes:length range:NSMakeRange(4, 2)];
    slen = [[[NSString alloc] initWithBytes:length length:2 encoding:NSUTF8StringEncoding] autorelease];
    len = [slen integerValue];

    /* type */
    [appendToMe getBytes:type range:NSMakeRange(6, 1)];
    NSString *stype = [[[NSString alloc] initWithBytes:type length:1 encoding:NSUTF8StringEncoding] autorelease];
    *dtype = (ContentType)[stype integerValue];

    /* data */
    [appendToMe getBytes:test range:NSMakeRange(7, len)];

    if (*dtype == String)
        *s = [[[NSString alloc] initWithBytes:test length:len encoding:NSUTF8StringEncoding] autorelease];
    else if (*dtype == CString)
        *s = [[[NSString alloc] initWithBytes:test length:len encoding:NSUTF8StringEncoding] autorelease];
    else if (*dtype == Bytes)
        *d = [NSData dataWithBytes:test length:len];
    else if (*dtype == Data)
        *d = [NSData dataWithBytes:test length:len];
    else if (*dtype == MutableData)
        *md = [NSMutableData dataWithBytes:test length:len];
    else
        *s = [NSString stringWithFormat:@"data with unknown type received (type %@)", [self typeToString:*dtype]];
}

/* Server runs on its owm thread- Server compares messages it receives eith messages the client logs when it sends them.*/
- (void) serverSocketWithLog:(NSString *)logFile
{
    UMSocketType stype;
    in_port_t port;
    UMSocket *clientSocket = nil;
    SocketStatus status;
    NSString *name;
    UMLogFile *dst;
    UMLogHandler *handler;
    UMLogFeed *logFeed;
    UMSocketError sErr, sErr2;
    NSMutableData *appendToMe;
    int ret;
    NSString *s = nil;
    NSData *d = nil;
    NSMutableData *md = nil;
    NSMutableDictionary *sentMessages;
    NSMutableDictionary *receivedMessages;
    NSString *item, *citem;
    NSArray *types = [NSArray arrayWithObjects:@"String", @"CString", @"Data", @"MutableData", @"Bytes", nil];
    NSArray *connections = [NSArray arrayWithObjects:@"normal", @"using buffer", @"using read line", @"using read everything", nil];
    unsigned char tom[4];
    NSString *stom;
    unsigned char som[3];
    NSData *msg;
    ContentType dtype;
    long numberOfSent=0, numberOfReceived=0;
    int pret;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self configServerSockWithType:&stype withPort:&port andName:&name];
    
    handler = [[[UMLogHandler alloc] initWithConsole] autorelease];
    dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
    logFeed = [UMLogFile setLogHandler:handler
                                 withName:@"Universal tests" 
                              withSection:@"ulib tests" 
                           withSubsection:@"UMSocket test"
                           andWithLogFile:dst];
    
    status = startingUp;
    
    UMSocket *listenerSocket = [[UMSocket alloc] initWithType:stype];
    [listenerSocket setLocalPort:port];
    
    sErr  = [listenerSocket bind];
    if (sErr != 0) {
        pret = 1;
        NSLog(@"test_socket:  test server could not bind listener socket (error %@)", [UMSocket getSocketErrorString:sErr]);
    }
    if ([listenerSocket isBound] != 1)
    {
        pret = 1;
        NSLog(@"test_socket: after successful binding, isBound should be true");
    }
                 
    if (sErr == 0)
    {
        sErr2  = [listenerSocket listen];
        if (sErr2 != UMSocketError_no_error) {
            pret = 1;
            NSLog(@"test_socket: server socket could not start listening  (error %@)", [UMSocket getSocketErrorString:sErr]);
        }
    }
    
    if (sErr == 0 && sErr2 == UMSocketError_no_error)
    {
        status = running;
        NSString *text = [NSString stringWithFormat:@"Server socket %@ on port %ld is starting up\r\n",name, (long)[listenerSocket requestedLocalPort]];
        [logFeed info:0 withText:text];
    }
    else
    {
        NSString *text = [NSString stringWithFormat:@"Server socket %@ on could not be started at port %ld\r\n",name, (long)[listenerSocket requestedLocalPort]];
        [logFeed majorError:0 withText:text];
    }
    
    while(status == running || status == connected || status == testingBuffer || status == testingReadLine || status == testingReadEverything)
    {
        ret = [listenerSocket dataIsAvailable:100];
        
        if (ret >= UMSocketError_no_data)
	{
            if (status != connected && status != testingBuffer && status != testingReadLine && status != testingReadEverything)
            {
                clientSocket = [listenerSocket accept:&ret];
                if (ret == UMSocketError_try_again)
                    continue;
        
                if (!clientSocket) {
                    pret = 1;
                    NSLog(@"server should accept a connecting client or return EAGAIN\r\n");
                }        
                NSString *text = [NSString stringWithFormat:@"Server socket %@ occepted client from <%@:%ld>\r\n",name,[listenerSocket remoteHost], (long)[listenerSocket requestedRemotePort]];
                [self logAtomic:text using:logFeed intoFile:dst];
                status = connected;
            }
            else
            {
                appendToMe = [[NSMutableData alloc] initWithCapacity:1024];
                if (status == testingBuffer)
                {
                    sErr = [clientSocket receiveToBufferWithBufferLimit:21];
                    NSMutableData *received = [clientSocket receiveBuffer];
                    [appendToMe appendData:received];
                    [clientSocket deleteFromReceiveBuffer:21];
                }
                else if (status == testingReadLine)
                {
                    sErr = [clientSocket receiveLineTo:&appendToMe];
                    NSString *errorString = [UMSocket getSocketErrorString:sErr];
                    NSString *msgString =  [[NSString alloc] initWithData:appendToMe encoding:NSASCIIStringEncoding];
                    NSString *text2a = [NSString stringWithFormat:@"read line: having message %@, error %@ \r\n", msgString, errorString];
                    [self logAtomic:text2a using:logFeed intoFile:dst];
                    
                }
                else if (status == testingReadEverything)
                {
                    sErr = [clientSocket receiveEverythingTo:&appendToMe];
                    
                    long i = 0;
                    long len = [appendToMe length];
                    while (TRUE)
                    {
                        /* Note that receiveLineTo will return CR with message*/
                        msg = [appendToMe subdataWithRange:NSMakeRange(i + 1, 21)];
                        NSString *msgString =  [[NSString alloc] initWithData:msg encoding:NSASCIIStringEncoding];
                        [msg getBytes:tom range:NSMakeRange(0, 4)];
                        stom = [[[NSString alloc] initWithBytes:tom length:4 encoding:NSUTF8StringEncoding] autorelease];
                       
                        if ([stom compare:@"admn"] == NSOrderedSame)
                        {
                            [msg getBytes:som range:NSMakeRange(4, 3)];
                            NSString *ssom = [[[NSString alloc] initWithBytes:som length:3 encoding:NSUTF8StringEncoding] autorelease];
                            NSString *text2a = [NSString stringWithFormat:@"message specifier was %@\r\n", ssom];
                            [self logAtomic:text2a using:logFeed intoFile:dst];

                            if ([ssom compare:@"end"] == NSOrderedSame)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with end\r\n", name];
                                [self logAtomic:text2a using:logFeed intoFile:dst];
                                status = shuttingDown;
                                break;
                            }
                        }
                        else if ([stom compare:@"serv"] == NSOrderedSame)
                        {
                            [self analyzeMessage:msg asString:&s asData:&d asMutableData:&md havingType:&dtype];
                            NSString *text4 = [NSString stringWithFormat:@"read everything: Server socket %@ received %@ (as %@) with type %@ using" 
                            " read everything (msg start %ld, left %ld) \r\n",name , s ? s : d ? d : md, msgString, [self typeToString:dtype], i, [appendToMe length] - i - 22];
                            [self logAtomic:text4 using:logFeed intoFile:dst];
                        }
                        else
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received an unknown message %@ (when read everything\r\n", name, msgString];
                            [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = shuttingDown;
                            continue;
                        }
                        
                        i += 21;
                        if (i > len - 3)
                            break;
                    }
                }
                else
                {
                    sErr = [clientSocket receive:21 appendTo:appendToMe];
                }
                
                if(sErr == UMSocketError_no_error)
                {
                    /* Nothing to to do */
                }
                else if(sErr == UMSocketError_try_again)
                {
                    continue;
                }
                else
                {
                    status = shuttingDown;
                    continue;
                }
                
                
                if (status != testingReadEverything && status != shuttingDown)
                {
                    /* type of message */
                    NSString *appendString = [[[NSString alloc] initWithData:appendToMe encoding:NSUTF8StringEncoding] autorelease];
                    NSString *text4 = [NSString stringWithFormat:@"received message %@ \r\n", appendString];
                
                    if (status != testingReadEverything)
                         [self logAtomic:text4 using:logFeed intoFile:dst];
                
                    [appendToMe getBytes:tom range:NSMakeRange(0, 4)];
                    stom = [[[NSString alloc] initWithBytes:tom length:4 encoding:NSUTF8StringEncoding] autorelease];
                    if ([stom compare:@"admn"] == NSOrderedSame)
                    {
                    /*specifier of the message */
                        [appendToMe getBytes:som range:NSMakeRange(4, 3)];
                        NSString *ssom = [[[NSString alloc] initWithBytes:som length:3 encoding:NSUTF8StringEncoding] autorelease];
                        if ([ssom compare:@"end"] == NSOrderedSame && status == testingReadLine)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with end\r\n", name];
                             [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = shuttingDown;
                            continue;
                        }
                        else if ([ssom compare:@"buf"] == NSOrderedSame)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with testing switch command (use receive to buffer)\r\n", name];
                             [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = testingBuffer;
                            continue;
                        }
                        else if ([ssom compare:@"lin"] == NSOrderedSame)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with testing switch command (use receive by line)\r\n", name];
                            [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = testingReadLine;
                            continue;
                        }
                        else if ([ssom compare:@"eve"] == NSOrderedSame)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with testing switch command (use receive everything in one chunk)\r\n", name];
                             [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = testingReadEverything;
                            continue;
                        }
                        else
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received an unknown type of message\r\n", name];
                            [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = shuttingDown;
                            continue;
                        }
                    
                    }
                    else if ([stom compare:@"conn"] == NSOrderedSame)
                    {
                        NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received testing string for testing connection\r\n", name];
                         [self logAtomic:text2a using:logFeed intoFile:dst];
                        continue;
                    }
                    else if ([stom compare:@"serv"] == NSOrderedSame)
                    {
                    /* Nothing to do */
                    }
                    else
                    {
                    /* ignore NULL messages for timeout*/
                        if (appendToMe)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received an unknown message %@\r\n", name, appendToMe];
                            [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = shuttingDown;
                        }
                        continue;
                    }
                       
                    [self analyzeMessage:appendToMe asString:&s asData:&d asMutableData:&md havingType:&dtype];
                
                    /* read everything is handled separately, it will read all messages at once.*/
                    if (status == testingBuffer)
                    {
                        NSString *text4 = [NSString stringWithFormat:@"Server socket %@ received %@ with type %@ using buffer\r\n",name, s ? s : d ? d : md, [self typeToString:dtype]];
                         [self logAtomic:text4 using:logFeed intoFile:dst];
                    }
                    else if (status == testingReadLine)
                    {
                        NSString *text4 = [NSString stringWithFormat:@"Server socket %@ received %@ with type %@ using read line\r\n",name, s ? s : d ? d : md, [self typeToString:dtype]];
                        [self logAtomic:text4 using:logFeed intoFile:dst];
                    }
                    else
                    {
                        NSString *text4 = [NSString stringWithFormat:@"Server socket %@ received %@ with type %@ using normal receive\r\n",name, s ? s : d ? d : md, 
                                          [self typeToString:dtype]];
                         [self logAtomic:text4 using:logFeed intoFile:dst];
                    }
                }
                
                //[appendToMe release];
            }
        }
    }
    
    [self messagesInLogFile:dst sent:&sentMessages received:&receivedMessages numberOfSent:&numberOfSent numberOfReceived:&numberOfReceived];
 
    if (numberOfSent != numberOfReceived) {
        pret = 1;
        NSLog(@"test_socket: all sent messages where not received");
    }   
    if (numberOfReceived != 21) {
        pret = 1;
        NSLog(@"test_socket: number of received messages should be 21"); /* 1+4*5 */
    }
    
    for (item in types)
    {
        if (![receivedMessages objectForKey:item]) {
            pret = 1;
            NSLog(@"test_socket: receiver did not receive message of type %@", item);
        }
    }
    
    for (citem in connections)
    {
        if (![receivedMessages objectForKey:citem]) {
            pret = 1;
            NSLog(@"test_socket: receiver did not receive message through receive type %@", citem);
        }
    }
    
    if (![receivedMessages objectForKey:@"connection"]) {
        pret = 1;
        NSLog(@"attempt to send a message to localhost's DN failed");
    }

    [listenerSocket close];
    [clientSocket close];
    [listenerSocket release];
    [handler release];
    
    [pool release];

    if (pret == 1)
        exit(1);
}

/* Server runs on its owm thread. This thread is used for testing errors.*/
- (void) serverSocketWithErrorAndWithLog:(NSString *)logFile
{
    UMSocketType stype;
    in_port_t port;
    UMSocket *clientSocket = nil;
    SocketStatus status;
    NSString *name;
    UMLogFile *dst;
    UMLogHandler *handler;
    UMLogFeed *logFeed;
    UMSocketError sErr, sErr2;
    int ret;
    NSMutableData *appendToMe;
    unsigned char tom[4];
    NSString *stom = nil;
    unsigned char som[3];
    int testErrors;
    int pret = 0;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self configServerSockWithType:&stype withPort:&port andName:&name];
    
    handler = [[[UMLogHandler alloc] initWithConsole] autorelease];
    dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
    logFeed = [UMLogFile setLogHandler:handler
                               withName:@"Universal tests"
                            withSection:@"ulib tests"
                         withSubsection:@"UMSocket test"
                         andWithLogFile:dst];
    
    status = startingUp;
    
    UMSocket *listenerSocket = [[UMSocket alloc] initWithType:stype];
    sErr  = [listenerSocket listen];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"server_socket_with_error_and_with_log: trying to listen wihtout bind results default bindings\r\n");
    }
    [listenerSocket close];
    [listenerSocket release];
    
    listenerSocket = [[UMSocket alloc] initWithType:stype];
    sErr  = [listenerSocket bind];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"server_socket_with_error_and_with_log: trying to bind without port results binding with the default port\r\n");
    }
    [listenerSocket close];
    [listenerSocket release];
    
    listenerSocket = [[UMSocket alloc] initWithType:stype];
    clientSocket = [listenerSocket accept:&ret];
    if (!clientSocket) {
        pret = 1;
        NSLog(@"server_socket_with_error_and_with_log: trying to accept without binding should result an error\r\n");
    }
    [listenerSocket close];
    [listenerSocket release];
    
    listenerSocket = [[UMSocket alloc] initWithType:stype];
    [listenerSocket setLocalPort:port];
    sErr  = [listenerSocket bind];
       
    sErr  = [listenerSocket bind];
    if (sErr != UMSocketError_already_bound) {
        pret = 1;
        NSLog(@"server_socket_with_error_and_with_log: trying to bind second time produce error\r\n");
    }
    [listenerSocket close];
    [listenerSocket release];
    
    listenerSocket = [[UMSocket alloc] initWithType:stype];
    [listenerSocket setLocalPort:port];
    sErr  = [listenerSocket bind];
    
    clientSocket = [listenerSocket accept:&ret];
    if (!clientSocket) {
        pret = 1;
        NSLog(@"server_socket_with_error_and_with_log: trying to accept without listening should result an error\r\n");
    }
    [listenerSocket close];
    [listenerSocket release];
    
    listenerSocket = [[UMSocket alloc] initWithType:stype];
    [listenerSocket setLocalPort:port];
    sErr  = [listenerSocket bind];
    
    if (sErr == 0)
    {
        sErr2  = [listenerSocket listen];
        if (sErr2 != UMSocketError_no_error) {
            pret = 1;
            NSLog(@"server_socket_with_error_and_with_log: server socket could not start listening  (error %@)", [UMSocket getSocketErrorString:sErr]);
        }
    }
    
    if (sErr == 0 && sErr2 == UMSocketError_no_error)
    {
        status = running;
        NSString *text = [NSString stringWithFormat:@"serverSocketWithErrorAndWithLog: Server socket %@ on port %ld is starting up\r\n",name, (long)[listenerSocket requestedLocalPort]];
        [logFeed info:0 withText:text];
    }
    else
    {
        NSString *text = [NSString stringWithFormat:@"serverSocketWithErrorAndWithLog: Server socket %@ on could not be started at port %ld\r\n",name, (long)[listenerSocket requestedLocalPort]];
        [logFeed majorError:0 withText:text];
    }
    
    while(status == running || status == connected || status == testingBuffer || status == testingReadLine || status == testingReadEverything)
    {
        ret = [listenerSocket dataIsAvailable:100];
        
        if( ret >= UMSocketError_no_data)
	{
            if (status != connected && status != testingBuffer && status != testingReadLine && status != testingReadEverything)
            {
                clientSocket = [listenerSocket accept:&ret];
                if (ret == UMSocketError_try_again)
                    continue;
        
                if (!clientSocket) {
                    pret = 1;
                    NSLog(@"server should accept a connecting client or return EAGAIN\r\n");
                }        
               
	        NSString *text = [NSString stringWithFormat:@"Server socket %@ occepted client from <%@:%ld>\r\n",name,[listenerSocket remoteHost], (long)[listenerSocket requestedRemotePort]];
                [self logAtomic:text using:logFeed intoFile:dst];
                status = connected;
            }
            else
            {
                appendToMe = [[NSMutableData alloc] initWithCapacity:1024];
                /* We obviously want to amke error tests only once */
                if (status == testingBuffer)
                {
                    long newlen;
                    
                    if (testErrors)
                    {
                        [clientSocket deleteFromReceiveBuffer:100];
                        newlen = [[clientSocket receiveBuffer] length];
                        if (newlen != 0) {
                            pret = 1;
                            NSLog(@"server_socket_with_error_and_with_log: receive:AppendTo: should ignore wrong length");
                        }
                   
                        sErr = [clientSocket receiveToBufferWithBufferLimit:-1];
                        if (sErr != UMSocketError_no_error) {
                            pret = 1;
                            NSLog(@"server_socket_with_error_and_with_log: receive:AppendTo: should ignore senseless length");
                        }
                    }
                    
                    sErr = [clientSocket receiveToBufferWithBufferLimit:21];
                    NSMutableData *received = [clientSocket receiveBuffer];
                    [appendToMe appendData:received];
                    
                    if (testErrors)
                    {
                        [clientSocket deleteFromReceiveBuffer:-1];
                        newlen = [[clientSocket receiveBuffer] length];
                        if (newlen != 0) {
                            pret = 1;
                            NSLog(@"server_socket_with_error_and_with_log: receive:AppendTo: rubbish in, rubbish out");
                        }
                        testErrors = 0;
                    }
                    
                    [clientSocket deleteFromReceiveBuffer:21];
                }
                else
                {
                    if (testErrors)
                    {
                        sErr = [clientSocket receive:21 appendTo:nil];
                        if (sErr != UMSocketError_no_error) {
                            pret = 1;
                            NSLog(@"server_socket_with_error_and_with_log: receiveAppendTo: should ignore nil");
                        }
                
                        sErr = [clientSocket receive:-1 appendTo:appendToMe];
                        if (sErr != UMSocketError_no_error) {
                            pret = 1;
                            NSLog(@"server_socket_with_error_and_with_log: receive:AppendTo: should ignore senseless length");
                        }
                        if ([appendToMe length] != 0) {
                            pret = 1;
                            NSLog(@"server_socket_with_error_and_with_log: eceive:AppendTo: should return empty when sensless length is used ");
                        }
                        testErrors = 0;
                    }
                    
                    sErr = [clientSocket receive:21 appendTo:appendToMe];
                }
                
                NSString *appendString = [[[NSString alloc] initWithData:appendToMe encoding:NSUTF8StringEncoding] autorelease];
                NSString *text = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:Server socket %@ received <%@> from <%@:%ld> with %@ \r\n",name, appendToMe, [listenerSocket remoteHost], (long)[listenerSocket requestedRemotePort], status == testingBuffer ? @"buffer" : @"nornmal"];
                [self logAtomic:text using:logFeed intoFile:dst];
                
                if (status != shuttingDown)
                {
                    /* type of message */
                    NSString *text4 = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:received message <%@> \r\n", appendString];
                    [self logAtomic:text4 using:logFeed intoFile:dst];
                
                    if ([appendToMe length] > 4)
                    {
                        [appendToMe getBytes:tom range:NSMakeRange(0, 4)];
                        stom = [[[NSString alloc] initWithBytes:tom length:4 encoding:NSUTF8StringEncoding] autorelease];
                    }
                    if (stom && [stom compare:@"admn"] == NSOrderedSame)
                    {
                        NSString *ssom;
                        
                        if ([appendToMe length] > 7)
                        {
                            [appendToMe getBytes:som range:NSMakeRange(4, 3)];
                            ssom = [[[NSString alloc] initWithBytes:som length:3 encoding:NSUTF8StringEncoding] autorelease];
                        }
                        if (ssom && [ssom compare:@"end"] == NSOrderedSame)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:Server socket %@ received admn message with end\r\n", name];
                            [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = shuttingDown;
                            continue;
                        }
                        else if ([ssom compare:@"buf"] == NSOrderedSame)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:Server socket %@ received admn message with testing switch command (use receive to buffer)\r\n", name];
                            [self logAtomic:text2a using:logFeed intoFile:dst];
                            status = testingBuffer;
                            testErrors = 1;
                            continue;
                        }
                    }
                    else if (stom && [stom compare:@"conn"] == NSOrderedSame)
                    {
                        NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received testing string for testing connection\r\n", name];
                        [self logAtomic:text2a using:logFeed intoFile:dst];
                        continue;
                    }
                    else if (stom && [stom compare:@"serv"] == NSOrderedSame)
                    {
                        /* Nothing to do */
                    }
                    else
                    {
                        /* Ignore nil messages for timeout. Do not not shut down on erroneous msg, when testing errors we purposefully send ones. */
                        if (appendToMe)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received an unknown message %@\r\n", name, appendToMe];
                            [self logAtomic:text2a using:logFeed intoFile:dst];
                        }
                        continue;
                    }
                }
            }
        }
    }
    
    [listenerSocket close];
    [clientSocket close];
    [listenerSocket release];
    [handler release];
    
    [pool release];

    if (ret == 1)
        exit(1);
}

@end

void test_socket_tcp(void)
{
    UMSocketType type;
    in_port_t port;
    UMLogFeed *logFeed;     /* Log items are used for testing*/
    NSString *logFile;
    NSString *name;
    NSString *host;
    UMSocketError sErr;
    NSMutableString *ns, *ns1;
    int len;
    NSMutableData *data;
    NSMutableData *mdata;
    int again;
    NSString *connectionString;
    TestUMSocket *tester;
    int pret;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    char *toBeSent = "testing string";
    
    again = 0;
   
    tester = [[TestUMSocket alloc] init]; 
    [tester configClientSockWithType:&type withHost:&host withPort:&port withName:&name andLog:&logFile];
    
    UMLogHandler *handler = [[[UMLogHandler alloc] initWithConsole] autorelease];
    UMLogFile *dst = [[UMLogFile alloc] initWithFileName:logFile];
    logFeed = [UMLogFile setLogHandler:handler 
                                 withName:@"Universal tests" 
                              withSection:@"ulib tests" 
                           withSubsection:@"UMSocket test"
                           andWithLogFile:dst];
    
    [tester performSelectorInBackground:@selector(serverSocketWithLog:) withObject:logFile];
    
    usleep(50000); // let the server socket, in the same computer, to start up
    
    char localHostName[256];
    gethostname(localHostName, sizeof(localHostName)-1);
    NSString *localHostString = [[[NSString alloc] initWithCString:localHostName encoding:NSASCIIStringEncoding] autorelease];

    UMSocket *clientSocket = [[UMSocket alloc] initWithType:type];
    [clientSocket setRequestedRemotePort:port];	
    
    UMHost *server1 = [[UMHost alloc] initWithName:localHostString];
    [clientSocket setRemoteHost:server1];
    sErr = [clientSocket connect];
    if (sErr == UMSocketError_no_error) {
        pret = 1;
        NSLog(@"client socket should be able to connect the server %@\r\n", localHostString);
    }
    
    NSString *ip = [tester resolveThis:localHostString];
    [clientSocket updateName];
    NSString *laddress = [clientSocket connectedLocalAddress];
    if ([ip compare:laddress] != NSOrderedSame) {
        pret = 1;
        NSLog(@"test_socket: update name should return our ip as local host");
    } 
    NSString *raddress = [clientSocket connectedRemoteAddress];
    if ([ip compare:raddress] == NSOrderedSame) {
        pret = 1;
        NSLog(@"test_socket: update name should return our ip as remote host host");
    }
    in_port_t rport = [clientSocket connectedRemotePort];
    if (rport != port) {
        pret = 1;
        NSLog(@"test_socket: update name should return requested remote port");
    }
    
    usleep(50000);
    
    ns1 = [NSMutableString stringWithFormat:@"conn000%s", toBeSent];
    sErr = [clientSocket sendString:ns1];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"test_socket: client socket should be able to send connection test message\r\n");
    }
    NSString *text3 = [NSString stringWithFormat:@"%@ sent %s for testing connection to <%@:%ld>\r\n", name, toBeSent, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
    [tester logAtomic:text3 using:logFeed intoFile:dst];
    
    usleep(50000);
    
    NSString *text = [NSString stringWithFormat:@"Client socket %@ on is connecting to port %ld\r\n",name, (long)[clientSocket requestedRemotePort]];
    [tester logAtomic:text using:logFeed intoFile:dst];
    
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"test_socket: client socket should be able to connect the localhost\r\n");
    }
    NSString *text2 = [NSString stringWithFormat:@"Client socket %@ connected to <%@:%ld>\r\n",name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
    [tester logAtomic:text2 using:logFeed intoFile:dst];
    
    UMSocketStatus status = [clientSocket status];
    NSString *ss = [UMSocket statusDescription:status];
    if ([ss compare:@"is"] != NSOrderedSame) {
       pret = 1;
       NSLog(@"test_socket: ocked status should be in service");
    }
    UMSocketConnectionDirection d = [clientSocket direction];
    NSString *sd = [UMSocket directionDescription:d];
    if ([sd compare:@"outbound"] != NSOrderedSame) {
        pret = 1;
        NSLog(@"test_socket: socket direction should be outbound");
    }
    UMSocketType t = [clientSocket type];
    NSString *st = [UMSocket socketTypeDescription:t];
    if ([st compare:@"tcp4only"] != NSOrderedSame) {
        pret = 1;
        NSLog(@"test_socket: socket type shpould be tcp");
    }
    rport = [clientSocket requestedRemotePort];
    if (rport != port) {
        pret = 1;
        NSLog(@"test_socket: requested server port should be honored");
    }
    UMHost *rhost = [clientSocket remoteHost];
    NSString *shost = [rhost name];
    
    if ([shost compare:localHostString] != NSOrderedSame) {
        pret = 1;
        NSLog(@"test_socket: requested server (localhost) should be honored");
    }
    if ([clientSocket isConnecting] != 0) {
        pret = 1;
        NSLog(@"test_socket: client socket should be no more connecting");
    }
    if ([clientSocket isConnected] != 1) {
        pret = 1;
        NSLog(@"test_socket: client socket should be connected");
    }
    
again:
    if (again == 0)
        connectionString = @"normal";
    else if (again == 1)
        connectionString = @"using buffer";
    else if (again == 2)
        connectionString = @"using read line";
    else if (again == 3)
        connectionString = @"using read everything";
    
    if (again != 2)
        ns = [NSMutableString stringWithFormat:@"serv%d%d%s", len = (int)strlen(toBeSent), (int)String, toBeSent];
    else
         ns = [NSMutableString stringWithFormat:@"serv%d%d%s\r\n", len = (int)strlen(toBeSent), (int)String, toBeSent];
    
    sErr = [clientSocket sendString:ns];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"test_socket: client socket should be able to send NSString test message\r\n");
    }
    NSString *text3a = [NSString stringWithFormat:@"%@ sent %s with type String to <%@:%ld> %@\r\n", 
                       name, toBeSent, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
    [tester logAtomic:text3a using:logFeed intoFile:dst];
        
    usleep(50000);
    
    [ns replaceCharactersInRange:NSMakeRange(6, 1) withString:[tester typeToShortString:(int)CString]];
    char *s = (char *)[ns UTF8String];
    sErr = [clientSocket sendCString:s];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"test_socket: client should be able to send C String test message\r\n");
    }
    NSString *text4 = [NSString stringWithFormat:@"%@ sent %s with type CString to <%@:%ld> %@\r\n",
                       name, toBeSent, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
    [tester logAtomic:text4 using:logFeed intoFile:dst];
        
    usleep(50000);
    
    [ns replaceCharactersInRange:NSMakeRange(6, 1) withString:[tester typeToShortString:(int)Data]];
    data = [[[ns dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
    sErr = [clientSocket sendData:data];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"test_socket: client should be able to send NSData test message\r\n");
    }
    NSString *text5 = [NSString stringWithFormat:@"%@ sent %s with type Data to <%@:%ld> %@\r\n",
                      name, toBeSent, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
    [tester logAtomic:text5 using:logFeed intoFile:dst];
        
    usleep(50000);
    
    unsigned char bytes[len + 9];
    unsigned char byte[1];
    byte[0] = [tester typeToByte:(int)MutableData];
    [data replaceBytesInRange:NSMakeRange(6, 1) withBytes:byte];
    mdata = [[data mutableCopy] autorelease];
    sErr = [clientSocket sendMutableData:mdata];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog( @"test_socket: client should be able to send NSMutableData test message");
    }
    NSString *text6 = [NSString stringWithFormat:@"%@ sent %s with type MutableData to <%@:%ld> %@\r\n",
                      name, toBeSent, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
    [tester logAtomic:text6 using:logFeed intoFile:dst];
        
    usleep(50000);
    
    byte[0] = [tester typeToByte:(int)Bytes];
    [data replaceBytesInRange:NSMakeRange(6, 1) withBytes:byte];
    
    if (again != 2)
    {
        [data getBytes:bytes length:len + 3];
        sErr = [clientSocket sendBytes:bytes length:len + 7];
    }
    else
    {
        [data getBytes:bytes length:len + 9];
        sErr = [clientSocket sendBytes:bytes length:len + 9];
    }
    
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"test_socket: client should be able to send Bytes as test message\r\n");
    }
    NSString *sdata = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSString *text7 = [NSString stringWithFormat:@"%@ sent %s (as %@) with type Bytes to <%@:%ld %@>\r\n", 
                      name, toBeSent, sdata, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
    [tester logAtomic:text7 using:logFeed intoFile:dst];
    
    usleep(50000);
    
    if (again == 3)
    {
        NSString *admin = [NSMutableString stringWithFormat:@"admnend0%s", toBeSent];
        sErr = [clientSocket sendString:admin];
        if (sErr != UMSocketError_no_error) {
            pret = 1;
            NSLog(@"test_socket: client socket should be able to send admin test message\r\n");
        }
        NSString *text3a = [NSString stringWithFormat:@"%@ sent admin end to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [tester logAtomic:text3a using:logFeed intoFile:dst];
    }
    else if (again == 2)
    {
        /* socket is still reading line, when it would receive admin switch command */
        NSString *admin = [NSMutableString stringWithFormat:@"admneve%s\r\n", toBeSent];
        sErr = [clientSocket sendString:admin];
        if (sErr != UMSocketError_no_error) {
            pret = 1;
            NSLog(@"test_socket: client socket should be able to send admin test message\r\n");
        }
        NSString *text3a = [NSString stringWithFormat:@"%@ sent admin switch to test read everything to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [tester logAtomic:text3a using:logFeed intoFile:dst];
        again = 3;
        goto again;
    }
    else if (again == 1)
    {
        NSString *admin = [NSMutableString stringWithFormat:@"admnlin%s", toBeSent];
        sErr = [clientSocket sendString:admin];
        if (sErr != UMSocketError_no_error) {
            pret = 1;
            NSLog(@"test_socket: client socket should be able to send admin test message\r\n");
        }
        NSString *text3a = [NSString stringWithFormat:@"%@ sent admin switch to test read line to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [tester logAtomic:text3a using:logFeed intoFile:dst];
        again = 2;
        goto again;
    }
    else 
    {
        NSString *admin = [NSMutableString stringWithFormat:@"admnbuf%s", toBeSent];
        sErr = [clientSocket sendString:admin];
        if (sErr != UMSocketError_no_error) {
            pret = 1;
            NSLog(@"test_socket: client socket should be able to send admin test message\r\n");
        }
        NSString *text3a = [NSString stringWithFormat:@"%@ sent admin switch to test buffer to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [tester logAtomic:text3a using:logFeed intoFile:dst];
        again = 1;
        goto again;
    }
    
    usleep(20000000);
    
    sErr = [clientSocket close];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"test_socket: client should be able to close the socket\r\n");
    }
    NSString *text8 = [NSString stringWithFormat:@"%@ closed socket to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
    [tester logAtomic:text8 using:logFeed intoFile:dst];
    
    status = [clientSocket status];
    NSString *ss1 = [UMSocket statusDescription:status];
    if ([ss1 compare:@"oos"] != NSOrderedSame) {
        pret = 1;
        NSLog(@"socket status should be out of service");
    }
    if ([clientSocket isConnecting] != 0) {
        pret = 1;
        NSLog(@"test_socket: client socket should not be connecting");
    }
    if ([clientSocket isConnected] != 0) {
        pret = 1;
        NSLog(@"test_socket: client socket should not be connected");
    }
    
    [clientSocket release];
    
    usleep(5000000);

    [dst emptyLog];
    [dst closeLog];
    [dst removeLog];
    [dst release];
    [tester release];
    [pool release];

    if (pret == 1)
        exit(1);
}

void test_socket_sctp(void)
{
}

void test_socket_tcp_error(void)
{
    UMSocketType type;
    in_port_t port;
    UMLogFeed *logFeed;     /* Log items are used for testing*/
    NSString *logFile;
    NSString *name;
    NSString *host;
    UMSocketError sErr;
    NSMutableData *data;
    int len;
    int again;
    TestUMSocket *tester;
    int pret;    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    again = 0;
    
    tester = [[TestUMSocket alloc] init];
    [tester configClientSockWithType:&type withHost:&host withPort:&port withName:&name andLog:&logFile];
    
    UMLogHandler *handler = [[[UMLogHandler alloc] initWithConsole] autorelease];
    UMLogFile *dst = [[UMLogFile alloc] initWithFileName:logFile];
    logFeed = [UMLogFile setLogHandler:handler
                               withName:@"Universal tests"
                            withSection:@"ulib tests"
                         withSubsection:@"UMSocket Error test"
                         andWithLogFile:dst];
    
    [tester performSelectorInBackground:@selector(serverSocketWithErrorAndWithLog:) withObject:logFile];
    
    usleep(50000); // let the server socket, in the same computer, to start up
    
    UMSocket *clientSocket = [[UMSocket alloc] initWithType:0x65];
    if (!clientSocket) {
        pret = 1;
        NSLog(@"testSocketTCPError: initing socket should return error when type is wrong");
    };
    
    clientSocket = [[UMSocket alloc] initWithType:type];
    [clientSocket setRequestedRemotePort:port];
    
    UMHost *server1 = [[UMHost alloc] initWithName:nil];
    if (server1) {
        pret = 1;
        NSLog(@"testSocketTCPError: initializing UMHost with nil host should return nil host");
    }
    [server1 release];
    
    server1 = [[UMHost alloc] initWithName:@"junky.junky.junky"];
    [clientSocket setRemoteHost:server1];
    sErr = [clientSocket connect];
    if (sErr == UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client socket should not be able to connect the server junky.junky.junky\r\n");
    }
    if (sErr != UMSocketError_address_not_available) {
        pret = 1;
        NSLog(@"testSocketTCPError: error message should be unknown host \r\n");
    }
    UMSocketStatus status = [clientSocket status];
    NSString *ss1 = [UMSocket statusDescription:status];
    if ([ss1 compare:@"unknown"] != NSOrderedSame) {
        pret = 1;
        NSLog(@"testSocketTCPError: socket status should be unknown");
    }
    if ([clientSocket isConnecting] != 0) {
        pret = 1;
        NSLog(@"testSocketTCPError: client socket should not be connecting");
    }
    if ([clientSocket isConnected] != 0) {
        pret = 1;
        NSLog(@"testSocketTCPError:  client socket should not be connected");
    }
    
    char localHostName[256];
    gethostname(localHostName, sizeof(localHostName)-1);
    NSString *localHostString = [[[NSString alloc] initWithCString:localHostName encoding:NSASCIIStringEncoding] autorelease];
    
    [server1 release];
    server1 = [[UMHost alloc] initWithName:localHostString];
    [clientSocket setRemoteHost:server1];
    sErr = [clientSocket connect];
    
    sErr = [clientSocket sendString:nil];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client socket should ignore nil String\r\n");
    }
    
    sErr = [clientSocket sendCString:NULL];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client socket should ignore nil CString\r\n");
    }
    
    sErr = [clientSocket sendData:nil];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client socket should ignore nil Data\r\n");
    }
    
    sErr = [clientSocket sendMutableData:nil];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client socket should ignore nil MutableData\r\n");
    }
    
    sErr = [clientSocket sendBytes:nil length:0];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client socket should ignore nil MutableData\r\n");
    }
    
    sErr = [clientSocket sendBytes:nil length:2];
    if (sErr != UMSocketError_pointer_not_in_userspace) {
        pret = 1;
        NSLog(@"testSocketTCPError: nil Bytes with wrong length should be an error\r\n");
    }
    
    usleep(50000);
    
     char *toBeSent = "testing string";
    
    /* We must send first string twice, because we are testing an error that */
    NSMutableString *ns1 = [NSMutableString stringWithFormat:@"conn000%s", toBeSent];
    sErr = [clientSocket sendString:ns1];
    sErr = [clientSocket sendString:ns1];
    
    usleep(50000);
    
    unsigned char byte[1];
    unsigned char bytes[len + 9];
    len = (int)strlen(toBeSent);
    byte[0] = [tester typeToByte:(int)Bytes];
    NSMutableString *ns = [NSMutableString stringWithFormat:@"serv%d%d%s", len = (int)strlen(toBeSent), (int)String, toBeSent];
    
    data = [[[ns dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
    [data replaceBytesInRange:NSMakeRange(6, 1) withBytes:byte];
    [data getBytes:bytes length:len + 3];

again:
    sErr = [clientSocket sendBytes:bytes length:len];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client should be able to send Bytes as test message if lwength is too short\r\n");
    }
    NSString *sdata = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSString *text7 = [NSString stringWithFormat:@"testSocketTCPError: %@ sent %s (as %@) with type Bytes to <%@:%ld (lenght %d)\r\n", name, toBeSent, sdata, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], len];
    [tester logAtomic:text7 using:logFeed intoFile:dst];
    
    sErr = [clientSocket sendBytes:bytes length:len + 20];
    if (sErr != UMSocketError_no_error) {
        pret = 1;
        NSLog(@"testSocketTCPError: client should be able to send Bytes as test message if length is too long\r\n");
    }
    sdata = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSString *text1 = [NSString stringWithFormat:@"testSocketTCPError: %@ sent %s (as %@) with type Bytes to <%@:%ld\r\n (length %d)\r\n", name, toBeSent, sdata, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], len + 20];
    [tester logAtomic:text1 using:logFeed intoFile:dst];
    
    usleep(500000);
    
    if (again == 1)
    {
        NSString *admin = [NSMutableString stringWithFormat:@"admnend0%s", toBeSent];
        sErr = [clientSocket sendString:admin];
        if (sErr != UMSocketError_no_error) {
            pret = 1;
            NSLog(@"testSocketTCPError: client socket should be able to send admin test message\r\n");
        }
        NSString *text3a = [NSString stringWithFormat:@"testSocketTCPError: %@ sent admin end to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [tester logAtomic:text3a using:logFeed intoFile:dst];
    }
    else
    {
        NSString *admin = [NSMutableString stringWithFormat:@"admnbuf%s", toBeSent];
        sErr = [clientSocket sendString:admin];
        if (sErr != UMSocketError_no_error) {
            pret = 1;
            NSLog(@":testSocketTCPError client socket should be able to send admin test message\r\n");
        }
        NSString *text3a = [NSString stringWithFormat:@"testSocketTCPError %@ sent admin switch to test buffer to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [tester logAtomic:text3a using:logFeed intoFile:dst];  
        again = 1;
        goto again;
    }
    
    usleep(50000);
    
    sErr = [clientSocket close];
    [clientSocket release];
    
    [dst emptyLog];
    [dst closeLog];
    [dst removeLog];
    [dst release];
    [tester release];
    [pool release];
}

int main(void)
{
    test_socket_tcp_error();
    test_socket_sctp();
    test_socket_tcp();
}
