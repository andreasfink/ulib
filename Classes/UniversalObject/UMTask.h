//
//  UMTask.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMObject.h"
@class UMBackgrounder;

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
