//
//  UMDataWithHistory.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMDataWithHistory.h"
#import "NSData+UniversalObject.h"
#import "NSString+UniversalObject.h"

@implementation UMDataWithHistory
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


-(void)setData:(NSData *)newValue
{
    oldValue = currentValue;
    currentValue = newValue;
    if(currentValue != oldValue)
        isModified = YES;
}

- (NSData *)data
{
    return currentValue;
}

-(NSData *)oldData
{
    return oldValue;
}

-(NSString *)nonNullString
{
    if(currentValue==NULL)
        return @"";
    return [currentValue hexString];
}

- (NSString *)oldNonNullString;
{
    if(oldValue==NULL)
        return @"";
    return [oldValue hexString];
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
    self.currentValue = [str unhexedData];
}

- (NSString *)description
{
    if(isModified)
    {
        return [NSString stringWithFormat:@"Data '%@' (unmodified)",[currentValue hexString]];
    }
    else
    {
        return [NSString stringWithFormat:@"Data '%@' (changed from '%@')",[currentValue hexString],[oldValue hexString]];
    }
}

@end
