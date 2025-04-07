//
//  UMDirtyObject.h
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import <ulib/UMObject.h>

@interface UMDirtyObject : UMObject
{ 
    BOOL    _isDirty;
    id      _currentValue;
    id      _previousValue;
}

@property(readwrite,assign,atomic) BOOL    isDirty;
@property(readwrite,strong,atomic) id      currentValue;
@property(readwrite,strong,atomic) id      previousValue;
- (void)clearDirty;  /*!< same as isDirty=NO flag but the new value is now the old value */

@end

