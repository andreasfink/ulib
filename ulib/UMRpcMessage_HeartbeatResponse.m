//
//  UMRpcMessage_HeartbeatResponse.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMRpcMessage_HeartbeatResponse.h>
#import <ulib/UMRpcMessageType.h>

@implementation UMRpcMessage_HeartbeatResponse

- (UMRpcMessage_HeartbeatResponse *)init
{
   self = [super init];
   if(self)
   {
       _command = @(UMRpcMessageType_HEARTBEAT_RESPONSE);
       _flags = @(UMRpcFlag_IS_RESPONSE);
   }
   return self;
}

- (NSString *) objectName
{
   return @"UMRpcMessage_HeartbeatResponse";
}

@end

