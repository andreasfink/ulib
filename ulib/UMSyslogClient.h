//
//  UMSyslogClient.h
//  ulib
//
//  Created by Andreas Fink on 29.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

// this is a object to write RFC5424 compatible syslog entries
//

#import <ulib/UMObject.h>
#import <ulib/UMHost.h>
#include <unistd.h>
 
typedef enum UMSyslogFacility
{
    UMSyslogFacility_Default                = -1,
    UMSyslogFacility_Kernel                 = 0,
    UMSyslogFacility_User                   = 1,
    UMSyslogFacility_Mail                   = 2,
    UMSyslogFacility_SydstemDaemons         = 3,
    UMSyslogFacility_SecurityAuthorisation1 = 4,
    UMSyslogFacility_Internal               = 5,
    UMSyslogFacility_Printer                = 6,
    UMSyslogFacility_Network                = 7,
    UMSyslogFacility_UUCP                   = 8,
    UMSyslogFacility_Clock                  = 9,
    UMSyslogFacility_SecurityAuthorisation2 = 10,
    UMSyslogFacility_FTP                    = 11,
    UMSyslogFacility_NTP                    = 12,
    UMSyslogFacility_Audit                  = 13,
    UMSyslogFacility_Alert                  = 14,
    UMSyslogFacility_ClockDaemon            = 15,
    UMSyslogFacility_Local0                 = 16,
    UMSyslogFacility_Local1                 = 17,
    UMSyslogFacility_Local2                 = 18,
    UMSyslogFacility_Local3                 = 19,
    UMSyslogFacility_Local4                 = 20,
    UMSyslogFacility_Local5                 = 21,
    UMSyslogFacility_Local6                 = 22,
    UMSyslogFacility_Local7                 = 23,
} UMSyslogFacility;

typedef enum UMSyslogSeverity
{
    UMSyslogSeverity_Default        = -1,
    UMSyslogSeverity_Emergency      = 0,
    UMSyslogSeverity_Alert          = 1,
    UMSyslogSeverity_Critical       = 2,
    UMSyslogSeverity_Error          = 3,
    UMSyslogSeverity_Warning        = 4,
    UMSyslogSeverity_Notice         = 5,
    UMSyslogSeverity_Informational  = 6,
    UMSyslogSeverity_Debug          = 7,
} UMSyslogSeverity;

@interface UMSyslogClient : UMObject
{
    NSString *_destinationHost;
    int     _version;
    int     _udpPort;
    UMSyslogFacility     _defaultFacility;
    UMSyslogSeverity     _defaultSeverity;
    pid_t   _localPid;
    NSString *_localHostname;
    NSString *_appname;
    NSDateFormatter *_dateFormatter;
    UMSocket *_sock;
    BOOL isOpen;
}

@property(readwrite,strong) NSString *destinationHost;
@property(readwrite,assign) int     udpPort;
@property(readwrite,assign) UMSyslogFacility     defaultFacility;
@property(readwrite,assign) UMSyslogSeverity     defaultSeverity;
@property(readwrite,strong) NSString *localHostname;

- (UMSyslogClient *)initWithDestination:(NSString *)destHost port:(int)port;
- (void)open;
- (void)close;
- (void)logMessageId:(NSString *)msgid
             message:(NSString *)msg
            facility:(UMSyslogFacility)facility
            severity:(UMSyslogSeverity)severity;


@end
