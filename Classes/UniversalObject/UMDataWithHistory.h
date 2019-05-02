//
//  UMDataWithHistory.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
#import "UMObjectWithHistory.h"
/*!
 @class UMDataWithHistory
 @brief A NSData which remembers its previous value and if it has been modified

 UMDataWithHistory is a object holding a NSData and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
 */

@interface UMDataWithHistory : UMObjectWithHistory
{
}


- (void)setData:(NSData *)newValue;
- (NSData *)data;
- (NSData *)currentData;
- (NSData *)oldData;
- (NSString *)nonNullString;
- (NSString *)oldNonNullString;
- (void) loadFromString:(NSString *)str;
+ (UMDataWithHistory *)dataWithHistoryWithData:(NSData *)s;

@end
