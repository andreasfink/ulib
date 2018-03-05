//
//  UMTask.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMTask.h"
#import "UMMutex.h"
#import "UMBackgrounder.h"
#import "UMThreadHelpers.h"

@implementation UMTask
@synthesize name;
@synthesize enableLogging;
@synthesize sync;

- (UMTask *)initWithName:(NSString *)n
{
    self = [super init];
    if(self)
    {
        self.name = n;
        _runMutex = [[UMMutex alloc]initWithName:@"umtask-lock"];
    }
    return self;
}

- (void)runOnBackgrounder:(UMBackgrounder *)bg
{
    [_runMutex lock];
    @try
    {
        ulib_set_thread_name([NSString stringWithFormat:@"%@ (executing: %@)",bg.name,self.name]);
        if(enableLogging)
        {
            if(self.name==NULL)
            {
                NSLog (@"self.name is NULL!");
            }
            NSLog(@"Task %@ execution on backgrounder %@",self.name,bg.name);
        }
        if(_synchronizeMutex)
        {
            [_synchronizeMutex lock];
            [self main];
            [_synchronizeMutex unlock];
        }
        else
        {
            if((_synchronizeObject) && (_synchronizeObject!=self)) /* self is already synchronized */
            {
                @synchronized(_synchronizeObject)
                {
                    [self main];
                }
            }
            else
            {
                [self main];
            }
        }
    }
    @finally
    {
        [_runMutex unlock];
    }
    _synchronizeObject=NULL; /* we need to break the link to the synchronized object as it might hold us
                             otherwise we might never get released from memory */
    _retainObject = NULL;
}

- (void)main
{
    NSLog(@"empty task");
}

@end
