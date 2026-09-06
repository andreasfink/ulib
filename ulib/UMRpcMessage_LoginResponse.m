//
//  UMRpcMessage_LoginResponse.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulib/UMRpcMessage_LoginResponse.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMASN1UTF8String.h>
#import <ulib/UMASN1Integer.h>
#import <ulib/UMRpcMacros.h>

@implementation UMRpcMessage_LoginResponse

- (UMRpcMessage_LoginResponse *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_LOGIN_RESPONSE);
        _flags = @(UMRpcFlag_IS_RESPONSE);
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_LoginResponse";
}

- (id)objectValue
{    
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    DAPPEND_NUMBER(@"serverApiVersion",_serverApiVersion,pdict)
    DAPPEND_STRING(@"serverName",_serverName,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_NUMBER(UMRpcMessageLoginResponseTAG_SERVER_API_VERSION,_serverApiVersion,a)
    APPEND_STRING(UMRpcMessageLoginResponseTAG_SERVER_NAME,_serverName,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}



- (UMRpcMessage_LoginResponse *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Object *payload = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [payload getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_NUMBER(UMRpcMessageLoginResponseTAG_SERVER_API_VERSION, _serverApiVersion, o)
        CHECK_STRING(UMRpcMessageLoginResponseTAG_SERVER_NAME, _serverName, o)
        o = [payload getObjectAtPosition:pos++];
    }
    return self;
}



@end
