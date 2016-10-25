//
//  UMDoubleWithHistory.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

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
