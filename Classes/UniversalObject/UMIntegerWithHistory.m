//
//  UMIntegerWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMIntegerWithHistory.h"

@implementation UMIntegerWithHistory

@synthesize oldValue;
@synthesize currentValue;

- (id)init
{
    self = [super init];
    if(self)
	{
        // Initialization code here.
    }
    
    return self;
}

-(void)setInteger:(NSInteger)newValue
{
    oldValue = currentValue;
    currentValue = newValue;
    if(currentValue != oldValue)
        isModified = YES;
}

- (NSInteger)integer
{
    return currentValue;
}

- (NSInteger)oldInteger
{
    return oldValue;
}

-(NSString *)nonNullString
{
    return [NSString stringWithFormat:@"%ld",(long)currentValue];
}

- (NSString *)oldNonNullString;
{
    return [NSString stringWithFormat:@"%ld",(long)oldValue];
}

- (BOOL) hasChanged
{
    return isModified;
}

- (void) clearChangedFlag;
{
    isModified = NO;
}

- (void)clearDirtyFlag
{
    self.oldValue = self.currentValue;
    [self clearChangedFlag];
}

- (void) loadFromString:(NSString *)str
{
    self.currentValue = atol([str UTF8String]);
}


- (NSString *)description
{
    if(isModified)
    {
        return [NSString stringWithFormat:@"Integer '%ld' (unmodified)",(long)currentValue];
    }
    else
    {
        return [NSString stringWithFormat:@"Integer '%ld' (changed from '%ld')",(long)currentValue,(long) oldValue];
    }
}

+(UMIntegerWithHistory *)integerWithHistoryWithInteger:(int)i
{
    UMIntegerWithHistory *iwh = [[UMIntegerWithHistory alloc]init];
    [iwh setInteger:i];
    return iwh;
}

@end
