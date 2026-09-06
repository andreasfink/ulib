//
//  UMRpcMessage.h
//  ulibrpc
//
//  Created by Andreas Fink on 20.08.2026.
//

#import <ulibasn1/UMASN1Object.h>
#import <ulibasn1/UMASN1Sequence.h>
#import <ulibasn1/UMASN1UTF8String.h>
#import <ulibasn1/UMASN1Integer.h>

#import <ulibasn1/UMRpcFlag.h>

typedef enum UMRpcMessageTAG
{
    UMRpcMessageTAG_SEQUENCE_NUMBER = 0,
    UMRpcMessageTAG_COMMAND         = 1,
    UMRpcMessageTAG_FLAGS           = 2,
    UMRpcMessageTAG_STATUS          = 3,
    UMRpcMessageTAG_ERROR           = 4,
    UMRpcMessageTAG_PAYLOAD         = 5,
} UMRpcMessageTAG;

@interface UMRpcMessage : UMASN1Sequence
{
    NSNumber        *_sequenceNumber;
    NSNumber        *_command;
    NSNumber        *_flags;
    NSNumber        *_status;
    NSString        *_error;
    UMASN1Object    *_payload;
    id              _callbackObject; /* placeholder to pass the original passed object back on a handler call */
}



@property(readwrite,atomic,strong)  NSNumber    *sequenceNumber;
@property(readwrite,atomic,strong)  NSNumber    *command;
@property(readwrite,atomic,strong)  NSNumber    *flags;
@property(readwrite,atomic,strong)  NSNumber    *status;
@property(readwrite,atomic,strong)  NSString    *error;
@property(readwrite,atomic,strong)  UMASN1Object *payload;
@property(readwrite,atomic,strong) id callbackObject;

- (UMRpcMessage *) processAfterDecodeWithContext:(id)context;
- (NSString *) objectName;
- (UMSynchronizedSortedDictionary *) objectValue;

- (void)setFlag:(UMRpcFlag)flag;
- (void)clearFlag:(UMRpcFlag)flag;
- (BOOL)isFlagSet:(UMRpcFlag)flag;
+ (NSString *)statusDescription:(NSNumber *)status;


@end
