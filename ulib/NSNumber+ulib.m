//
//  NSNumber+ulib.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSNumber+ulib.h>


@implementation NSNumber(ulib)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	return [NSString stringWithFormat:@"%@Number: %ld",prefix,(long)[self integerValue]];
}

@end
