//
//  TestUmSocket.m
//  ulib
//
//  Created by Aarno Syvänen on 27.03.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUmSocket.h"

#include <netdb.h>
#include <arpa/inet.h>

#import <Foundation/Foundation.h>
#import "UMConfig.h"
#import "UMHost.h"
#import "NSMutableString+UMHTTP.h"

@implementation TestUMSocket

@synthesize status;
@synthesize received;
@synthesize sent;

- (void)setUp
{
    [super setUp];
    received = 0;
    sent = 0;
}

- (void)tearDown
{
    [super tearDown];
}

+ (NSString *)typeToString:(ContentType)type
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

+ (NSString *)typeToShortString:(int)type
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
+ (unsigned char)typeToByte:(int)type
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

+ (ContentType)stringToType:(NSString *)string
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

+ (void)configServerSockWithType:(UMSocketType *)type andPort:(in_port_t *)port andName:(NSString **)name
{
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString *cfgName = [thisBundle pathForResource:@"socket-test" ofType:@"conf"];

    UMConfig *cfg = [[UMConfig alloc] initWithFileName:cfgName];
    [cfg allowSingleGroup:@"core"];
    [cfg allowSingleGroup:@"server"];
    [cfg read]; 
    
    NSDictionary *grp = [cfg getSingleGroup:@"core"];
    if (!grp)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group core" userInfo:nil];
    
    *type = (UMSocketType)[grp[@"type"] integerValue];
    *port = [grp[@"port"] integerValue];
    *name = grp[@"name"];
}

+ (void)configClientSockWithType:(UMSocketType *)type andHost:(NSString **)host andPort:(in_port_t *)port andName:(NSString **)name andLogFile:(NSString **)logFile
{

    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString *cfgName = [thisBundle pathForResource:@"socket-test" ofType:@"conf"];

    UMConfig *cfg = [[UMConfig alloc] initWithFileName:cfgName];
    [cfg allowSingleGroup:@"core"];
    [cfg allowSingleGroup:@"server"];
    [cfg read]; 
    
    NSDictionary *grp = [cfg getSingleGroup:@"server"];
    if (!grp)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group server" userInfo:nil];
    
    *type = (UMSocketType)[grp[@"type"] integerValue];
    *port = [grp[@"remote-port"] integerValue];
    *name = grp[@"name"];
    *logFile = grp[@"log-file"];
    *host = grp[@"remote-host"];
}

+ (void)logAtomic:(NSString *)text toLog:(UMLogFeed *)_logFeed atFile:(UMLogFile *)dst
{
    @synchronized(dst)
    {
        [_logFeed info:0 withText:text];
        [dst flushUnlocked];
    }
}

+ (void) messagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived;
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
    NSRange clientMessage;
    NSRange serverMessage;
    
    *sentMessages = [NSMutableDictionary dictionary];
    *receivedMessages = [NSMutableDictionary dictionary];
    types = @[@"String", @"CString", @"Data", @"MutableData", @"Bytes"];
    connections = @[@"normal", @"using buffer", @"using read line", @"using read everything"];
    [dst updateFileSize];
    ret = 1;
    *numberOfSent = 0;
    *numberOfReceived = 0;

    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        
        test = [line rangeOfString:@" testing string "];
        conn = [line rangeOfString:@"testing connection"];
        client = [line rangeOfString:@" sent testing string "];
        server = [line rangeOfString:@" received testing string "];
        clientMessage = [line rangeOfString:@"sent testing string (as"];
        serverMessage = [line rangeOfString:@"received testing string (as"];
        
        if (test.location == NSNotFound && conn.location == NSNotFound)
            continue;
        
        if (clientMessage.location != NSNotFound)
        {
            NSRange paranthesis = [line rangeOfString:@")"];
            if (paranthesis.location != NSNotFound)
            {
                NSMutableString *message = [[line substringWithRange:NSMakeRange(clientMessage.location + 23, paranthesis.location - clientMessage.location - 23)] mutableCopy];
                [message stripBlanks];
                NSRange using = [line rangeOfString:@"using"];
                NSString *usingString = [line substringFromIndex:using.location + 6];
                [message appendFormat:@" with %@", usingString];
                [message replaceOccurrencesOfString:@"\r" withString:@"CR" options:NSLiteralSearch range:NSMakeRange(0, [message length])];
                [message replaceOccurrencesOfString:@"\n" withString:@"LF" options:NSLiteralSearch range:NSMakeRange(0, [message length])];
                (*sentMessages)[message] = @"has";
                ++*numberOfSent;
            }
        }
        
        if (serverMessage.location != NSNotFound)
        {
            NSRange paranthesis = [line rangeOfString:@")" options:NSLiteralSearch range:NSMakeRange(serverMessage.location + 27, [line length] - serverMessage.location - 27)];
            if (paranthesis.location != NSNotFound)
            {
                NSMutableString *message = [[line substringWithRange:NSMakeRange(serverMessage.location + 27, paranthesis.location - serverMessage.location - 27)] mutableCopy];
                [message stripBlanks];
                NSRange using = [line rangeOfString:@"using"];
                NSString *usingString = [line substringFromIndex:using.location + 6];
                [message appendFormat:@" with %@", usingString];
                [message replaceOccurrencesOfString:@"\r" withString:@"CR" options:NSLiteralSearch range:NSMakeRange(0, [message length])];
                [message replaceOccurrencesOfString:@"\n" withString:@"LF" options:NSLiteralSearch range:NSMakeRange(0, [message length])];
                (*receivedMessages)[message] = @"has";
                ++*numberOfReceived;
            }
        }
        
        if (conn.location != NSNotFound)
        {
            if (client.location != NSNotFound)
            {
                (*sentMessages)[@"connection"] = @"has";
            }
            else if (server.location != NSNotFound)
            {
                (*receivedMessages)[@"connection"] = @"has";
            }
        }
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (client.location != NSNotFound)
                {
                    (*sentMessages)[item] = @"has";
                                
                }
                if (server.location != NSNotFound)
                {
                    (*receivedMessages)[item] = @"has";
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
                    (*sentMessages)[item] = @"has";
                    
                }
                if (server.location != NSNotFound)
                {
                    (*receivedMessages)[item] = @"has";
                }
                
            }
            ++i;
        }
    }
}

+ (NSString *)resolveThis:(NSString *)name
{
    struct hostent *host;
    char	namecstr[256];
    int		i;
    NSMutableArray *addresses;

    addresses = [[NSMutableArray alloc] init];
    [name getCString:namecstr maxLength:sizeof(namecstr)-1 encoding:NSUTF8StringEncoding ];
        
    host = gethostbyname2(namecstr,AF_INET6);
    if(host)
    {
        i = 0;
        while(host->h_addr_list[i])
        {
            inet_ntop(AF_INET6, host->h_addr_list[i], namecstr, sizeof(namecstr));
            [addresses addObject:@(namecstr)];
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
            [addresses addObject:@(namecstr)];
            i++;
        }
    }
    
    return addresses[0];
}

