//
//  UMASN1ObjectPrimitive.m
//  ulibasn1
//
//  Created by Andreas Fink on 06/04/16.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulibasn1/UMASN1ObjectPrimitive.h>

@implementation UMASN1ObjectPrimitive

- (UMASN1ObjectPrimitive *)init
{
    self = [super init];
    if(self)
    {
        [self.asn1_tag setTagIsPrimitive];
    }
    return self;
}


- (UMASN1ObjectPrimitive *)initWithBerData:(NSData *)data atPosition:(NSUInteger *)pos context:(id)context
{
    self = [super initWithBerData:data atPosition:pos context:context];
    if(self)
    {
        [self.asn1_tag setTagIsPrimitive];
    }
    return self;
}

@end
