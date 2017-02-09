//
//  UMDoubleWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMDoubleWithHistory.h"

@implementation UMDoubleWithHistory

@synthesize currentValue;
@synthesize oldValue;

- (id)init
{
    self = [super init];
    if(self)
	{
        // Initialization code here.
    }
    
    return self;
}
-(void)setDouble:(double)newValue
{
    oldValue = currentValue;
    currentValue = newValue;
    if(currentValue != oldValue)
        isModified = YES;
}

- (double)double
{
    return currentValue;
}

- (double)oldDouble
{
    return oldValue;
}

- (BOOL) hasChanged
{
    return isModified;
}

- (void) clearChangedFlag
{
    isModified = NO;
}

-(NSString *)nonNullString
{
    return [NSString stringWithFormat:@"%lf",currentValue];
}

- (NSString *)oldNonNullString
{
    return [NSString stringWithFormat:@"%lf",oldValue];
}

- (void)clearDirtyFlag
{
    self.oldValue = self.currentValue;
    [self clearChangedFlag];
}

- (void) loadFromString:(NSString *)str
{
    self.currentValue = atof([str UTF8String]);
}


- (NSString *)description
{
    if(isModified)
    {
        return [NSString stringWithFormat:@"Double '%8.4lf' (unmodified)",currentValue];
    }
    else
    {
        return [NSString stringWithFormat:@"Double '%8.4lf' (changed from '%8.4lf')",currentValue,oldValue];
    }
}
@end
