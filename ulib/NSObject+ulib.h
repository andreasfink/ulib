//
//  NSObject+ulib.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#ifndef NSObject_HierarchicalDescription_h
#define NSObject_HierarchicalDescription_h 1

@interface NSObject(ulib)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix;  /*!< convert a NSOjbect to a string in a human readable fashion with identation (prefix) being properly handled */

@end

#endif
