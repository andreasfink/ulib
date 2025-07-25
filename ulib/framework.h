//
//  framework.h
//  ulib
//
//  Created by Andreas Fink on 25.06.2025.
//


/*
* this is the only place where the Foundation framework should be included
* alternatively ObjFW might be used instead in the future
*/

#if defined(USE_OBJFW)

#import <ObjFW/ObjFW.h>

#else

#import <Foundation/Foundation.h>

#endif

