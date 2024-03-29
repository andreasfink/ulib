//
//  NSObject+HierarchicalDescription.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSObject+ulib.h>


@implementation NSObject(HierarchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	return [NSString stringWithFormat:@"%@Object: %@",prefix,[self description]];
}

@end
