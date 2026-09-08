//
//  UMSctpTask_AdminAttach.h
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMLayerTask.h>
@class UMLayerSctp;
@class UMLayerSctpUserProfile;

#import <ulib/UMLayerSctpUserProtocol.h>


@interface UMSctpTask_AdminAttach : UMLayerTask
{
    UMLayerSctpUserProfile *profile;
    id       userId;
}
@property(readwrite,strong) UMLayerSctpUserProfile *profile;
@property(readwrite,strong) id userId;

- (UMSctpTask_AdminAttach *)initWithReceiver:(UMLayerSctp *)rx
                                      sender:(id<UMLayerSctpUserProtocol>)tx
                                     profile:(UMLayerSctpUserProfile *)p
                                      userId:(id)uid;
- (void)main;

@end
#endif
