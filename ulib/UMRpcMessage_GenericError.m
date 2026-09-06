//
//  UMRpcMessage_GenericError.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulibasn1/UMRpcMessage_GenericError.h>
#import <ulibasn1/UMRpcMessageType.h>

#import <ulibasn1/UMRpcMacros.h>

@implementation UMRpcMessage_GenericError


- (UMRpcMessage_GenericError *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_GENERIC_ERROR);
        _flags = @(UMRpcFlag_IS_RESPONSE);
    }
    return self;
}


- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    APPEND_STRING(UMRpcMessageGenericErrorTAG_errorString,_errorString,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}

- (UMRpcMessage_GenericError *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Sequence *seq = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    UMASN1Object *o = [seq getObjectAtPosition:pos++];
    while(o)
    {
        CHECK_STRING(UMRpcMessageGenericErrorTAG_errorString,_errorString,o)
        o = [seq getObjectAtPosition:pos++];
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_GenericError";
}

- (id) objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *d = [[UMSynchronizedSortedDictionary alloc]init];
    
    DAPPEND_STRING(@"error-string",_errorString,d);
    
    dict[@"payload"] = d;
    return dict;
}

@end
