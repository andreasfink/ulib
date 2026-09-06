//
//  UMRpcMessage_LogoutRequest.h
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulib/UMRpcMessage.h>

typedef enum UMRpcMessageLogoutRequestTAG
{
    UMRpcMessageLogoutRequestTAG_REASON = 1,
} UMRpcMessageLLogoutRequestTAG;

@interface UMRpcMessage_LogoutRequest : UMRpcMessage
{
    NSString *_reason;
}
@property(readwrite,strong,atomic) NSString *reason;

@end

