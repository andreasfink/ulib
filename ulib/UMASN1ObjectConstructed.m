//
//  UMASN1ObjectConstructed.m
//  ulibasn1
//
//  Created by Andreas Fink on 06/04/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1ObjectConstructed.h>

@implementation UMASN1ObjectConstructed


- (UMASN1ObjectConstructed *)init
{
    self = [super init];
    if(self)
    {
        [self.asn1_tag setTagIsConstructed];
        self.asn1_list = [[NSMutableArray alloc]init];
    }
    return self;
}

@end
