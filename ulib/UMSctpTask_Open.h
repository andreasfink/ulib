//
//  UMSctpTask_Open.h
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/ulib.h>
#import <ulib/UMLayerSctpUserProtocol.h>

@class UMLayerSctp;

@interface UMSctpTask_Open : UMLayerTask
{
    BOOL        _sendAbortFirst;
    NSString    *_reason;
}
@property(readwrite,assign) BOOL sendAbortFirst;
@property(readwrite,strong) NSString *reason;

- (UMSctpTask_Open *)initWithReceiver:(UMLayerSctp *)rx sender:(id<UMLayerSctpUserProtocol>)tx;
- (void)main;
@end
#endif
