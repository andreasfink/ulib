//
//  UMRpcMessage_LoginRequest.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMRpcMessage_LoginRequest.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcMacros.h>

@implementation UMRpcMessage_LoginRequest


- (UMRpcMessage_LoginRequest *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_LOGIN_REQUEST);
        _flags = @(0);
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_LoginRequest";
}

- (id)objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    DAPPEND_STRING(@"username",_username,pdict)
    DAPPEND_STRING(@"password",_password,pdict)
    DAPPEND_STRING(@"instance",_instance,pdict)
    DAPPEND_NUMBER(@"apiVersion",_apiVersion,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_STRING(UMRpcMessageLoginRequestTAG_USERNAME,_username,a)
    APPEND_STRING(UMRpcMessageLoginRequestTAG_PASSWORD,_password,a)
    APPEND_STRING(UMRpcMessageLoginRequestTAG_INSTANCE,_instance,a)
    APPEND_NUMBER(UMRpcMessageLoginRequestTAG_API_VERSION,_apiVersion,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}

- (UMRpcMessage_LoginRequest *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Object *payload = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [payload getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_STRING(UMRpcMessageLoginRequestTAG_USERNAME, _username, o)
        CHECK_STRING(UMRpcMessageLoginRequestTAG_PASSWORD, _password, o)
        CHECK_STRING(UMRpcMessageLoginRequestTAG_INSTANCE, _instance, o)
        CHECK_NUMBER(UMRpcMessageLoginRequestTAG_API_VERSION, _apiVersion, o)
        o = [payload getObjectAtPosition:pos++];
    }
    return self;
}

@end
