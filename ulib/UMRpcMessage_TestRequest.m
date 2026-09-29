//
//  UMRpcMessage_TestRequest.m
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulib/UMRpcMessage_TestRequest.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcMacros.h>

@implementation UMRpcMessage_TestRequest

- (UMRpcMessage_TestRequest *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_TEST_REQUEST);
        _flags = @(0);
    }
    return self;
}


- (NSString *) objectName
{
    return @"UMRpcMessage_TestRequest";
}


- (id)objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    DAPPEND_STRING(@"requestMessage",_requestMessage,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_STRING(UMRpcMessageTestRequestTAG_requestMessage,_requestMessage,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}


- (UMRpcMessage_TestRequest *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Object *payload = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [payload getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_STRING(UMRpcMessageTestRequestTAG_requestMessage, _requestMessage, o)
        o = [payload getObjectAtPosition:pos++];
    }
    return self;
}


@end
