//
//  UMIntegerWithHistory.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"
#import "UMObjectWithHistory.h"

/*!
 @class UMIntegerWithHistory
 @brief A NSDate which remembers its previous value and if it has been modified

 UMIntegerWithHistory is a object holding a NSInteger and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
 */

@interface UMIntegerWithHistory : UMObjectWithHistory
{
}


- (void)setInteger:(NSInteger)newValue;
- (NSInteger)integer;
- (NSInteger)currentInteger;
- (NSInteger)oldInteger;

- (NSString *)nonNullString;
- (NSString *)oldNonNullString;
- (void) loadFromString:(NSString *)str;

+ (UMIntegerWithHistory *)integerWithHistoryWithInteger:(int)i;
@end
