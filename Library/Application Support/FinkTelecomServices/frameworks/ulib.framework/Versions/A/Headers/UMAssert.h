//
//  UMAsset.h
//  ulib
//
//  Created by Andreas Fink on 31.01.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#define UMAssert(condition, desc, ...)						\
    do 										\
    {										\
        if (!(condition)) 							\
        {									\
            [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd 	\
            object:self file:[NSString stringWithUTF8String:__FILE__] 		\
            lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; 		\
        }									\
    } while(0)


#define UMAssertInFunction(condition, desc, ...)						\
    do 										\
    {										\
        if (!(condition)) 							\
        {									\
            [[NSAssertionHandler currentHandler] handleFailureInFunction:@(__FUNCTION__) 	\
            file:[NSString stringWithUTF8String:__FILE__] 		\
            lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; 		\
        }									\
    } while(0)
