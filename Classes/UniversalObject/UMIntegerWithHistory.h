//
//  UMIntegerWithHistory.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@interface UMIntegerWithHistory : UMObject

{
@private    
    NSInteger    oldValue;
    NSInteger    currentValue;
    BOOL         isModified;
}

@property(readwrite,assign) NSInteger    oldValue;
@property(readwrite,assign) NSInteger    currentValue;

- (void)setInteger:(NSInteger)newValue;
- (NSInteger )integer;
- (NSInteger)oldInteger;
- (BOOL) hasChanged;
- (void) clearChangedFlag;
- (NSString *)nonNullString;
- (NSString *)oldNonNullString;
- (void)clearDirtyFlag;
- (void) loadFromString:(NSString *)str;
+(UMIntegerWithHistory *)integerWithHistoryWithInteger:(int)i;
@end
