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

@property(readwrite,assign) BOOL    isDirty;
@property(readwrite,strong) id      currentValue;
@property(readwrite,strong) id      previousValue;
- (void)clearDirty;
@end

