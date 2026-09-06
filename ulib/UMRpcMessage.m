//
//  UMRpcMessage.m
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulibasn1/UMRpcMessage.h>
#import <ulibasn1/UMRpcMessageType.h>
#import <ulibasn1/UMRpcError.h>

@implementation UMRpcMessage

- (void) processBeforeEncode
{
    [super processBeforeEncode];
    [_asn1_tag setTagIsConstructed];
    _asn1_list = [[NSMutableArray alloc]init];
    
    if(_sequenceNumber)
    {
        UMASN1Integer *i = [[UMASN1Integer alloc]initWithNumber:_sequenceNumber];
        i.asn1_tag.tagNumber = UMRpcMessageTAG_SEQUENCE_NUMBER;
        i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:i];
    }
    if(_command)
    {
        UMASN1Integer *i = [[UMASN1Integer alloc]initWithNumber:_command];
        i.asn1_tag.tagNumber = UMRpcMessageTAG_COMMAND;
        i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:i];
    }
    if(_flags)
    {
        UMASN1Integer *i = [[UMASN1Integer alloc]initWithNumber:_flags];
        i.asn1_tag.tagNumber = UMRpcMessageTAG_FLAGS;
        i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:i];
    }
    if(_status)
    {
        UMASN1Integer *i = [[UMASN1Integer alloc]initWithNumber:_status];
        i.asn1_tag.tagNumber = UMRpcMessageTAG_STATUS;
        i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:i];
    }
    if(_error)
    {
        UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithString:_error];
        u.asn1_tag.tagNumber = UMRpcMessageTAG_ERROR;
        u.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:u];
    }
    if(_payload)
    {
        _payload.asn1_tag.tagNumber = UMRpcMessageTAG_PAYLOAD;
        _payload.asn1_tag.tagClass = UMASN1Class_ContextSpecific;
        [_asn1_list addObject:_payload];
    }
}

- (UMRpcMessage *) processAfterDecodeWithContext:(id)context
{
    [super processAfterDecodeWithContext:context];
    int pos = 0;
    UMASN1Object *o = [self getObjectAtPosition:pos++];
    while(o)
    {
        if(o.asn1_tag.tagClass==UMASN1Class_ContextSpecific)
        {
            switch(o.asn1_tag.tagNumber)
            {
                case UMRpcMessageTAG_SEQUENCE_NUMBER:
                {
                    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _sequenceNumber = i.number;
                    break;
                }
                case UMRpcMessageTAG_COMMAND:
                {
                    UMASN1Integer *i =  [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _command = i.number;
                    break;
                }
                case UMRpcMessageTAG_FLAGS:
                {
                    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _flags = i.number;
                    break;
                }
                case UMRpcMessageTAG_STATUS:
                {
                    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:o context:context];
                    _status = i.number;
                    break;
                }
                case UMRpcMessageTAG_ERROR:
                {
                    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:o context:context];
                    _error = u.stringValue;
                    break;
                }
                case UMRpcMessageTAG_PAYLOAD:
                {
                    _payload = o;
                    break;
                }
            }
        }
        o = [self getObjectAtPosition:pos++];
    }
    return self;
}

- (NSString *) objectName
{
    return @"UMRpcMessage";
}


- (UMSynchronizedSortedDictionary *) objectValue
{
    UMSynchronizedSortedDictionary *dict = [[UMSynchronizedSortedDictionary alloc]init];
    if(_sequenceNumber)
    {
        dict[@"sequenceNumber"] = _sequenceNumber;
    }
    if(_command)
    {
        dict[@"command"]        = _command;
        
    }
    if(_flags)
    {
        dict[@"flags"]              = _flags;
        dict[@"flags-description"]  = [UMRpcMessage flagsDescription:_flags];
    }
    if(_status)
    {
        dict[@"status"]             = _status;
        dict[@"status-description"] = [UMRpcMessage statusDescription:_status];
    }
    if(_error)
    {
        dict[@"error"]        = _error;
    }
    if(_payload)
    {
        dict[@"payload"]        = _payload.objectValue;
    }
    return dict;
}

- (void)setFlag:(UMRpcFlag)flag
{
    int f = _flags.intValue;
    f = f | flag;
    _flags = @(f);
}

-(void)clearFlag:(UMRpcFlag)flag
{
    int f = _flags.intValue;
    f = f &  ~flag;
    _flags = @(f);
}


- (BOOL)isFlagSet:(UMRpcFlag)flag
{
    if(_flags==NULL)
    {
        return NO;
    }
    int f = _flags.intValue;
    if(f & flag)
    {
        return YES;
    }
    return NO;
}


+ (NSString *)flagsDescription:(NSNumber *)flagsIn
{
    int flags = flagsIn.intValue;
    if(flags==0)
    {
        return @"NO_FLAGS_SET";
    }
    NSMutableArray *a = [[NSMutableArray alloc]init];
    if(flags & UMRpcFlag_IS_RESPONSE)
    {
        [a addObject:@"RESPONSE"];
    }
    if(flags & UMRpcFlag_CLOSING_CONNECTION)
    {
        [a addObject:@"CLOSING_CONNECTION"];
    }
    return [a componentsJoinedByString:@","];
}

+ (NSString *)statusDescription:(NSNumber *)status
{
    switch(status.intValue)
    {
        case UMRpcError_NOT_CONNECTED:
            return @"NOT_CONNECTED";
        case UMRpcError_PENDING:
            return @"PENDING";
        case    UMRpcError_UNDEFINED:
            return @"UNDEFINED";
        case    UMRpcError_NO_ERROR:
            return @"NO_ERROR";
        case UMRpcError_UNSUPPORTED_COMMAND:
            return @"UNSUPPORTED_COMMAND";
        case UMRpcError_PARAMETER_ERROR:
            return @"PARAMETER_ERROR";
        case UMRpcError_INVALID_STATE:
            return @"INVALID_STATE";
        case UMRpcError_INVALID_INSTANCE:
            return @"INVALID_INSTANCE";
        case UMRpcError_NOT_AUTHORIZED:
            return @"NOT_AUTHORIZED";
        caseUMRpcError_API_VERSION_MISMATCH:
            return @"API_VERSION_MISMATCH";
        case UMRpcError_CONNECTION_ERROR:
            return @"CONNECTION_ERROR";
        case UMRpcError_WRITE_FAILURE:
            return @"WRITE_FAILURE";
        case UMRpcError_INSERT_FAILURE:
            return @"INSERT_FAILURE";
        case UMRpcError_UPDATE_FAILURE:
            return @"UPDATE_FAILURE";
        case UMRpcError_LOAD_FAILURE:
            return @"LOAD_FAILURE";
        case UMRpcError_NOT_FOUND:
            return @"NOT_FOUND";
        case UMRpcError_DELETE_FAILURE:
            return @"DELETE_FAILURE";
        case UMRpcError_NO_DB_SESSIONS_AVAILABLE:
            return @"NO_DB_SESSIONS_AVAILABLE";
        case UMRpcError_DB_ERROR:
             return @"DB_ERROR";
        case UMRpcError_SYNTAX_ERROR:
            return @"SYNTAX_ERROR";

    }
    return @"(unknown)";
}
    
@end

