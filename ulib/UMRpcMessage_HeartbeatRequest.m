//
//  UMRpcMessage_HeartbeatRequest.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulibasn1/UMRpcMessage_HeartbeatRequest.h>
#import <ulibasn1/UMRpcMessageType.h>

@implementation UMRpcMessage_HeartbeatRequest

- (UMRpcMessage_HeartbeatRequest *)init
{
   self = [super init];
   if(self)
   {
       _command = @(UMRpcMessageType_HEARTBEAT_REQUEST);
       _flags = @(0);
   }
   return self;
}

- (NSString *) objectName
{
   return @"UMRpcMessage_HeartbeatRequest";
}

@end

