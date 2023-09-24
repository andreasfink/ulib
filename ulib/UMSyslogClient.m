//
//  UMSyslogClient.m
//  ulib
//
//  Created by Andreas Fink on 29.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMSyslogClient.h>
#include <unistd.h>

@implementation UMSyslogClient

- (UMSyslogClient *)initWithDestination:(NSString *)destHost port:(int)port
{
    self = [super init];
    if(self)
    {
        char localhost[_SC_HOST_NAME_MAX+1];
        memset(localhost,0x00,_SC_HOST_NAME_MAX+1);
        gethostname(localhost,_SC_HOST_NAME_MAX);
        _localHostname = @(localhost);
        _localPid = getpid();
        _version = 1;
        _appname = @"UMSyslogClient";
        _defaultFacility = UMSyslogFacility_Local0;
        _defaultSeverity = UMSyslogSeverity_Error;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
        [_dateFormatter setDateFormat:@"YYYY-MM-DDTHH:mm:ssZ"];
        _destinationHost = destHost;
        _udpPort = port;
    }
    return self;
}

- (void)open
{
    _sock = [[UMSocket alloc]initWithType:UMSOCKET_TYPE_UDP name:@"syslog-client"];
    _sock.remoteHost = [[UMHost alloc]initWithName:_destinationHost];
    _sock.requestedRemotePort = _udpPort;
    _sock.objectStatisticsName = @"UMSocket(Syslog-client)";
    [_sock connect];
    isOpen = YES;
    [self logMessageId:@"00000000"
               message:@"--startup--"
              facility:UMSyslogFacility_Default
              severity:UMSyslogSeverity_Informational];
}

- (void)close
{
    [_sock close];
    isOpen = NO;
}

- (void)logMessageId:(NSString *)msgid
             message:(NSString *)msg
            facility:(UMSyslogFacility)facility
            severity:(UMSyslogSeverity)severity
{
    if(!isOpen)
    {
        [self open];
    }
    if(facility == UMSyslogFacility_Default)
    {
        facility = _defaultFacility;
    }
    if(severity == UMSyslogSeverity_Default)
    {
        severity = _defaultSeverity;
    }
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@"<%d>%d %@ %@ %lu %@ - %@",
        (facility<< 3 | severity),
        _version,
        [self timeStamp],
        _localHostname,
        (unsigned long)_localPid,
        msgid,
        msg
     ];
    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    [_sock sendData:data];
}

- (NSString *)timeStamp
{
    if(_dateFormatter)
    {
        return [_dateFormatter stringFromDate:[NSDate date]];
    }

    time_t    current;
    struct tm trec1;
    char buffer[32];

    time(&current);
    localtime_r(&current, &trec1);
    memset(buffer,0x00,32);
    return @(asctime_r(&trec1, buffer));
}


@end
