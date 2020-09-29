//
//  UMTask.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"
#import "UMMutex.h"

@class UMBackgrounder;

/*!
 @class UMTask
 @brief A UMTask is a work task which can be executed in the background, thrown on to queues etc.
    Usually the object is subclassed and the "main" method is being implemented to do something useful.
    A UMTask can be synchronized to another object (the "synchronizeObject") have a name and 
    can have logging.
*/
@class UMTaskQueue;
@class UMTaskQueueMulti;

@interface UMTask : UMObject
{
    NSString        *_name;
    BOOL            _enableLogging;
    BOOL            _sync;
    id              _synchronizeObject; /* DEPRECIATED */
    UMMutex         *_synchronizeMutex; /* preferred */
    id              _retainObject; /* object to hold until task ends */
    UMMutex         *_runMutex;
    UMTaskQueue         __weak *_taskQueue;
    UMTaskQueueMulti    __weak *_taskQueueMulti;
    int                 _taskQueueMultiSubqueueIndex;
}
@property(strong)           NSString *name;
@property(assign,atomic)    BOOL enableLogging;
@property(assign)           BOOL sync;
@property(strong)           id synchronizeObject;   /* DEPRECIATED */
@property(readwrite,strong) UMMutex   *synchronizeMutex; /* preferred */
@property(strong)           id retainObject;
@property(readwrite,strong) UMMutex   *runMutex; /* preferred */
@property(readwrite,weak)   UMTaskQueue *taskQueue;
@property(readwrite,weak)   UMTaskQueueMulti *taskQueueMulti;
@property(assign,atomic)    int taskQueueMultiSubqueueIndex;




- (UMTask *)initWithName:(NSString *)name;
- (void)runOnBackgrounder:(UMBackgrounder *)bg;
- (void)startup;
- (void)main;
- (void)shutdown;
@end
