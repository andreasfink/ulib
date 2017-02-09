//
//  UMDoubleWithHistory.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

/*!
 @class UMDoubleWithHistory
 @brief A NSData which remembers its previous value and if it has been modified

 UMDoubleWithHistory is a object holding a double value and its previous value.
 It can be used to hold data which is potentially modified at some point in time
 and then remember if it has been modified and what the old values are.
 Used for example in database access to only modify the fields which have changed
 (and if none has changed, not doing any query at all).
 */

@interface UMDoubleWithHistory : UMObject
{
@private    
    double    oldValue;
    double    currentValue;
    BOOL        isModified;
}

@property(readwrite,assign) double oldValue;
@property(readwrite,assign) double currentValue;

- (void)setDouble:(double)newValue;
- (double)double;
- (double)oldDouble;
- (BOOL) hasChanged;
- (void)clearDirtyFlag;
- (void) clearChangedFlag;
- (NSString *)nonNullString;
- (NSString *)oldNonNullString;
- (void) loadFromString:(NSString *)str;

@end
