//
//  UMLayer.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

//#import <pthread.h>

#import "UMObject.h"
#import "UMLogLevel.h"

@class UMThroughputCounter;
@class UMTask;
@class UMTaskQueue;
@class UMTaskQueueMulti;
@class UMLayerTask;
@class UMLayerAckRequest;
@class UMHistoryLog;

#define UMLAYER_ADMIN_QUEUE             0
#define UMLAYER_LOWER_PRIORITY_QUEUE    1
#define UMLAYER_UPPER_PRIORITY_QUEUE    2
#define UMLAYER_LOWER_QUEUE             3
#define UMLAYER_UPPER_QUEUE             4
#define UMLAYER_QUEUE_COUNT             5


@interface UMLayer : UMObject
{
    NSString                            *_layerName;
    NSString                            *_layerType;
    UMTaskQueueMulti                    *_taskQueue;
    UMThroughputCounter					*_lowerQueueThroughput;
    UMThroughputCounter					*_upperQueueThroughput;
    UMThroughputCounter					*_adminQueueThroughput;
    NSString                            *_logFileName;
    UMHistoryLog                        *_layerHistory;
    UMLogLevel                          _logLevel;
    BOOL                                _enable;
    BOOL                                _isSharedQueue;
}


- (UMLayer *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq;
- (UMLayer *)initWithTaskQueueMulti:(UMTaskQueueMulti *)tq name:(NSString *)name;

@property(readwrite,strong) NSString            *layerName;
@property(readwrite,strong) NSString            *layerType;
@property(readwrite,strong) UMTaskQueueMulti    *taskQueue;
@property(readwrite,strong) UMThroughputCounter *lowerQueueThroughput;
@property(readwrite,strong) UMThroughputCounter *upperQueueThroughput;
@property(readwrite,strong) UMThroughputCounter *adminQueueThroughput;
@property(readwrite,strong) NSString            *logFileName;
@property(readwrite,strong) UMHistoryLog        *layerHistory;

@property(readwrite,assign,atomic)              UMLogLevel logLevel;
@property(readwrite,assign) BOOL                enable;
@property(readwrite,assign) BOOL                isSharedQueue;

- (void)queueFromLower:(UMLayerTask *)task;
- (void)queueFromUpper:(UMLayerTask *)task;
- (void)queueFromAdmin:(UMLayerTask *)task;
- (void)queueFromLowerWithPriority:(UMLayerTask *)task;
- (void)queueFromUpperWithPriority:(UMLayerTask *)task;

- (void)adminInit;
- (void)adminAttachFor:(UMLayer *)attachingLayer userId:(id)uid;
- (void)adminAttachConfirm:(UMLayer *)attachedLayer userId:(id)uid;
- (void)adminAttachFail:(UMLayer *)attachedLayer userId:(id)uid;

#pragma mark -
#pragma mark Layer Logging

- (void)logDebug:(NSString *)s;
- (void)logInfo:(NSString *)s;
- (void)logWarning:(NSString *)s;
- (void)logMinorError:(NSString *)s;
- (void)logMajorError:(NSString *)s;
- (void)logMajorError:(int)err location:(NSString *)location;
- (void)logMinorError:(int)err location:(NSString *)location;
- (void)logPanic:(NSString *)s;
- (void)addLayerConfig:(NSMutableDictionary *)config;
- (void)readLayerConfig:(NSDictionary *)config;
- (void)dump:(NSFileHandle *)filehandler;
@end
