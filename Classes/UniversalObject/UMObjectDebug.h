//
//  UMObjectDebug.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMObject.h"

/*!
 @class UMObjectDebug
 @brief The debugging version of UMObject

 UMObjectDebug is a object handled like UMObject but allows
 to log stuff during retain/release thats why its compiled
 specifically without ARC.

 Only useful for debuggging. You would simply inherit your object from
 UMObjectDebug instead of UMObject so you can track where your objects
 gets finally deallocated which you can't trap with ARC enabled by setting
 breakpoints at retainDebug and releaseDebug or by overloading these methods.

 */

@interface UMObjectDebug : UMObject
{
    int ulib_retain_counter;
}

- (void)retainDebug; /*!< gets called at retain event */
- (void)releaseDebug; /*!< gets called when a release occurs */
- (void)enableRetainReleaseLogging; /*!< if set retain/release cycles get logged to the console with NSLog */

@end
