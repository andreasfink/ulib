//
//  UMConfigLocation.m
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
#import "UMConfigLocation.h"

@implementation UMConfigLocation

@synthesize filename; 
@synthesize line_no; 
@synthesize line; 

- (UMConfigLocation *)initWithFilename:(NSString *)f
{
    if((self=[super init]))
    {
        self.filename = f;
    }
    return self;
}


@end
