//
//  UMRpcMessage_TestRequest.h
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulibasn1/UMRpcMessage.h>

typedef enum UMRpcMessageTestRequestTAG
{
    UMRpcMessageTestRequestTAG_requestMessage = 1,
} UMRpcMessageTestRequestTAG;

@interface UMRpcMessage_TestRequest : UMRpcMessage
{
    NSString *_requestMessage;
}
@property(readwrite,strong)     NSString *requestMessage;

@end

