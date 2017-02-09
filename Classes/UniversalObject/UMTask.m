//
//  UMTask.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMTask.h"
#import "UMLock.h"
#import "UMBackgrounder.h"

@implementation UMTask
@synthesize name;
@synthesize enableLogging;
@synthesize sync;
@synthesize synchronizeObject;

- (UMTask *)initWithName:(NSString *)n
{
    self = [super init];
    if(self)
    {
        self.name = n;
    }
    return self;
}

- (void)runOnBackgrounder:(UMBackgrounder *)bg
{
    @synchronized(self)
    {
        @autoreleasepool
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
            if((synchronizeObject) && (synchronizeObject!=self)) /* self is already synchronized */
            {
                @synchronized(synchronizeObject)
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
    synchronizeObject=NULL; /* we need to break the link to the synchronized object as it might hold us
                             otherwise we might never get released from memory */
}

- (void)main
{
    NSLog(@"empty task");
}

@end
