//
//  NSString+HierarchicalDescription.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (HierarchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix;  /*!< convert a NSString to a string in a human readable fashion with identation (prefix) being properly handled */
- (NSString *)increasePrefix;
- (NSString *)removeFirstAndLastChar;

@end
