//
//  UMRpcMessage_LogoutResponse.m
//  ulibrpc
//
//  Created by Andreas Fink on 21.08.2026.
//

#import <ulib/UMRpcMessage_LogoutResponse.h>
#import <ulib/UMRpcMessageType.h>
#import <ulib/UMRpcMacros.h>

@implementation UMRpcMessage_LogoutResponse

- (UMRpcMessage_LogoutResponse *)init
{
    self = [super init];
    if(self)
    {
        _command = @(UMRpcMessageType_LOGOUT_RESPONSE);
        _flags = @(UMRpcFlag_IS_RESPONSE);
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage_LogoutResponse";
}


- (id)objectValue
{
    UMSynchronizedSortedDictionary *dict = [super objectValue];
    UMSynchronizedSortedDictionary *pdict = [[UMSynchronizedSortedDictionary alloc]init];
    //  DAPPEND_STRING(@"reason",_reason,pdict)
    dict[@"payload"] = pdict;
    return dict;
}

- (void) processBeforeEncode
{
    NSMutableArray *a = [[NSMutableArray alloc]init];
    // APPEND_STRING(UMRpcMessageLogoutRequestTAG_REASON,_reason,a)
    _payload = [[UMASN1Sequence alloc]initWithValues:a];
    [super processBeforeEncode];
}
@end
