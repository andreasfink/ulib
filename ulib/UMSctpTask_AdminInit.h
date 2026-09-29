//
//  UMSctpTask_AdminInit.h
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMLayerTask.h>
#import <ulib/UMLayerSctpUserProtocol.h>

@class UMLayerSctp;
@interface UMSctpTask_AdminInit : UMLayerTask

- (UMSctpTask_AdminInit *)initWithReceiver:(UMLayerSctp *)receiver sender:(id<UMLayerSctpUserProtocol>)sender;

@end

