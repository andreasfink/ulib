//
//  NSArray+HierarchicalDescription.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (HierarchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix; /*!< convert a NSArray to a string in a human readable fashion with identation (prefix) being properly increased */

@end
