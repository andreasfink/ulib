//
//  UMSctpTask_Close.h
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/ulib.h>
#import <ulib/UMLayerSctpUserProtocol.h>

@class UMLayerSctp;

@interface UMSctpTask_Close : UMLayerTask
{
    NSString *_reason;
}
@property(readwrite,strong,atomic) NSString *reason;

- (UMSctpTask_Close *)initWithReceiver:(UMLayerSctp *)rx sender:(id<UMLayerSctpUserProtocol>)tx;
- (void)main;
@end
#endif
