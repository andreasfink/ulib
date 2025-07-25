//
//  NSNumber+ulib.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/framework.h>


@interface NSNumber(ulib)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix; /*!< convert a NSNumber to a string in a human readable fashion with identation (prefix) being properly handled */

@end
