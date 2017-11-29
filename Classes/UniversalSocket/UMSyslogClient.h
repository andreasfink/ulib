//
//  UMSyslogClient.h
//  ulib
//
//  Created by Andreas Fink on 29.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

// this is a object to write RFC5424 compatible syslog entries
//

#import "UMObject.h"
#import "UMHost.h"
#include <unistd.h>

@interface UMSyslogClient : UMObject
{
    NSString *_destinationHost;
    int     _version;
    int     _udpPort;
    int     _defaultFacility;
    int     _defaultSeverity;
    pid_t   _localPid;
    NSString *_localHostname;
    NSString *_appname;
    NSDateFormatter *_dateFormatter;
    UMSocket *_sock;
    BOOL isOpen;
}

@property(readwrite,strong) NSString *destinationHost;
@property(readwrite,assign) int     udpPort;
@property(readwrite,assign) int     defaultFacility;
@property(readwrite,assign) int     defaultSeverity;
@property(readwrite,strong) NSString *localHostname;

- (UMSyslogClient *)initWithDestination:(NSString *)destHost port:(int)port;
- (void)open;
- (void)close;
- (void)logMessageId:(NSString *)msgid
             message:(NSString *)msg
            facility:(int)facility
            severity:(int)severity;


@end
