//
//  UMSctpTask_AdminDetach.h
//  ulib
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/ulib.h>
@class UMLayerSctp;
#import <ulib/UMLayerSctpUserProtocol.h>

@interface UMSctpTask_AdminDetach : UMLayerTask
{
    id       userId;
}

@property(readwrite,strong) id userId;

- (UMSctpTask_AdminDetach *)initWithReceiver:(UMLayerSctp *)rx
                                      sender:(id<UMLayerSctpUserProtocol>)tx
                                      userId:(id)uid;
- (void)main;

@end
#endif
