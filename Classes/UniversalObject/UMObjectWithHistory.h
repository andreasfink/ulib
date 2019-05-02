//
//  UMObjectWithHistory.h
//  ulib
//
//  Created by Andreas Fink on 02.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

/*
 @class UMObjectWithHistory
 @brief A UMObject which remembers its previous value

 UMObjectWithHistory is a object holding a UMObject and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
 */

@interface UMObjectWithHistory : UMObject
{
@protected
    NSObject *_oldValue;      /*!< the previous object value */
    NSObject *_currentValue;  /*!< the current object value */
    BOOL     _isModified;     /*!< BOOL telling us if there was any change */
}

@property (readwrite,strong)    NSObject *oldValue;
@property (readwrite,strong)    NSObject *currentValue;

- (void)setValue:(NSObject *)newValue; /*!< set to a new value. if different the isModified flag is raised */
- (NSObject *)value; /*!< the current value */
- (NSObject *)oldValue; /*!y the previous value */
- (BOOL) hasChanged; /*!< has it changed since we cleared the flag? */
- (void) clearChangedFlag; /*!< flush the has changed flag (for example after updating db) */
- (void)clearDirtyFlag; /*!< same as clearChanged flag but the new value is now the old value */
- (void) loadFromValue:(NSObject *)v;        /*!< initialize with a new object */
- (void) loadFromString:(NSObject *)str;     /*!< initialize with a new string object */

+ (UMObjectWithHistory *)objectWithHistoryWithObject:(NSObject *)o;

@end
