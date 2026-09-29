//
//  UMSctpTask_Data.h
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMLayerTask.h>
#import <ulib/UMLayerSctpUserProtocol.h>
@class UMLayerSctp;

@interface UMSctpTask_Data : UMLayerTask
{
    NSData          *_data;
    NSNumber        *_streamId;
    NSNumber        *_protocolId;
    NSDictionary    *_ackRequest;
}

@property (readwrite,strong)        NSData          *data;
@property (readwrite,strong)        NSNumber        *streamId;
@property (readwrite,strong)        NSNumber        *protocolId;
@property (readwrite,strong)        NSDictionary    *ackRequest;
@property (readwrite,strong)        NSNumber        *socketNumber;

- (UMSctpTask_Data *)initWithReceiver:(UMLayerSctp *)rx
                               sender:(id<UMLayerSctpUserProtocol>)tx
                                 data:(NSData *)d
                             streamId:(NSNumber *)sid
                           protocolId:(NSNumber *)pid
                           ackRequest:(NSDictionary *)ack;
@end
#
