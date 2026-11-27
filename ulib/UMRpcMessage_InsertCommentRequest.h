//
//  UMRpcMessage_InsertCommentRequest.h
//  ulib
//
//  Created by Andreas Fink on 27.11.2026.
//


#import <ulib/UMRpcMessage.h>


typedef enum UMRpcMessage_InsertCommentRequestTAG
{
    UMRpcMessage_InsertCommentRequestTAG_COMMENT    = 1,
} UMRpcMessage_InsertCommentRequestTAG;

@interface UMRpcMessage_InsertCommentRequest : UMRpcMessage
{
    NSString *_comment;
}

@property(readwrite,strong,atomic)  NSString *comment;

@end


