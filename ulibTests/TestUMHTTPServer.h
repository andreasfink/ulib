//
//  TestUMHTTPServer.h
//  ulib
//
//  Created by Aarno Syvänen on 25.04.12.
//  Copyright (c) Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved

#import <XCTest/XCTest.h>
#import "UniversalHTTP.h"

@class UMHTTPCaller, UMHTTPRequest, UMTestHTTPClient, UMLogFile;

@interface TestUMHTTPServer : XCTestCase
{
    BOOL done;
}

- (void)clientThread:(UMHTTPCaller *)caller;
+ (void)configHTTPClientFromConfigFile:(NSString *)configFile withUserName:(NSString **)username andPassword:(NSString **)password andLogFile:(NSString **)logFile andURLs:(NSMutableArray **)urls andText:(NSString **)msgText andHeaders:(NSMutableArray **)split andPostContent:(NSString **)content andCertKeyFile:(NSString **)ck andNumberOfRequests:(long *)maxRequests andServer:(NSString **)host andServerPort:(long *)port;
+ (UMTestHTTPClient *) startRequestWithCaller:(UMHTTPCaller *)caller withId:(long)i withLogFile:(NSString *)logFile withURLs:(NSMutableArray *)urls withText:(NSString *)msgText withHeaders:(NSMutableArray *)headers withPostContent:(NSString *)content withCertKeyFile:(NSString *)ck withHost:(NSString *)host withServerPort:(long)port withUsername:(NSString *)username withPassword:(NSString *)password andWithMethod:(UMHTTPMethod)method;
+ (int)receiveReply:(UMTestHTTPClient *)trans;
+ (void)configHTTPServerWithPort:(long *)port andLogFile:(NSString **)logFile;
+ (void) messagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived;
+ (void) postMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived;
+ (void) headMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived;
+ (void) optionsMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived;
+ (void) traceMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived;
+ (void) putMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived contentsSent:(long *)numberOfContentsSent contentsReceived:(long *)numberOfContentsReceived;
+ (void) deleteMessagesInLogFile:(UMLogFile *)dst sent:(NSMutableDictionary **)sentMessages received:(NSMutableDictionary **)receivedMessages messagesSent:(long *)numberOfSent messagesReceived:(long *)numberOfReceived;
+ (NSString *)methodToString:(int)method;


@end
