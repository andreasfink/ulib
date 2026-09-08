//
//  UMSctpTask_Manual_InService.h
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/ulib.h>

#import <ulib/UMLayerSctp.h>
#import <ulib/UMLayerSctpUserProtocol.h>

@interface UMSctpTask_Manual_InService : UMLayerTask
{
}

- (UMSctpTask_Manual_InService *)initWithReceiver:(UMLayerSctp *)rx sender:(id<UMLayerSctpUserProtocol>)tx;
- (void)main;

@end
#endif
