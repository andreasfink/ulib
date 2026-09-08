//
//  UMSctpTask_Manual_ForceOutOfService.h
//  ulib
//
//  Created by Andreas Fink on 29.11.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMLayerTask.h>
#import <ulib/UMLayerSctp.h>
#import <ulib/UMLayerSctpUserProtocol.h>

@interface UMSctpTask_Manual_ForceOutOfService : UMLayerTask
{
    
}

- (UMSctpTask_Manual_ForceOutOfService *)initWithReceiver:(UMLayerSctp *)rx sender:(id<UMLayerSctpUserProtocol>)tx;
- (void)main;

@end
