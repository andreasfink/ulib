//
//  UMJSonWriter.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@interface UMJsonWriter : UMObject
{
    NSUInteger maxDepth;
    NSString *error;
    BOOL humanReadable;
    BOOL sortKeys;
    SEL sortKeysSelector;
}

@property NSUInteger maxDepth;
@property (readwrite, strong) NSString *error;
@property BOOL humanReadable;
@property BOOL sortKeys;
@property (readwrite,assign) SEL sortKeysSelector;

- (NSString*)stringWithObject:(id)value;
- (NSData*)dataWithObject:(id)value;

@end
