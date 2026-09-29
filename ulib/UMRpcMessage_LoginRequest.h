//
//  UMRpcMessage_LoginRequest.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMRpcMessage.h>

typedef enum UMRpcMessageLoginRequestTAG
{
    UMRpcMessageLoginRequestTAG_USERNAME = 1,
    UMRpcMessageLoginRequestTAG_PASSWORD = 2,
    UMRpcMessageLoginRequestTAG_INSTANCE = 3,
    UMRpcMessageLoginRequestTAG_API_VERSION = 4,
} UMRpcMessageLoginRequestTAG;

@interface UMRpcMessage_LoginRequest : UMRpcMessage
{
    NSString *_username;
    NSString *_password;
    NSString *_instance;
    NSNumber *_apiVersion;
}

@property(readwrite,strong,atomic)  NSString *username;
@property(readwrite,strong,atomic)  NSString *password;
@property(readwrite,strong,atomic)  NSString *instance;
@property(readwrite,strong,atomic)  NSNumber *apiVersion;

@end

