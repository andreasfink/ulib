
//
//  UMJSonStreamParserState.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>

#import "UMJsonTokeniser.h"
#import "UMJsonStreamParser.h"

@interface UMJsonStreamParserState : UMObject
+ (id)sharedInstance;

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token;
- (UMJsonStreamParserStatus)parserShouldReturn:(UMJsonStreamParser*)parser;
- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok;
- (BOOL)needKey;
- (BOOL)isError;

- (NSString*)name;

@end

@interface UMJsonStreamParserStateStart : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateComplete : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateError : UMJsonStreamParserState
@end


@interface UMJsonStreamParserStateObjectStart : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateObjectGotKey : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateObjectSeparator : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateObjectGotValue : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateObjectNeedKey : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateArrayStart : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateArrayGotValue : UMJsonStreamParserState
@end

@interface UMJsonStreamParserStateArrayNeedValue : UMJsonStreamParserState
@end
