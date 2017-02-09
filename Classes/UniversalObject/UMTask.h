//
//  UMTask.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"
@class UMBackgrounder;

/*!
 @class UMTask
 @brief A UMTask is a work task which can be executed in the background, thrown on to queues etc.
    Usually the object is subclassed and the "main" method is being implemented to do something useful.
    A UMTask can be synchronized to another object (the "synchronizeObject") have a name and 
    can have logging.
*/

@interface UMTask : UMObject
{
    NSString        *name;
    BOOL            enableLogging;
    BOOL            sync;
    id              synchronizeObject;
}
@property(strong)   NSString *name;
@property(assign)   BOOL enableLogging;
@property(assign)   BOOL sync;
@property(strong)   id synchronizeObject;


- (UMTask *)initWithName:(NSString *)name;
- (void)runOnBackgrounder:(UMBackgrounder *)bg;
- (void)main;

@end
