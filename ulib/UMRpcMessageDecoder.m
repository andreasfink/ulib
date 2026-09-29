//
//  UMRpcMessageDecoder.m
//  ulibasn1
//
//  Created by Andreas Fink on 22.08.2026.
//

#import <ulib/UMRpcMessageDecoder.h>
#import <ulib/UMRpcMessage.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcMessage_GenericError.h>
#import <ulib/UMRpcMessage_HeartbeatRequest.h>
#import <ulib/UMRpcMessage_HeartbeatResponse.h>
#import <ulib/UMRpcMessage_LoginRequest.h>
#import <ulib/UMRpcMessage_LoginResponse.h>
#import <ulib/UMRpcMessage_LogoutRequest.h>
#import <ulib/UMRpcMessage_LogoutResponse.h>
#import <ulib/UMRpcMessage_TestRequest.h>
#import <ulib/UMRpcMessage_TestResponse.h>


@implementation UMRpcMessageDecoder

- (UMSynchronizedSortedDictionary *)standardMessageTypes
{
    UMSynchronizedSortedDictionary *mt = [[UMSynchronizedSortedDictionary alloc]init];
    mt[@(UMRpcMessageType_GENERIC_ERROR)]       = @"GENERIC_ERROR";
    mt[@(UMRpcMessageType_LOGIN_REQUEST)]       = @"LOGIN_REQUEST";
    mt[@(UMRpcMessageType_LOGIN_RESPONSE)]      = @"LOGIN_RESPONSE";
    mt[@(UMRpcMessageType_LOGOUT_REQUEST )]     = @"LOGOUT_REQUEST";
    mt[@(UMRpcMessageType_LOGOUT_RESPONSE)]     = @"LOGOUT_RESPONSE";
    mt[@(UMRpcMessageType_HEARTBEAT_REQUEST)]   = @"HEARTBEAT_REQUEST";
    mt[@(UMRpcMessageType_HEARTBEAT_RESPONSE)]  = @"HEARTBEAT_RESPONSE";
    mt[@(UMRpcMessageType_TEST_REQUEST)]        = @"TEST_REQUEST";
    mt[@(UMRpcMessageType_TEST_RESPONSE)]       = @"TEST_RESPONSE";
    return mt;
}

- (UMRpcMessage *)decodeMessage:(UMRpcMessage *)msgin
{
    int cmd = msgin.command.intValue;
    switch(cmd)
    {
        case UMRpcMessageType_GENERIC_ERROR:
            return [[UMRpcMessage_GenericError alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_LOGIN_REQUEST:
            return [[UMRpcMessage_LoginRequest alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_LOGIN_RESPONSE:
            return [[UMRpcMessage_LoginResponse alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_LOGOUT_REQUEST:
            return [[UMRpcMessage_LogoutRequest alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_LOGOUT_RESPONSE:
            return [[UMRpcMessage_LogoutResponse alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_HEARTBEAT_REQUEST:
            return [[UMRpcMessage_HeartbeatRequest alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_HEARTBEAT_RESPONSE:
            return [[UMRpcMessage_HeartbeatResponse alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_TEST_REQUEST:
            return [[UMRpcMessage_TestRequest alloc]initWithASN1Object:msgin context:NULL];
        case UMRpcMessageType_TEST_RESPONSE:
            return [[UMRpcMessage_TestResponse alloc]initWithASN1Object:msgin context:NULL];
    }
    return msgin;
}
@end
