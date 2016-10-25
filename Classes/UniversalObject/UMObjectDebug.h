//
//  UMObjectDebug.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

/*
 
   UMObjectDebug is a object handled like UMObject but allows
   to log stuff during retain/release thats why its compiled
   specifically without ARC
 
   Only useful for debuggging. You would simply inherit your object from
   UMObjectDebug instead of UMObject so you can track where your objects 
   gets finally deallocated which you can't trap with ARC enabled

 */

#import "UMObject.h"

@interface UMObjectDebug : UMObject
{
    int ulib_retain_counter;
}


- (void)retainDebug;
- (void)releaseDebug;
- (void)enableRetainReleaseLogging;

@end
