//
//  UMRpcMessageType.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/ulib.h>


typedef enum UMRpcMessageType
{
    UMRpcMessageType_GENERIC_ERROR      = 0,
    UMRpcMessageType_LOGIN_REQUEST      = 1,
    UMRpcMessageType_LOGIN_RESPONSE     = 2,
    UMRpcMessageType_LOGOUT_REQUEST     = 3,
    UMRpcMessageType_LOGOUT_RESPONSE    = 4,
    UMRpcMessageType_HEARTBEAT_REQUEST  = 5,
    UMRpcMessageType_HEARTBEAT_RESPONSE = 6,
    UMRpcMessageType_TEST_REQUEST       = 7,
    UMRpcMessageType_TEST_RESPONSE      = 8,
} UMRpcMessageType;
