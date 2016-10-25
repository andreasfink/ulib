//
//  NSString+HierarchicalDescription.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (HierarchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix;
- (NSString *)increasePrefix;
- (NSString *)removeFirstAndLastChar;

@end
