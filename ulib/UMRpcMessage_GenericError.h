//
//  UMRpcMessage_GenericError.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//


#import <ulib/UMRpcMessage.h>

typedef enum UMRpcMessageGenericErrorTAG
{
    UMRpcMessageGenericErrorTAG_errorString = 1,
} UMRpcMessageGenericErrorTAG;

@interface UMRpcMessage_GenericError : UMRpcMessage
{
    NSString *_errorString;
}

@property(strong,atomic) NSString *errorString;

@end

