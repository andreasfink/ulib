//
//  UMStringWithHistory.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

/*!
 @class UMStringWithHistory
 @brief A NSString which remembers its previous value

 UMStringWithHistory is a object holding a NSString and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
*/

@interface UMStringWithHistory : UMObject
{
@private    
    NSString    *oldValue;      /*!< the previous string value */
    NSString    *currentValue;  /*!< the current string value */
    BOOL        isModified;     /*!< BOOL telling us if there was any change */
}

@property (readwrite,strong)    NSString    *oldValue;
@property (readwrite,strong)    NSString    *currentValue;

- (void)setString:(NSString *)newValue; /*!< set to a new value. if different the isModified flag is raised */
- (NSString *)string; /*!< the current value */
- (NSString *)oldString; /*!y the previous value */
- (BOOL) hasChanged; /*!< has it changed since we cleared the flag? */
- (void) clearChangedFlag; /*!< flush the has changed flag (for example after updating db) */
- (NSString *)nonNullString; /*!< returns the current value and if its NULL it returns an empty string */
- (NSString *)oldNonNullString; /*!< returns the old value and if its NULL it returns an empty string */
- (void)clearDirtyFlag; /*!< same as clearChanged flag but the new value is now the old value */
- (void) loadFromString:(NSString *)str; /*!< initialize with a string */

@end
