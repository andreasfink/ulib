//
//  NSObject+HierarchicalDescription.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "NSObject+HierarchicalDescription.h"


@implementation NSObject(HierarchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix
{
	return [NSString stringWithFormat:@"%@Object: %@",prefix,[self description]];
}

@end