+ (void)analyzeMessage:(NSData *)appendToMe givingString:(NSString **)s orData:(NSData **)d orMutableData:(NSMutableData **)md andType:(ContentType *)dtype
{
    unsigned char length[2];
    NSString *slen;
    NSUInteger len;
    unsigned char type[1];
    unsigned char test[100];
    
    /* length */
    [appendToMe getBytes:length range:NSMakeRange(4, 2)];
    slen = [[NSString alloc] initWithBytes:length length:2 encoding:NSUTF8StringEncoding];
    len = [slen integerValue];

    /* type */
    [appendToMe getBytes:type range:NSMakeRange(6, 1)];
    NSString *stype = [[NSString alloc] initWithBytes:type length:1 encoding:NSUTF8StringEncoding];
    *dtype = (ContentType)[stype integerValue];

    /* data */
    [appendToMe getBytes:test range:NSMakeRange(7, len)];

    if (*dtype == String)
        *s = [[NSString alloc] initWithBytes:test length:len encoding:NSUTF8StringEncoding];
    else if (*dtype == CString)
        *s = [[NSString alloc] initWithBytes:test length:len encoding:NSUTF8StringEncoding];
    else if (*dtype == Bytes)
        *d = [NSData dataWithBytes:test length:len];
    else if (*dtype == Data)
        *d = [NSData dataWithBytes:test length:len];
    else if (*dtype == MutableData)
        *md = [NSMutableData dataWithBytes:test length:len];
    else
        *s = [NSString stringWithFormat:@"data with unknown type received (type %@)", [TestUMSocket typeToString:*dtype]];
}

