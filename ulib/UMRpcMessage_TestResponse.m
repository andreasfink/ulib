//
//  UMRpcMessage_TestResponse.m
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulibasn1/UMRpcMessage_TestResponse.h>
#import <ulibasn1/UMRpcMessageType.h>
#import <ulibasn1/UMRpcMacros.h>


@implementation UMRpcMessage_TestResponse

- (UMRpcMessage_TestResponse *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_TEST_RESPONSE);
        _flags=@(UMRpcFlag_IS_RESPONSE);
    }
    return self;
}


- (NSString *) objectName
{
    return @"UMRpcMessage_TestResponse";
}



- (id)objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    DAPPEND_STRING(@"responseMessage",_responseMessage,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_STRING(UMRpcMessageTestResponeTAG_responseMessage,_responseMessage,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}


- (UMRpcMessage_TestResponse *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Object *payload = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [payload getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_STRING(UMRpcMessageTestResponeTAG_responseMessage, _responseMessage, o)
        o = [payload getObjectAtPosition:pos++];
    }
    return self;
}

@end
