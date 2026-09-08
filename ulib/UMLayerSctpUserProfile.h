//
//  UMLayerSctpUserProfile.h
//  ulibsctp
//
//  Created by Andreas Fink on 03.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/ulib.h>

@interface UMLayerSctpUserProfile : UMObject
{
    BOOL _allMessages;
    BOOL _statusUpdates;
    NSArray *_streamIds;
    NSArray *_protocolIds;
    BOOL _monitoring;
}

@property(readwrite,assign) BOOL allMessages;
@property(readwrite,assign) BOOL statusUpdates;
@property(readwrite,strong) NSArray *streamIds;
@property(readwrite,strong) NSArray *protocolIds;
@property(readwrite,assign) BOOL monitoring;

- (UMLayerSctpUserProfile *)initWithDefaultProfile;
- (BOOL) wantsStreamId:(NSNumber *)stream;
- (BOOL) wantsProtocolId:(NSNumber *)proto;
- (BOOL) wantsStatusUpdates;
- (BOOL) wantsMonitor;

@end
#endif
