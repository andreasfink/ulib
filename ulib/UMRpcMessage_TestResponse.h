//
//  UMRpcMessage_TestResponse.h
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulib/UMRpcMessage.h>

typedef enum UMRpcMessageTestResponseTAG
{
    UMRpcMessageTestResponeTAG_responseMessage = 1,
} UMRpcMessageTestResponseTAG;

@interface UMRpcMessage_TestResponse : UMRpcMessage
{
    NSString *_responseMessage;
}

@property(readwrite,strong,atomic)  NSString *responseMessage;
@end

