//
//  NSData+HierarchicalDescription.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData(HiearchicalDescription)

- (NSString *)hierarchicalDescriptionWithPrefix:(NSString *)prefix;
- (NSString *)stringForDumping;
- (NSString *)dump;

@end
