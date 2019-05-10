//
//  UMConstantStringsDict.h
//  ulib
//
//  Created by Andreas Fink on 09.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMMutex.h"

/*
 	the purpose of this class is to collect a bunch of constant
 	strings into a dictionary to be used as cpointers.
 	This means you can only append a NSString and get cpointers
 	out of it which will never been deallocated.

 	This way a c pointer can be used throught the code pointing to this
 	constant string and we are sure the cstring never is deallocated.

*/

@interface UMConstantStringsDict : NSObject
{
	NSMutableDictionary 		*_dict;
	UMMutex						*_lock;
}

+ (UMConstantStringsDict *)sharedInstance;
- (const char *)asciiStringFromNSString:(NSString *)str;

@end

