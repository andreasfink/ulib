//
//  NSNumber+HiearchicalDescription.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "NSNumber+HierarchicalDescription.h"


@implementation NSNumber(HiearchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	return [NSString stringWithFormat:@"%@Number: %ld",prefix,(long)[self integerValue]];
}

@end
