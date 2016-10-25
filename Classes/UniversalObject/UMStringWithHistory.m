//
//  UMStringWithHistory.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMStringWithHistory.h"

@implementation UMStringWithHistory
@synthesize oldValue;
@synthesize currentValue;

- (id)init
{
    self = [super init];
    if (self) 
    {
        // Initialization code here.
    }
    
    return self;
}


-(void)setString:(NSString *)newValue
{
    oldValue = currentValue;
    currentValue = newValue;
    if(![currentValue isEqualToString:oldValue])
        isModified = YES;
}

- (NSString *)string
{
    return currentValue; 
}

- (NSString *)nonNullString
{
    if(currentValue==NULL)
        return @"";
    return currentValue;
}

- (NSString *)oldNonNullString
{
    if(oldValue==NULL)
        return @"";
    return oldValue;
}


-(NSString *)oldString
{
    return oldValue;
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
    self.currentValue = str;
}

- (NSString *)description
{
    if(isModified)
    {
        return [NSString stringWithFormat:@"String '%@' (unmodified)",currentValue];
    }
    else
    {
        return [NSString stringWithFormat:@"String '%@' (changed from '%@')",currentValue,oldValue];
    }
}


@end
