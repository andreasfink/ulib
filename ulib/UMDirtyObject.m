//
//  UMDirtyObject.m
//  ulib
//
//  Created by Andreas Fink on 04.03.2025.
//

#import "UMDirtyObject.h"

@implementation UMDirtyObject

- (void)clearDirty
{
    _isDirty = NO;
    _previousValue = _currentValue;
}

- (id)proxyForJson
{
    return _currentValue;
}

@end
