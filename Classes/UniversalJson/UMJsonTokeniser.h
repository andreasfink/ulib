//
//  UMJSonTokeniser.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

typedef enum
{
    UMjson_token_error = -1,
    UMjson_token_eof,
    
    UMjson_token_array_start,
    UMjson_token_array_end,
    
    UMjson_token_object_start,
    UMjson_token_object_end,

    UMjson_token_separator,
    UMjson_token_keyval_separator,
    
    UMjson_token_number,
    UMjson_token_string,
    UMjson_token_true,
    UMjson_token_false,
    UMjson_token_null,
    
} UMjson_token_t;

@class UMJsonUTF8Stream;

@interface UMJsonTokeniser : UMObject
{
    UMJsonUTF8Stream *_stream;
    NSString *_error;
}

@property (strong) UMJsonUTF8Stream *stream;
@property (copy) NSString *error;

- (void)appendData:(NSData*)data_;

- (UMjson_token_t)getToken:(NSObject**)token;

@end
