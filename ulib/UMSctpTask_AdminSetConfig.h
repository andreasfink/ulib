//
//  UMSctpTask_AdminSetConfig.h
//  ulib
//
//  Created by Andreas Fink on 01.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMLayerTask.h>
#import <ulib/UMLayerSctpUserProtocol.h>

@class UMLayerSctp;

@interface UMSctpTask_AdminSetConfig : UMLayerTask
{
    NSDictionary *config;
    id          appContext;
}
@property(readwrite,strong)     NSDictionary *config;

- (UMSctpTask_AdminSetConfig *)initWithReceiver:(UMLayerSctp *)receiver
                                         config:(NSDictionary *)cfg
                             applicationContext:(id)appContext;
- (void)main;
- (id)appContext;
@end
#endif
