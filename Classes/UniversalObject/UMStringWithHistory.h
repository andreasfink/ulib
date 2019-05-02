//
//  UMStringWithHistory.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"
#import "UMObjectWithHistory.h"

/*!
 @class UMStringWithHistory
 @brief A NSString which remembers its previous value

 UMStringWithHistory is a object holding a NSString and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
*/

@interface UMStringWithHistory : UMObjectWithHistory
{
}

- (void)setString:(NSString *)newString;
- (NSString *)string;

- (NSString *)currentString;
- (NSString *)oldString;
- (NSString *)nonNullString;
- (NSString *)oldNonNullString;
- (void) loadFromString:(NSString *)str;

@end
