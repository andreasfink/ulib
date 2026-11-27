//
//  UMRpcMessage_InsertCommentRequest.m
//  ulib
//
//  Created by Andreas Fink on 27.11.2026.
//

#import <ulib/UMRpcMessage_InsertCommentRequest.h>
#import <ulib/UMRpcMacros.h>
#import <ulib/UMRpcMessageType.h>

@implementation UMRpcMessage_InsertCommentRequest

- (UMRpcMessage_InsertCommentRequest *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_INSERT_COMMENT_REQUEST);
        _flags = @(0);
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_InsertCommentRequest";
}

- (id)objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    DAPPEND_STRING(@"comment",_comment,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_STRING(UMRpcMessage_InsertCommentRequestTAG_COMMENT,_comment,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}

- (UMRpcMessage_InsertCommentRequest *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Object *payload = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [payload getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_STRING(UMRpcMessage_InsertCommentRequestTAG_COMMENT, _comment, o)
        o = [payload getObjectAtPosition:pos++];
    }
    return self;
}

@end



