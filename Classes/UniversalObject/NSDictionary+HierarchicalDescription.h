//
//  NSDictionary+HierarchicalDescription.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary(HiearchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix; /*!< convert a NSDictionary to a string in a human readable fashion with identation (prefix) being properly handled */

@end
