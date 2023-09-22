//
//  NSNumber+HiearchicalDescription.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSNumber+HierarchicalDescription.h>


@implementation NSNumber(HiearchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	return [NSString stringWithFormat:@"%@Number: %ld",prefix,(long)[self integerValue]];
}

@end
