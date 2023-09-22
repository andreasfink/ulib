//
//  NSData+HierarchicalDescription.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData(HiearchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix; /*!< convert a NSData to a string in a human readable fashion with identation (prefix) being properly handled */
- (NSString *)stringForDumping;
- (NSString *)dump;

@end
