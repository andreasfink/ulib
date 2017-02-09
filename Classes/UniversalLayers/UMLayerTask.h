//
//  UMLayerTask.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <Foundation/Foundation.h>
#import "UMTask.h"
#import "UMLayerUserProtocol.h"

@class UMThroughputCounter;

@class UMLayer;


@interface UMLayerTask : UMTask
{
    UMLayer                 *receiver;
    id<UMLayerUserProtocol> sender;
    BOOL                    requiresSynchronisation;
}

@property(readwrite,strong) UMLayer *                   receiver;
@property(readwrite,strong) id<UMLayerUserProtocol>     sender;
@property(readwrite,assign) BOOL                        requiresSynchronisation;


- (UMLayerTask *)initWithName:(NSString *)n receiver:(UMLayer *)rx sender:(id<UMLayerUserProtocol>)tx;
- (UMLayerTask *)initWithName:(NSString *)n receiver:(UMLayer *)rx sender:(id<UMLayerUserProtocol>)tx requiresSynchronisation:(BOOL)sync;

@end
