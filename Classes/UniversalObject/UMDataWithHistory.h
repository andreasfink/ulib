//
//  UMDataWithHistory.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMObject.h"

@interface UMDataWithHistory : UMObject
{
@private
    NSData      *oldValue;
    NSData      *currentValue;
    BOOL        isModified;
}

@property (readwrite,strong) NSData *oldValue;
@property (readwrite,strong) NSData *currentValue;

- (void)setData:(NSData *)newValue;
- (NSData *)data;
- (NSData *)oldData;
- (BOOL) hasChanged;
- (void) clearChangedFlag;
- (NSString *)nonNullString;
- (NSString *)oldNonNullString;
- (void)clearDirtyFlag;
- (void) loadFromString:(NSString *)str;

@end