- (int)handleMessage:(NSData *)msg withLogFeed:(UMLogFeed *)_logFeed withLogFile:(UMLogFile *)dst withName:(NSString *)name
{
    unsigned char tom[4];
    NSString *stom;
    unsigned char som[3];
    NSString *s;
    NSData *d;
    NSMutableData *md;
    ContentType dtype;
    NSString *msgString =  [[NSString alloc] initWithData:msg encoding:NSASCIIStringEncoding];
    [msg getBytes:tom range:NSMakeRange(0, 4)];
    stom = [[NSString alloc] initWithBytes:tom length:4 encoding:NSUTF8StringEncoding];

    if ([stom compare:@"admn"] == NSOrderedSame)
    {
        [msg getBytes:som range:NSMakeRange(4, 3)];
        NSString *ssom = [[NSString alloc] initWithBytes:som length:3 encoding:NSUTF8StringEncoding];
        NSString *text2a = [NSString stringWithFormat:@"message specifier was %@\r\n", ssom];
        [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
    
        if ([ssom compare:@"end"] == NSOrderedSame)
        {
            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with end\r\n", name];
            [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
            status = shuttingDown;
            return -1;
        }
    }
    else if ([stom compare:@"serv"] == NSOrderedSame)
    {
        NSString *text4 = nil;
        [TestUMSocket analyzeMessage:msg givingString:&s orData:&d orMutableData:&md andType:&dtype];
        if (s)
        {
            text4 = [NSString stringWithFormat:@"read everything: Server socket %@ received %@ with type %@\r\n",name , s, [TestUMSocket typeToString:dtype]];
        }
        else if (d || md)
        {
            NSString *dataString;
            if (d)
            {
                dataString = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
            }
            else if (md)
            {
                dataString = [[NSString alloc] initWithData:md encoding:NSUTF8StringEncoding];
            }
            text4 = [NSString stringWithFormat:@"read everything: Server socket %@ received %@ with type %@\r\n",name , dataString, [TestUMSocket typeToString:dtype]];
        }
        [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
    }
    else
    {
        NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received an unknown message <%@> (when read everything\r\n", name, msgString];
        [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
        status = shuttingDown;
        return 0;
    }
    return 0;
}

/* Server runs on its owm thread- Server compares messages it receives eith messages the client logs when it sends them.*/
- (void)serverSocketWithLog:(UMLogFile *)dst
{
    UMSocketType stype;
    in_port_t port;
    UMSocket *clientSocket = nil;
    NSString *name;
    UMLogHandler *handler;
    UMLogFeed *_logFeed;
    UMSocketError sErr, sErr2;
    NSMutableData *appendToMe;
    int ret;
    NSString *s = nil;
    NSData *d = nil;
    NSMutableData *md = nil;
    NSMutableDictionary *sentMessages;
    NSMutableDictionary *receivedMessages;
    NSString *item, *citem;
    NSArray *types = @[@"String", @"CString", @"Data", @"MutableData", @"Bytes"];
    NSArray *connections = @[@"normal", @"using buffer", @"using read line", @"using read everything"];
    unsigned char tom[4];
    NSString *stom;
    unsigned char som[3];
    NSData *msg;
    ContentType dtype;
    long numberOfSent=0, numberOfReceived=0;
    
    @autoreleasepool
    {
        startupDone = NO;
        status = notRunning;
        
        [TestUMSocket configServerSockWithType:&stype
                                       andPort:&port
                                       andName:&name];
        
        handler = [[UMLogHandler alloc] initWithConsole];
        _logFeed = [UMLogFile setLogHandler:handler
                                     withName:@"Universal tests" 
                                  withSection:@"ulib tests" 
                               withSubsection:@"UMSocket test"
                               andWithLogFile:dst];
        
        status = startingUp;
        
        UMSocket *listenerSocket = [[UMSocket alloc] initWithType:stype];
        [listenerSocket setLocalPort:port];
        
        sErr  = [listenerSocket bind];
        XCTAssertTrue(sErr == 0, @"TestUmSocket:  test server could not bind listener socket (error %@)", [UMSocket getSocketErrorString:sErr]);
        XCTAssertTrue([listenerSocket isBound] == 1, @"TestUmSocket: after successful binding, isBound should be true");
                     
        if (sErr == 0)
        {
            sErr2  = [listenerSocket listen];
            XCTAssertTrue(sErr2 == UMSocketError_no_error, @"TestUmSocket: server socket could not start listening  (error %@)", [UMSocket getSocketErrorString:sErr]);
        }
        
        if (sErr == 0 && sErr2 == UMSocketError_no_error)
        {
            status = running;
            NSString *text = [NSString stringWithFormat:@"Server socket %@ on port %ld is starting up\r\n",name, (long)[listenerSocket requestedLocalPort]];
            [_logFeed info:0 withText:text];
        }
        else
        {
            NSString *text = [NSString stringWithFormat:@"Server socket %@ on could not be started at port %ld\r\n",name, (long)[listenerSocket requestedLocalPort]];
            [_logFeed majorError:0 withText:text];
        }
        
        startupDone = YES;
        
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
                    
                    XCTAssertNotNil(clientSocket, @"server should accept a connecting client or return EAGAIN\r\n");
			        NSString *text = [NSString stringWithFormat:@"Server socket %@ occepted client from <%@:%ld>\r\n",name,[listenerSocket remoteHost], (long)[listenerSocket requestedRemotePort]];
                    [TestUMSocket logAtomic:text toLog:_logFeed atFile:dst];
                    status = connected;
                }
                else
                {
                    appendToMe = [[NSMutableData alloc] initWithCapacity:1024];
                    if (status == testingBuffer)
                    {
                        sErr = [clientSocket receiveToBufferWithBufferLimit:21];
                        NSMutableData *ourReceived = [clientSocket receiveBuffer];
                        [appendToMe appendData:ourReceived];
                        [self handleMessage:appendToMe withLogFeed:_logFeed withLogFile:dst withName:name];
                        [clientSocket deleteFromReceiveBuffer:21];
                    }
                    else if (status == testingReadLine)
                    {
                        sErr = [clientSocket receiveLineToCRLF:&appendToMe];
                        [self handleMessage:appendToMe withLogFeed:_logFeed withLogFile:dst withName:name];
                        NSMutableData *ourReceived = [clientSocket receiveBuffer];
#pragma unused(ourReceived)
                    }
                    else if (status == testingReadEverything)
                    {
                        sErr = [clientSocket receiveEverythingTo:&appendToMe];
                        
                        long i = 0;
                        long len = [appendToMe length];
                        while (TRUE)
                        {
                            msg = [appendToMe subdataWithRange:NSMakeRange(i, 21)];
                            ret = [self handleMessage:msg withLogFeed:_logFeed withLogFile:dst withName:name];
                            if (ret == -1)
                                break;
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
                    
                    
                    if (status != shuttingDown)
                    {
                        /* type of message */
                        NSString *appendString = [[NSString alloc] initWithData:appendToMe encoding:NSUTF8StringEncoding];
                        NSString *text4 = [NSString stringWithFormat:@"received message %@ \r\n", appendString];
                    
                        if (status != testingReadEverything)
                            [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
                    
                        [appendToMe getBytes:tom range:NSMakeRange(0, 4)];
                        stom = [[NSString alloc] initWithBytes:tom length:4 encoding:NSUTF8StringEncoding];
                        if ([stom compare:@"admn"] == NSOrderedSame)
                        {
                            /*specifier of the message */
                            [appendToMe getBytes:som range:NSMakeRange(4, 3)];
                            NSString *ssom = [[NSString alloc] initWithBytes:som length:3 encoding:NSUTF8StringEncoding];
                            if ([ssom compare:@"end"] == NSOrderedSame && status == testingReadLine)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with end\r\n", name];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = shuttingDown;
                                continue;
                            }
                            else if ([ssom compare:@"buf"] == NSOrderedSame)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with testing switch command (use receive to buffer)\r\n", name];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = testingBuffer;
                                continue;
                            }
                            else if ([ssom compare:@"lin"] == NSOrderedSame)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with testing switch command (use receive by line)\r\n", name];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = testingReadLine;
                                continue;
                            }
                            else if ([ssom compare:@"eve"] == NSOrderedSame)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received admn message with testing switch command (use receive everything in one chunk)\r\n", name];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = testingReadEverything;
                                continue;
                            }
                            else
                            {
                                NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received an unknown type of message\r\n", name];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = shuttingDown;
                                continue;
                            }
                        
                        }
                        else if ([stom compare:@"conn"] == NSOrderedSame)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received testing string for testing connection\r\n", name];
                            [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
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
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = shuttingDown;
                            }
                            continue;
                        }
                           
                        [TestUMSocket analyzeMessage:appendToMe givingString:&s orData:&d orMutableData:&md andType:&dtype];
                        
                        if (status == connected)
                        {
                            ++received;
                            NSString *text4 = [NSString stringWithFormat:@"Server socket %@ received %@ (as %@) with type %@ using normal receiver\r\n",name, s ? s : d ? d : md, appendString, [TestUMSocket typeToString:dtype]];
                            [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
                        }
                        else if (status == testingBuffer)
                        {
                            ++received;
                            NSString *text4 = [NSString stringWithFormat:@"Server socket %@ received %@ (as %@) with type %@ using buffer\r\n",name, s ? s : d ? d : md, appendString, [TestUMSocket typeToString:dtype]];
                            [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
                        }
                        else if (status == testingReadLine)
                        {
                            ++received;
                            NSString *text4 = [NSString stringWithFormat:@"Server socket %@ received %@ (as %@) with type %@ using read line\r\n",name, s ? s : d ? d : md, appendString, [TestUMSocket typeToString:dtype]];
                            [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
                        }
                        else if (status == testingReadEverything)
                        {
                            received += 5;      // everything in one chunk
                            NSString *text4 = [NSString stringWithFormat:@"Server socket %@ received %@ (as %@) with type %@ using read everything\r\n",name, s ? s : d ? d : md, appendString, [TestUMSocket typeToString:dtype]];
                            [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
                        }
                    }
                }
            }
        }
        
        [dst flush];
        [TestUMSocket messagesInLogFile:dst sent:&sentMessages received:&receivedMessages messagesSent:&numberOfSent messagesReceived:&numberOfReceived];
        
        XCTAssertTrue(numberOfSent == numberOfReceived + 4, @"TestUmSocket: all sent messages where not received (sent %ld, received %ld), note that one test case is receiving 5 messages in chunck", numberOfSent, numberOfReceived);
        XCTAssertTrue(numberOfSent == 20, @"TestUmSocket: number of sent messages should be 20");
        XCTAssertTrue(numberOfReceived == 16, @"TestUmSocket: number of received messages should be 16"); /* 3*5+1, fourth batch of messages sent in one chunk */
        for (item in types)
        {
            XCTAssertNotNil(receivedMessages[item], @"TestUmSocket: receiver did not receive message of type %@", item);
        }
        
        for (citem in connections)
        {
            XCTAssertNotNil(receivedMessages[citem], @"TestUmSocket: receiver did not receive message through receive type %@", citem);
        }
        
        XCTAssertNotNil(receivedMessages[@"connection"], @"attempt to send a message to localhost's DN failed");

        [listenerSocket close];
        [clientSocket close];
        status = shutDown;
    }
}

+ (NSMutableData *)readFromSocket:(UMSocket *)clientSocket withFixedLength:(BOOL)useFixed
{
    UMSocketError sErr;
    NSMutableData *appendToMe = [NSMutableData data];
    BOOL packetStartAtStart;
    static NSMutableData *testBuffer = nil;
    
    if (!testBuffer)
        testBuffer = [NSMutableData data];
    
    if (useFixed)
    {
        sErr = [clientSocket receive:21 appendTo:testBuffer];
    }
    else
    {
        sErr = [clientSocket receiveToBufferWithBufferLimit:21];
        NSMutableData *received = [clientSocket receiveBuffer];
        [testBuffer appendData:received];
    }
    
//    NSString *appendString = [[NSString alloc] initWithData:testBuffer encoding:NSUTF8StringEncoding];

    NSData *firstFour = [testBuffer subdataWithRange:NSMakeRange(0, 4)];
    NSString *firstFourString = [[NSString alloc] initWithData:firstFour
                                                   encoding:NSUTF8StringEncoding];
    packetStartAtStart = [firstFourString compare:@"admn"] == NSOrderedSame || [firstFourString compare:@"serv"] == NSOrderedSame || [firstFourString compare:@"conn"] == NSOrderedSame;
    if (packetStartAtStart)
    {
        NSData *connData = [@"conn" dataUsingEncoding:NSUTF8StringEncoding];
        NSData *servData = [@"serv" dataUsingEncoding:NSUTF8StringEncoding];
        NSData *admnData = [@"admn" dataUsingEncoding:NSUTF8StringEncoding];
        NSRange conn = [testBuffer rangeOfData:connData options:NSDataSearchBackwards range:NSMakeRange(1, [testBuffer length] - 1)];
        NSRange serv = [testBuffer rangeOfData:servData options:NSDataSearchBackwards range:NSMakeRange(1, [testBuffer length] - 1)];
        NSRange admn = [testBuffer rangeOfData:admnData options:NSDataSearchBackwards range:NSMakeRange(1, [testBuffer length] - 1)];
        NSRange conn2, serv2, admn2;
        
        /* Value of NSNotFound is NSIntegerMax */
        long first = conn.location;
        if (serv.location < first)
            first = serv.location;
        if (admn.location < first)
            first = admn.location;
        
        if (first != NSNotFound)
        {
            conn2 = [testBuffer rangeOfData:connData options:NSDataSearchBackwards range:NSMakeRange(first + 1, [testBuffer length] - first - 1)];
            serv2 = [testBuffer rangeOfData:servData options:NSDataSearchBackwards range:NSMakeRange(first + 1, [testBuffer length] - first - 1)];
            admn2 = [testBuffer rangeOfData:admnData options:NSDataSearchBackwards range:NSMakeRange(first + 1, [testBuffer length] - first - 1)];
        }
        
        if (conn.location != NSNotFound || serv.location != NSNotFound || admn.location != NSNotFound)
        {
            if (conn.location != NSNotFound)
            {
                appendToMe = [[testBuffer subdataWithRange:NSMakeRange(0, conn.location)] mutableCopy];
                [testBuffer replaceBytesInRange:NSMakeRange(0, conn.location) withBytes:nil length:0];
            }
            else if (serv.location != NSNotFound)
            {
                appendToMe = [[testBuffer subdataWithRange:NSMakeRange(0, serv.location)] mutableCopy];
                [testBuffer replaceBytesInRange:NSMakeRange(0, serv.location) withBytes:nil length:0];
            }
            else if (admn.location != NSNotFound)
            {
                appendToMe = [[testBuffer subdataWithRange:NSMakeRange(0, admn.location)] mutableCopy];
                [testBuffer replaceBytesInRange:NSMakeRange(0, admn.location) withBytes:nil length:0];
            }
        }
        else
        {
            appendToMe = [[testBuffer subdataWithRange:NSMakeRange(0, 21)] mutableCopy];
            [testBuffer replaceBytesInRange:NSMakeRange(0, 21) withBytes:nil length:0];
        }
    }
    else
    {
        NSData *connData = [@"conn" dataUsingEncoding:NSUTF8StringEncoding];
        NSData *servData = [@"serv" dataUsingEncoding:NSUTF8StringEncoding];
        NSData *admnData = [@"admn" dataUsingEncoding:NSUTF8StringEncoding];
        NSRange conn = [testBuffer rangeOfData:connData options:NSDataSearchBackwards range:NSMakeRange(0, [testBuffer length])];
        NSRange serv = [testBuffer rangeOfData:servData options:NSDataSearchBackwards range:NSMakeRange(0, [testBuffer length])];
        NSRange admn = [testBuffer rangeOfData:admnData options:NSDataSearchBackwards range:NSMakeRange(0, [testBuffer length])];
        NSRange conn2, serv2, admn2;
    
        /* Value of NSNotFound is NSIntegerMax */
        long first = conn.location;
        if (serv.location < first)
            first = serv.location;
        if (admn.location < first)
            first = admn.location;
    
        if (first != NSNotFound)
        {
            conn2 = [testBuffer rangeOfData:connData options:NSDataSearchBackwards range:NSMakeRange(first + 1, [testBuffer length] - first - 1)];
            serv2 = [testBuffer rangeOfData:servData options:NSDataSearchBackwards range:NSMakeRange(first + 1, [testBuffer length] - first - 1)];
            admn2 = [testBuffer rangeOfData:admnData options:NSDataSearchBackwards range:NSMakeRange(first + 1, [testBuffer length] - first - 1)];
        }
        else
            appendToMe = nil;
    
        if (conn.location != NSNotFound || serv.location != NSNotFound || admn.location != NSNotFound)
        {
            if (conn.location != NSNotFound)
            {
                [testBuffer replaceBytesInRange:NSMakeRange(0, conn.location) withBytes:nil length:0];
                if (conn2.location != NSNotFound || serv2.location != NSNotFound || admn2.location != NSNotFound)
                {
                    if (conn2.location != NSNotFound)
                    {
                        appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, conn2.location - first)] mutableCopy];
                        [testBuffer replaceBytesInRange:NSMakeRange(0, conn2.location) withBytes:nil length:0];
                    }
                    else if (serv2.location != NSNotFound)
                    {
                        appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, serv2.location - first)] mutableCopy];
                        [testBuffer replaceBytesInRange:NSMakeRange(0, serv2.location) withBytes:nil length:0];
                    }
                    else if (admn2.location != NSNotFound)
                    {
                        appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, admn2.location - first)] mutableCopy];
                        [testBuffer replaceBytesInRange:NSMakeRange(0, admn2.location) withBytes:nil length:0];
                    }
                    else
                    {
                        appendToMe = nil;
                        [testBuffer replaceBytesInRange:NSMakeRange(0, first) withBytes:nil length:0];
                    }
                }
            }
            else if (serv.location != NSNotFound)
            {
                [testBuffer replaceBytesInRange:NSMakeRange(0, serv.location) withBytes:nil length:0];
                if (conn2.location != NSNotFound || serv2.location != NSNotFound || admn2.location != NSNotFound)
                {
                    if (conn2.location != NSNotFound || serv2.location != NSNotFound || admn2.location != NSNotFound)
                    {
                        if (conn2.location != NSNotFound)
                        {
                            appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, conn2.location - first)] mutableCopy];
                            [testBuffer replaceBytesInRange:NSMakeRange(0, conn2.location) withBytes:nil length:0];
                        }
                        else if (serv2.location != NSNotFound)
                        {
                            appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, serv2.location - first)] mutableCopy];
                            [testBuffer replaceBytesInRange:NSMakeRange(0, serv2.location) withBytes:nil length:0];
                        }
                        else if (admn2.location != NSNotFound)
                        {
                            appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, admn2.location - first)] mutableCopy];
                            [testBuffer replaceBytesInRange:NSMakeRange(0, admn2.location) withBytes:nil length:0];
                        }
                        else
                        {
                            appendToMe = nil;
                            [testBuffer replaceBytesInRange:NSMakeRange(0, first) withBytes:nil length:0];
                        }
                    }
                }
            }
            else if (admn.location != NSNotFound)
            {
                [testBuffer replaceBytesInRange:NSMakeRange(0, admn.location) withBytes:nil length:0];
                if (conn2.location != NSNotFound || serv2.location != NSNotFound || admn2.location != NSNotFound)
                {
                    if (conn2.location != NSNotFound)
                    {
                        appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, conn2.location - first)] mutableCopy];
                        [testBuffer replaceBytesInRange:NSMakeRange(0, conn2.location) withBytes:nil length:0];
                    }
                    else if (serv2.location != NSNotFound)
                    {
                        appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, serv2.location - first)] mutableCopy];
                        [testBuffer replaceBytesInRange:NSMakeRange(0, serv2.location) withBytes:nil length:0];
                    }
                    else if (admn2.location != NSNotFound)
                    {
                        appendToMe = [[testBuffer subdataWithRange:NSMakeRange(first, admn2.location - first)] mutableCopy];
                        [testBuffer replaceBytesInRange:NSMakeRange(0, admn2.location) withBytes:nil length:0];
                    }
                    else
                    {
                        appendToMe = nil;
                        [testBuffer replaceBytesInRange:NSMakeRange(0, first) withBytes:nil length:0];
                    }
                }
            }
        }
    }
    
    return appendToMe;
}

