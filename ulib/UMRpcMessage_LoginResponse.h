//
//  UMRpcMessage_LoginResponse.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMRpcMessage.h>

typedef enum UMRpcMessageLoginResponseTAG
{
    UMRpcMessageLoginResponseTAG_SERVER_API_VERSION = 1,
    UMRpcMessageLoginResponseTAG_SERVER_NAME = 2,
} UMRpcMessageLoginResponseTAG;

@interface UMRpcMessage_LoginResponse : UMRpcMessage
{
    NSNumber *_serverApiVersion;
    NSString *_serverName;
}

@property(readwrite,strong) NSNumber *serverApiVersion;
@property(readwrite,strong) NSString *serverName;

@end

