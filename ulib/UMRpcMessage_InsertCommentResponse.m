//
//  UMRpcMessage_InsertCommentResponse.m
//  ulib
//
//  Created by Andreas Fink on 27.11.2026.
//

#import "UMRpcMessage_InsertCommentResponse.h"
#import <ulib/UMRpcMacros.h>
#import <ulib/UMRpcMessageType.h>



@implementation UMRpcMessage_InsertCommentResponse

- (UMRpcMessage_InsertCommentResponse *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_INSERT_COMMENT_RESPONSE);
        _flags = @(UMRpcFlag_IS_RESPONSE);
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_InsertCommentResponse";
}

- (id)objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    DAPPEND_STRING(@"reason",_reason,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_STRING(UMRpcMessage_InsertCommentResponseTAG_REASON,_reason,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}

- (UMRpcMessage_InsertCommentResponse *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Object *payload = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [payload getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_STRING(UMRpcMessage_InsertCommentResponseTAG_REASON,_reason, o)
        o = [payload getObjectAtPosition:pos++];
    }
    return self;
}

@end