/* Server runs on its owm thread. This thread is used for testing errors.*/
- (void)serverSocketWithErrorAndWithLog:(NSString *)logFile
{
    UMSocketType stype;
    in_port_t port;
    UMSocket *clientSocket = nil;
    NSString *name;
    UMLogFile *dst;
    UMLogHandler *handler;
    UMLogFeed *_logFeed;
    UMSocketError sErr, sErr2;
    int ret;
    NSMutableData *appendToMe;
    unsigned char tom[4];
    NSString *stom = nil;
    unsigned char som[3];
    BOOL testErrors = TRUE;
    
    @autoreleasepool
    {
        startupDone = NO;
        status = notRunning;
        
        [TestUMSocket configServerSockWithType:&stype
                                       andPort:&port
                                       andName:&name];
        dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
        handler = [[UMLogHandler alloc] initWithConsole];
        _logFeed = [UMLogFile setLogHandler:handler
                                   withName:@"Universal tests"
                                withSection:@"ulib tests"
                             withSubsection:@"UMSocket test"
                             andWithLogFile:dst];
        
        status = startingUp;
        
        UMSocket *listenerSocket = [[UMSocket alloc] initWithType:stype];
        sErr  = [listenerSocket listen];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"serverSocketWithErrorAndWithLog: trying to listen wihtout bind results default bindings\r\n");
        [listenerSocket close];
        
        listenerSocket = [[UMSocket alloc] initWithType:stype];
        sErr  = [listenerSocket bind];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"serverSocketWithErrorAndWithLog: trying to bind without port results binding with the default port\r\n");
        [listenerSocket close];
        
        listenerSocket = [[UMSocket alloc] initWithType:stype];
        clientSocket = [listenerSocket accept:&ret];
        XCTAssertNil(clientSocket, @"serverSocketWithErrorAndWithLog: trying to accept without binding should result an error\r\n");
        [listenerSocket close];
        
        listenerSocket = [[UMSocket alloc] initWithType:stype];
        [listenerSocket setLocalPort:port];
        sErr  = [listenerSocket bind];
        
        sErr  = [listenerSocket bind];
        XCTAssertTrue(sErr == UMSocketError_already_bound, @"serverSocketWithErrorAndWithLog: trying to bind second time produce error\r\n");
        [listenerSocket close];
        
        listenerSocket = [[UMSocket alloc] initWithType:stype];
        [listenerSocket setLocalPort:port];
        sErr  = [listenerSocket bind];
        
        clientSocket = [listenerSocket accept:&ret];
        XCTAssertNil(clientSocket, @"serverSocketWithErrorAndWithLog: trying to accept without listening should result an error\r\n");
        [listenerSocket close];
        
        listenerSocket = [[UMSocket alloc] initWithType:stype];
        [listenerSocket setLocalPort:port];
        sErr  = [listenerSocket bind];
        
        if (sErr == 0)
        {
            sErr2  = [listenerSocket listen];
            XCTAssertTrue(sErr2 == UMSocketError_no_error, @"serverSocketWithErrorAndWithLog: server socket could not start listening  (error %@)", [UMSocket getSocketErrorString:sErr]);
        }
        
        if (sErr == 0 && sErr2 == UMSocketError_no_error)
        {
            status = running;
            NSString *text = [NSString stringWithFormat:@"serverSocketWithErrorAndWithLog: Server socket %@ on port %ld is starting up\r\n",name, (long)[listenerSocket requestedLocalPort]];
            [_logFeed info:0 withText:text];
        }
        else
        {
            NSString *text = [NSString stringWithFormat:@"serverSocketWithErrorAndWithLog: Server socket %@ on could not be started at port %ld\r\n",name, (long)[listenerSocket requestedLocalPort]];
            [_logFeed majorError:0 withText:text];
        }
        
        startupDone = YES;
        
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
                    
                    XCTAssertNotNil(clientSocket, @"server should accept a connecting client or return EAGAIN\r\n");
			    NSString *text = [NSString stringWithFormat:@"Server socket %@ occepted client from <%@:%ld>\r\n",name,[listenerSocket remoteHost], (long)[listenerSocket requestedRemotePort]];
                    [TestUMSocket logAtomic:text toLog:_logFeed atFile:dst];
                    status = connected;
                }
                else
                {
                    /* test errors only once */
                    if (testErrors)
                    {
                        appendToMe = [NSMutableData data];
                        
                        sErr = [clientSocket receive:21 appendTo:nil];
                        XCTAssertTrue(sErr == UMSocketError_no_error, @"serverSocketWithErrorAndLog: receiveAppendTo: should ignore nil");
                        
                        sErr = [clientSocket receive:-1 appendTo:appendToMe];
                        XCTAssertTrue(sErr == UMSocketError_no_error, @"serverSocketWithErrorAndLog: receive:AppendTo: should ignore senseless length");
                        XCTAssertTrue([appendToMe length] == 0, @"serverSocketWithErrorAndLog: eceive:AppendTo: should return empty when sensless length is used ");
                        testErrors = FALSE;
                    }

                    if (status == testingBuffer)
                        appendToMe = [TestUMSocket readFromSocket:clientSocket withFixedLength:NO];
                    else
                        appendToMe = [TestUMSocket readFromSocket:clientSocket withFixedLength:YES];
                        
                    NSString *appendString = [[NSString alloc] initWithData:appendToMe encoding:NSUTF8StringEncoding];
                    NSString *text = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:Server socket %@ received <%@> from <%@:%ld> with %@ (testing normal)\r\n",name, appendToMe, [listenerSocket remoteHost], (long)[listenerSocket requestedRemotePort], status == testingBuffer ? @"buffer" : @"normal"];
                    [TestUMSocket logAtomic:text toLog:_logFeed atFile:dst];
                    
                    if (status != shuttingDown)
                    {
                        /* type of message */
                        NSString *text4 = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:received message <%@> \r\n", appendString];
                        [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
                    
                        if ([appendToMe length] > 4)
                        {
                            [appendToMe getBytes:tom range:NSMakeRange(0, 4)];
                            stom = [[NSString alloc] initWithBytes:tom length:4 encoding:NSUTF8StringEncoding];
                        }
                        if (stom && [stom compare:@"admn"] == NSOrderedSame)
                        {
                            NSString *ssom;
                            
                            if ([appendToMe length] > 7)
                            {
                                [appendToMe getBytes:som range:NSMakeRange(4, 3)];
                                ssom = [[NSString alloc] initWithBytes:som length:3 encoding:NSUTF8StringEncoding];
                            }
                            if (ssom && [ssom compare:@"end"] == NSOrderedSame)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:Server socket %@ received admn message with end\r\n", name];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = shuttingDown;
                                continue;
                            }
                            else if ([ssom compare:@"buf"] == NSOrderedSame)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"serverSocketWithErrorAndLog:Server socket %@ received admn message with testing switch command (use receive to buffer)\r\n", name];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                status = testingBuffer;
                                testErrors = 1;
                                continue;
                            }
                        }
                        else if (stom && [stom compare:@"conn"] == NSOrderedSame)
                        {
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received testing string for testing connection\r\n", name];
                            [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                            continue;
                        }
                        else if (stom && [stom compare:@"serv"] == NSOrderedSame)
                        {
                            /* Now we are testing erroneous messages by client*/
                            ++received;
                            NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received testing string (as %@, %ld bytes) for testing connection\r\n", name, appendToMe, (long)[appendToMe length]];
                            [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                            continue;
                        }
                        else
                        {
                            /* Ignore nil messages for timeout. Do not not shut down on erroneous msg, when testing errors we purposefully send ones. */
                            if (appendToMe)
                            {
                                NSString *text2a = [NSString stringWithFormat:@"Server socket %@ received an unknown message %@\r\n", name, appendToMe];
                                [TestUMSocket logAtomic:text2a toLog:_logFeed atFile:dst];
                                long len = [[clientSocket receiveBuffer] length];
                                [clientSocket deleteFromReceiveBuffer:(unsigned int)len];
                            }
                            continue;
                        }
                    }
                }
            }
        }
        
        [listenerSocket close];
        [clientSocket close];
        status = shutDown;
    
    }
}

