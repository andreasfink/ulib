//
//  UMRpcMessageDecoder.m
//  ulibasn1
//
//  Created by Andreas Fink on 22.08.2026.
//

#import <ulibasn1/UMRpcMessageDecoder.h>
#import <ulibasn1/UMRpcMessage.h>
#import <ulibasn1/UMRpcMessageType.h>
#import <ulibasn1/UMRpcMessage_GenericError.h>
#import <ulibasn1/UMRpcMessage_HeartbeatRequest.h>
#import <ulibasn1/UMRpcMessage_HeartbeatResponse.h>
#import <ulibasn1/UMRpcMessage_LoginRequest.h>
#import <ulibasn1/UMRpcMessage_LoginResponse.h>
#import <ulibasn1/UMRpcMessage_LogoutRequest.h>
#import <ulibasn1/UMRpcMessage_LogoutResponse.h>
#import <ulibasn1/UMRpcMessage_TestRequest.h>
#import <ulibasn1/UMRpcMessage_TestResponse.h>


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
