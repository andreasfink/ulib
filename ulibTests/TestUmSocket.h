//
//  TestUmSocket.h
//  ulib
//
//  Created by Aarno Syvänen on 27.03.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UMSocket.h"
#import "UMLogFile.h"
#import "UMLogFeed.h"
#import "UMTestCase.h"

@class UMLogFeed, UMLogHandler, UMLogFile;

typedef enum SocketStatus
{
	notRunning = 0,
	startingUp,
	running,
    connected,
    testingBuffer,
    testingReadLine,
    testingReadEverything,
	shuttingDown,
	shutDown,
	failed,
} SocketStatus;

typedef enum ContentType
{
    Bytes = 0,
    CString,
    String,
    Data,
    MutableData,
    NotKnown
} ContentType;

@interface TestUMSocket : XCTestCase
{
    BOOL startupDone;
    SocketStatus status;
    long received;
    long sent;
}

@property(readwrite,assign) SocketStatus  status;
@property(readwrite,assign) long received;
@property(readwrite,assign) long sent;

+ (NSString *)typeToString:(ContentType)type;
+ (NSString *)typeToShortString:(int)type;
+ (unsigned char)typeToByte:(int)type;
+ (ContentType)stringToType:(NSString *)string;
+ (void)configServerSockWithType:(UMSocketType *)type andPort:(in_port_t *)port andName:(NSString **)name;
+ (void)configClientSockWithType:(UMSocketType *)type andHost:(NSString **)host andPort:(in_port_t *)port andName:(NSString **)name andLogFile:(NSString **)logFile;
- (void)serverSocketWithLog:(UMLogFile *)dst;
+ (void) logAtomic:(NSString *)text toLog:(UMLogFeed *)logFeed atFile:(UMLogFile *)dst;
+ (void) messagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent 
messagesReceived:(long *)numberOfReceived;
+ (NSString *)resolveThis:(NSString *)name;
+ (void)analyzeMessage:(NSData *)appendToMe givingString:(NSString **)s orData:(NSData **)d orMutableData:(NSMutableData **)md  andType:(ContentType *)dtype;

@end
