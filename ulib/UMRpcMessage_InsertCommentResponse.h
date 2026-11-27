//
//  UMRpcMessage_InsertCommentResponse.h
//  ulib
//
//  Created by Andreas Fink on 27.11.2026.
//

#import <ulib/UMRpcMessage.h>

typedef enum UMRpcMessage_InsertCommentResponseTAG
{
    UMRpcMessage_InsertCommentResponseTAG_REASON,
} UMRpcMessage_InsertCommentResponseTAG;


@interface UMRpcMessage_InsertCommentResponse : UMRpcMessage
{
    NSString *_reason;
}

@property(readwrite,strong,atomic)  NSString *reason;

@end

