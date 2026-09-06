//
//  UMRpcMessage_LogoutRequest.m
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulibasn1/UMRpcMessage_LogoutRequest.h>
#import <ulibasn1/UMRpcMessageType.h>
#import <ulibasn1/UMRpcMacros.h>

@implementation UMRpcMessage_LogoutRequest

- (UMRpcMessage_LogoutRequest *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_LOGOUT_REQUEST);
        _flags = @(0);
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_LogoutRequest";
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
    APPEND_STRING(UMRpcMessageLogoutRequestTAG_REASON,_reason,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}

- (UMRpcMessage_LogoutRequest *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    
    int pos = 0;
    UMASN1Sequence *seq = [[UMASN1Sequence alloc]initWithASN1Object:_payload context:context];
    
    UMASN1Object *o = [seq getObjectAtPosition:pos++];
    while(o)
    {
        if(o.asn1_tag.tagClass==UMASN1Class_ContextSpecific)
        {
            switch(o.asn1_tag.tagNumber)
            {
                case UMRpcMessageLogoutRequestTAG_REASON:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _reason = u.stringValue;
                    break;
                }
            }
        }
        o = [seq getObjectAtPosition:pos++];
    }
    return self;
}

@end

