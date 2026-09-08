//
//  UMLayerSctpOverTcp.h
//  ulibsctp
//
//  Created by Andreas Fink on 11.12.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//
#if defined(HAVE_SCTP_SCTP_H) || defined(HAVE_NETINET_SCTP_H)

#import <ulib/UMLayerSctp.h>

@interface UMLayerSctpOverTcp : UMLayerSctp

@end
#endif
