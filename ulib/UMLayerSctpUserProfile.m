//
//  UMLayerSctpUserProfile.m
//  ulibsctp
//
//  Created by Andreas Fink on 03.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import "UMLayerSctpUserProfile.h"

@implementation UMLayerSctpUserProfile



- (UMLayerSctpUserProfile *)initWithDefaultProfile
{
    self = [super init];
    if(self)
    {
        _allMessages = YES;
        _statusUpdates = YES;
        _monitoring = NO;
    }
    return self;
}

- (BOOL) wantsStreamId:(NSNumber *)stream
{
    if(_allMessages)
    {
        return YES;
    }
    if(_streamIds ==NULL)
    {
        return YES;
    }
    for(NSNumber *n in _streamIds)
    {
        if (n.unsignedLongValue == stream.unsignedLongValue)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL) wantsProtocolId:(NSNumber *)proto
{
    if(_allMessages)
    {
        return YES;
    }
    if(_protocolIds ==NULL)
    {
        return YES;
    }
    for(NSNumber *n in _protocolIds)
    {
        if (n.unsignedLongValue == proto.unsignedLongValue)
        {
            return YES;
        }
    }
    return NO;
}


- (BOOL) wantsStatusUpdates
{
    if(_statusUpdates)
    {
        return YES;
    }
    return NO;
}

- (BOOL) wantsMonitor
{
    if(_monitoring)
    {
        return YES;
    }
    return NO;
}

@end

#endif
