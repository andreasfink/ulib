//
//  UMJsonParser.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@interface UMJsonParser : UMObject
{
    NSUInteger maxDepth;
    NSString *error;
}
@property (readwrite,assign)NSUInteger maxDepth;
@property(readwrite,strong) NSString *error;

- (id)objectWithData:(NSData*)data;
- (id)objectWithString:(NSString *)repr;
- (id)objectWithString:(NSString*)jsonText
                 error:(NSError**)error __attribute__ ((deprecated));

@end


