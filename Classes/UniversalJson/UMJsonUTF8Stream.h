//
//  UMJSonUTF8Stream.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@interface UMJsonUTF8Stream : UMObject
{
@private
    const char *_bytes;
    NSMutableData *_data;
    NSUInteger _length;
    NSUInteger _index;
}

@property (assign) NSUInteger index;

- (void)appendData:(NSData*)data_;

- (BOOL)haveRemainingCharacters:(NSUInteger)chars;

- (void)skip;
- (void)skipWhitespace;
- (BOOL)skipCharacters:(const char *)chars length:(NSUInteger)len;

- (BOOL)getUnichar:(unichar*)ch;
- (BOOL)getNextUnichar:(unichar*)ch;
- (BOOL)getStringFragment:(NSString**)string;

- (NSString*)stringWithRange:(NSRange)range;

@end
