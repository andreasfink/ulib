//
//  UMStringWithHistory.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@interface UMStringWithHistory : UMObject
{
@private    
    NSString    *oldValue;
    NSString    *currentValue;
    BOOL        isModified;
}

@property (readwrite,strong)    NSString    *oldValue;
@property (readwrite,strong)    NSString    *currentValue;

- (void)setString:(NSString *)newValue;
- (NSString *)string;
- (NSString *)oldString;
- (BOOL) hasChanged;
- (void) clearChangedFlag;
- (NSString *)nonNullString;
- (NSString *)oldNonNullString;
- (void)clearDirtyFlag;
- (void) loadFromString:(NSString *)str;

@end