- (void) testSocketTCP
{
	UMSocketType type;
    in_port_t port;
    UMLogFeed *_logFeed;     /* Log items are used for testing*/
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
    
    @autoreleasepool
    {
        char *toBeSent = "testing string";
        
        again = 0;
        
        [TestUMSocket configClientSockWithType:&type 
                                       andHost:&host
                                       andPort:&port 
                                       andName:&name
                                    andLogFile:&logFile];
        
        UMLogHandler *handler = [[UMLogHandler alloc] initWithConsole];
        UMLogFile *dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
        [dst emptyLog];
        
        _logFeed = [UMLogFile setLogHandler:handler
                                     withName:@"Universal tests" 
                                  withSection:@"ulib tests" 
                               withSubsection:@"UMSocket test"
                               andWithLogFile:dst];
        
        [NSThread detachNewThreadSelector:@selector(serverSocketWithLog:) toTarget:self withObject:dst];

        while (!startupDone) // let the server socket, in the same computer, to start up
        {
            usleep(10000);
        }
        NSString *localHostString = @"localhost";
        UMSocket *clientSocket = [[UMSocket alloc] initWithType:type];
        [clientSocket setRequestedRemotePort:port];	
        
        UMHost *server1 = [[UMHost alloc] initWithLocalhost];
        [clientSocket setRemoteHost:server1];
        sErr = [clientSocket connect];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"client socket should be able to connect the server %@\r\n", localHostString);
        
        NSString *ip = @"127.0.0.1";
        [clientSocket updateName];
        NSString *laddress = [clientSocket connectedLocalAddress];
        int type;
        laddress = [UMSocket deunifyIp:laddress type:&type];
        XCTAssertTrue([ip compare:laddress] == NSOrderedSame, @"TestUmSocket: update name should return our ip as local host");
        NSString *raddress = [clientSocket connectedRemoteAddress];
        int addressType;
        raddress = [UMSocket deunifyIp:raddress type:&addressType];
        
        XCTAssertTrue([ip compare:raddress] == NSOrderedSame, @"TestUmSocket: update name should return our ip as remote host host");
        in_port_t rport = [clientSocket connectedRemotePort];
        XCTAssertTrue(rport == port, @"TestUmSocket: update name should return requested remote port");
        
        usleep(50000);
        
        ns1 = [NSMutableString stringWithFormat:@"conn000%s", toBeSent];
        sErr = [clientSocket sendString:ns1];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client socket should be able to send connection test message\r\n");
        NSString *text3 = [NSString stringWithFormat:@"%@ sent %s for testing connection to <%@:%ld>\r\n", name, toBeSent, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [TestUMSocket logAtomic:text3 toLog:_logFeed atFile:dst];
        
        usleep(50000);
        
        NSString *text = [NSString stringWithFormat:@"Client socket %@ on is connecting to port %ld\r\n",name, (long)[clientSocket requestedRemotePort]];
        [TestUMSocket logAtomic:text toLog:_logFeed atFile:dst];
        
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client socket should be able to connect the localhost\r\n");
        NSString *text2 = [NSString stringWithFormat:@"Client socket %@ connected to <%@:%ld>\r\n",name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [TestUMSocket logAtomic:text2 toLog:_logFeed atFile:dst];
        
        UMSocketStatus ourStatus = [clientSocket status];
        NSString *ss = [UMSocket statusDescription:ourStatus];
        XCTAssertTrue([ss compare:@"is"] == NSOrderedSame, @"sTestUmSocket: ocket status should be in service");
        UMSocketConnectionDirection d = [clientSocket direction];
        NSString *sd = [UMSocket directionDescription:d];
        XCTAssertTrue([sd compare:@"outbound"] == NSOrderedSame, @"TestUmSocket: socket direction should be outbound");
        UMSocketType t = [clientSocket type];
        NSString *st = [UMSocket socketTypeDescription:t];
        XCTAssertTrue([st compare:@"tcp4only"] == NSOrderedSame, @"TestUmSocket: socket type shpould be tcp");
        rport = [clientSocket requestedRemotePort];
        XCTAssertTrue(rport == port, @"TestUmSocket: requested server port should be honored");
        UMHost *rhost = [clientSocket remoteHost];
        NSString *shost = [rhost name];
        
        XCTAssertTrue([shost compare:localHostString] == NSOrderedSame, @"TestUmSocket: requested server (localhost) should be honored");
        XCTAssertTrue([clientSocket isConnecting] == 0, @"TestUmSocket: client socket should be no more connecting");
        XCTAssertTrue([clientSocket isConnected] == 1, @"TestUmSocket: client socket should be connected");
        
again:
        if (again == 0)
            connectionString = @"using normal";
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
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client socket should be able to send NSString test message\r\n");
        ++sent;
        NSString *text3a;
        NSMutableString *logNs;
        if (again == 2)
        {
            logNs = [ns mutableCopy];
            [logNs replaceOccurrencesOfString:@"\r\n" withString:@"CRLF" options:NSLiteralSearch range:NSMakeRange(0, [ns length])];
            text3a = [NSString stringWithFormat:@"%@ sent %s (as %@) with type String to <%@:%ld> %@\r\n", name, toBeSent, logNs, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        else
        {
            text3a = [NSString stringWithFormat:@"%@ sent %s (as %@) with type String to <%@:%ld> %@\r\n", name, toBeSent, ns, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        [TestUMSocket logAtomic:text3a toLog:_logFeed atFile:dst];
            
        usleep(50000);
        
        [ns replaceCharactersInRange:NSMakeRange(6, 1) withString:[TestUMSocket typeToShortString:(int)CString]];
        char *s = (char *)[ns UTF8String];
        sErr = [clientSocket sendCString:s];
        ++sent;
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client should be able to send C String test message\r\n");
        NSString *text4;
        if (again == 2)
        {
            char *logs = (char *)[logNs UTF8String];
            text4 = [NSString stringWithFormat:@"%@ sent %s (as %s) with type C String to <%@:%ld> %@\r\n",name, toBeSent, logs, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        else
        {
            text4 = [NSString stringWithFormat:@"%@ sent %s (as %s) with type C String to <%@:%ld> %@\r\n",name, toBeSent, s, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        [TestUMSocket logAtomic:text4 toLog:_logFeed atFile:dst];
            
        usleep(50000);
        
        [ns replaceCharactersInRange:NSMakeRange(6, 1) withString:[TestUMSocket typeToShortString:(int)Data]];
        data = [[ns dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
        sErr = [clientSocket sendData:data];
        ++sent;
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client should be able to send NSData test message\r\n");
        NSString *text5;
        if (again == 2)
        {
            logNs = [ns mutableCopy];
            [logNs replaceOccurrencesOfString:@"\r\n" withString:@"CRLF" options:NSLiteralSearch range:NSMakeRange(0, [ns length])];
            text5 = [NSString stringWithFormat:@"%@ sent %s (as %@) with type Data to <%@:%ld> %@\r\n",name, toBeSent, logNs, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        else
        {
            text5 = [NSString stringWithFormat:@"%@ sent %s (as %@) with type Data to <%@:%ld> %@\r\n",name, toBeSent, ns, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        [TestUMSocket logAtomic:text5 toLog:_logFeed atFile:dst];
            
        usleep(50000);
        
        unsigned char *bytes;
        bytes = malloc(len + 7);
        unsigned char *byte;
        byte = malloc(1);
        byte[0] = [TestUMSocket typeToByte:(int)MutableData];
        [data replaceBytesInRange:NSMakeRange(6, 1) withBytes:byte];
        mdata = [data mutableCopy];
        sErr = [clientSocket sendMutableData:mdata];
        ++sent;
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client should be able to send NSMutableData test message");
        NSMutableString *dataString = [[NSMutableString alloc] initWithData:mdata encoding:NSUTF8StringEncoding];
        NSString *text6;
        if (again == 2)
        {
            NSMutableString *copyString = [dataString mutableCopy];
            [copyString replaceOccurrencesOfString:@"\r\n" withString:@"CRLF" options:NSLiteralSearch range:NSMakeRange(0, [dataString length])];
            text6 = [NSString stringWithFormat:@"%@ sent %s (as %@) with type MutableData to <%@:%ld> %@\r\n",name, toBeSent, copyString,[clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        else
        {
           text6 = [NSString stringWithFormat:@"%@ sent %s (as %@) with type MutableData to <%@:%ld> %@\r\n",name, toBeSent, dataString,[clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        }
        [TestUMSocket logAtomic:text6 toLog:_logFeed atFile:dst];
        
        usleep(50000);
        
        byte[0] = [TestUMSocket typeToByte:(int)Bytes];
        [data replaceBytesInRange:NSMakeRange(6, 1) withBytes:byte];
        
    
        if (again != 2)
        {
            [data getBytes:bytes length:len + 7];
            sErr = [clientSocket sendBytes:bytes length:len + 7];
        }
        else
        {
            [data getBytes:bytes length:len + 9];
            sErr = [clientSocket sendBytes:bytes length:len + 9];
        }
        
        ++sent;
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client should be able to send Bytes as test message\r\n");
        NSMutableString *sdata = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *text7;
        if (again == 2)
        {
            [sdata replaceOccurrencesOfString:@"\r\n" withString:@"CRLF" options:NSLiteralSearch range:NSMakeRange(0, [sdata length])];
        }
        text7 = [NSString stringWithFormat:@"%@ sent %s (as %@) with type Bytes to <%@:%ld> %@\r\n",name, toBeSent, sdata,[clientSocket remoteHost], (long)[clientSocket requestedRemotePort], connectionString];
        [TestUMSocket logAtomic:text7 toLog:_logFeed atFile:dst];
        free(bytes);
        free(byte);
        
        usleep(50000);
        
        if (again == 3)
        {
            // Wait until allmessages were received
            while (received < sent)
            {
                usleep(100000);
            }
            NSString *admin = [NSMutableString stringWithFormat:@"admnend0%s", toBeSent];
            sErr = [clientSocket sendString:admin];
            XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client socket should be able to send admin test message\r\n");
            NSString *text3a = [NSString stringWithFormat:@"%@ sent admin end to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
            [TestUMSocket logAtomic:text3a toLog:_logFeed atFile:dst];
        }
        else if (again == 2)
        {
            /* socket is still reading line, when it would receive admin switch command */
            NSString *admin = [NSMutableString stringWithFormat:@"admneve%s\r\n", toBeSent];
            sErr = [clientSocket sendString:admin];
            XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client socket should be able to send admin test message\r\n");
            NSString *text3a = [NSString stringWithFormat:@"%@ sent admin switch to test read everything to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
            [TestUMSocket logAtomic:text3a toLog:_logFeed atFile:dst];
            again = 3;
            goto again;
        }
        else if (again == 1)
        {
            NSString *admin = [NSMutableString stringWithFormat:@"admnlin%s", toBeSent];
            sErr = [clientSocket sendString:admin];
            XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client socket should be able to send admin test message\r\n");
            NSString *text3a = [NSString stringWithFormat:@"%@ sent admin switch to test read line to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
            [TestUMSocket logAtomic:text3a toLog:_logFeed atFile:dst];
            again = 2;
            goto again;
        }
        else 
        {
            NSString *admin = [NSMutableString stringWithFormat:@"admnbuf%s", toBeSent];
            sErr = [clientSocket sendString:admin];
            XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client socket should be able to send admin test message\r\n");
            NSString *text3a = [NSString stringWithFormat:@"%@ sent admin switch to test buffer to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
            [TestUMSocket logAtomic:text3a toLog:_logFeed atFile:dst];
            again = 1;
            goto again;
        }
        
        while (status < shutDown) // Waiting for server going down
            usleep(100000);
        
        sErr = [clientSocket close];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"TestUmSocket: client should be able to close the socket\r\n");
        NSString *text8 = [NSString stringWithFormat:@"%@ closed socket to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
        [TestUMSocket logAtomic:text8 toLog:_logFeed atFile:dst];
        
        ourStatus = [clientSocket status];
        NSString *ss1 = [UMSocket statusDescription:ourStatus];
        XCTAssertTrue([ss1 compare:@"oos"] == NSOrderedSame, @"socket status should be out of service");
        XCTAssertTrue([clientSocket isConnecting] == 0, @"TestUmSocket: client socket should not be connecting");
        XCTAssertTrue([clientSocket isConnected] == 0, @"TestUmSocket: client socket should not be connected");
        
        usleep(5000000);

        [dst closeLog];
        [dst removeLog];
    }
}

- (void) testSocketSCTP
{
}

- (void) testSocketTCPError
{
    UMSocketType type;
    in_port_t port;
    UMLogFeed *_logFeed;     /* Log items are used for testing*/
    NSString *logFile;
    NSString *name;
    NSString *host;
    UMSocketError sErr;
    NSMutableData *data;
    int len;
    int again;
    
    @autoreleasepool
    {
        again = 0;
        
        [TestUMSocket configClientSockWithType:&type
                                       andHost:&host
                                       andPort:&port
                                       andName:&name
                                    andLogFile:&logFile];
        
        UMLogHandler *handler = [[UMLogHandler alloc] initWithConsole];
        UMLogFile *dst = [[UMLogFile alloc] initWithFileName:logFile];
        _logFeed = [UMLogFile setLogHandler:handler
                                   withName:@"Universal tests"
                                withSection:@"ulib tests"
                             withSubsection:@"UMSocket Error test"
                             andWithLogFile:dst];

        [NSThread detachNewThreadSelector:@selector(serverSocketWithErrorAndWithLog:) toTarget:self withObject:logFile];
        while (!startupDone) // let the server socket, in the same computer, to start up
            usleep(10000);
        
        UMSocket *clientSocket = [[UMSocket alloc] initWithType:0x65];
        XCTAssertNil(clientSocket, @"testSocketTCPError: initing socket should return error when type is wrong");
        
        clientSocket = [[UMSocket alloc] initWithType:type];
        [clientSocket setRequestedRemotePort:port];
        
        UMHost *server1 = [[UMHost alloc] initWithName:nil];
        XCTAssertNil(server1, @"testSocketTCPError: initializing UMHost with nil host should return nil host");
        
        server1 = [[UMHost alloc] initWithName:@"junky.junky.junky"];
        [clientSocket setRemoteHost:server1];
        sErr = [clientSocket connect];
        XCTAssertTrue(sErr != UMSocketError_no_error, @"testSocketTCPError: client socket should not be able to connect the server junky.junky.junky\r\n");
        XCTAssertTrue(sErr == UMSocketError_address_not_available, @"testSocketTCPError: error message should be unknown host \r\n");
         UMSocketStatus ourStatus = [clientSocket status];
        NSString *ss1 = [UMSocket statusDescription:ourStatus];
        XCTAssertTrue([ss1 compare:@"unknown"] == NSOrderedSame, @"testSocketTCPError: socket status should be unknown");
        XCTAssertTrue([clientSocket isConnecting] == 0, @"testSocketTCPError: client socket should not be connecting");
        XCTAssertTrue([clientSocket isConnected] == 0, @"testSocketTCPError:  client socket should not be connected");
    
        server1 = [[UMHost alloc] initWithLocalhost];
        [clientSocket setRemoteHost:server1];
        sErr = [clientSocket connect];
        
        while(status < connected)      /* Continue when server has accepted us */
            usleep(10000);
        
        sErr = [clientSocket sendString:nil];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client socket should ignore nil String\r\n");
        
        sErr = [clientSocket sendCString:nil];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client socket should ignore nil CString\r\n");
        
        sErr = [clientSocket sendData:nil];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client socket should ignore nil Data\r\n");
        
        sErr = [clientSocket sendMutableData:nil];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client socket should ignore nil MutableData\r\n");
        
        sErr = [clientSocket sendBytes:nil length:0];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client socket should ignore nil Bytes\r\n");
        
        sErr = [clientSocket sendBytes:nil length:2];
        XCTAssertTrue(sErr == UMSocketError_pointer_not_in_userspace, @"testSocketTCPError: nil Bytes with wrong length should be an error\r\n");
        
        char *toBeSent = "testing string";
        len = (int)strlen(toBeSent);
        
        /* We must send first string twice, because we are testing an error that */
        NSMutableString *ns1 = [NSMutableString stringWithFormat:@"conn000%s", toBeSent];
        sErr = [clientSocket sendString:ns1];
        sErr = [clientSocket sendString:ns1];
        
        unsigned char byte[1];
        unsigned char bytes[len + 9];
        
again:
        byte[0] = [TestUMSocket typeToByte:(int)Bytes];
        NSMutableString *ns = [NSMutableString stringWithFormat:@"serv%d%d%s", len = (int)strlen(toBeSent), (int)String, toBeSent];
        
        data = [[ns dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
        [data replaceBytesInRange:NSMakeRange(6, 1) withBytes:byte];
        [data getBytes:bytes length:len + 3];

        sErr = [clientSocket sendBytes:bytes length:len];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client should be able to send Bytes as test message if lwength is too short\r\n");
        NSString *sdata = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *text7 = [NSString stringWithFormat:@"testSocketTCPError: %@ sent %s (as %@) with type Bytes to <%@:%ld (lenght %d)\r\n", name, toBeSent, sdata, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], len];
        [TestUMSocket logAtomic:text7 toLog:_logFeed atFile:dst];
        
        usleep(50000);
        
        sErr = [clientSocket sendBytes:bytes length:len + 10];
        XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client should be able to send Bytes as test message if length is too long\r\n");
        sdata = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *text1 = [NSString stringWithFormat:@"testSocketTCPError: %@ sent %s (as %@) with type Bytes to <%@:%ld\r\n (length %d)\r\n", name, toBeSent, sdata, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort], len + 20];
        [TestUMSocket logAtomic:text1 toLog:_logFeed atFile:dst];
        
        if (again == 1)
        {
            NSString *admin = [NSMutableString stringWithFormat:@"admnend0%s", toBeSent];
            sErr = [clientSocket sendString:admin];
            XCTAssertTrue(sErr == UMSocketError_no_error, @"testSocketTCPError: client socket should be able to send admin test message\r\n");
            NSString *text3a = [NSString stringWithFormat:@"testSocketTCPError: %@ sent admin end to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
            [TestUMSocket logAtomic:text3a toLog:_logFeed atFile:dst];
        }
        else
        {
            NSString *admin = [NSMutableString stringWithFormat:@"admnbuf%s", toBeSent];
            sErr = [clientSocket sendString:admin];
            XCTAssertTrue(sErr == UMSocketError_no_error, @":testSocketTCPError client socket should be able to send admin test message\r\n");
            NSString *text3a = [NSString stringWithFormat:@"testSocketTCPError %@ sent admin switch to test buffer to <%@:%ld>\r\n", name, [clientSocket remoteHost], (long)[clientSocket requestedRemotePort]];
            [TestUMSocket logAtomic:text3a toLog:_logFeed atFile:dst];
            again = 1;
            goto again;
        }
        
        while(status != shutDown)
            usleep(10000);
        
        sErr = [clientSocket close];
        
        [dst emptyLog];
        [dst closeLog];
        [dst removeLog];
    }
}

- (void)testUnifyIP
{
    NSString *a = @"79.134.238.20";
    NSString *b  = [UMSocket unifyIP:a];
    NSString *c = @"ipv4:79.134.238.20";

    XCTAssertTrue([c isEqualToString:b], @"unifyIP mismatch #1");
}


@end
