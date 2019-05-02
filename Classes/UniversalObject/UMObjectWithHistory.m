//
//  UMObjectWithHistory.m
//  ulib
//
//  Created by Andreas Fink on 02.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObjectWithHistory.h"

@implementation UMObjectWithHistory


- (UMObjectWithHistory *)init
{
    self = [super init];
    if (self)
    {
        // Initialization code here.
        _isModified = NO;
    }
    return self;
}

- (void)setValue:(NSObject *)newValue; /*!< set to a new value. if different the isModified flag is raised */
{
    _oldValue = _currentValue;
    _currentValue = newValue;
    if(![_currentValue isEqualTo:_oldValue])
    {
        _isModified = YES;
    }
}

- (NSObject *)value
{
    return _currentValue;
}



- (BOOL) hasChanged
{
    return _isModified;
}

- (void) clearChangedFlag;
{
    _isModified = NO;
}

- (void)clearDirtyFlag
{
    _oldValue = _currentValue;
    _isModified = NO;
}

- (void) loadFromValue:(NSObject *)str
{
    _currentValue = str;
}

- (void) loadFromString:(NSObject *)str
{
    NSLog(@"UMObjectWithHistory: we dont know how to create this type of object (%@) from a string. Subclass this object and implement loadFromString", [self.class description]);
    _currentValue = NULL;
}

- (NSString *)description
{
    if(_isModified)
    {
        return [NSString stringWithFormat:@"Object '%@' (unmodified)",_currentValue];
    }
    else
    {
        return [NSString stringWithFormat:@"Object '%@' (changed from '%@')",_currentValue,_oldValue];
    }
}

+ (UMObjectWithHistory *)objectWithHistoryWithObject:(NSObject *)o
{
    UMObjectWithHistory *oh = [[UMObjectWithHistory alloc]init];
    [oh loadFromValue:o];
    return oh;
}


@end
