//
//  UMJsonStreamParser.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

@class UMJsonTokeniser;
@class UMJsonStreamParser;
@class UMJsonStreamParserState;

typedef enum
{
	UMJsonStreamParserComplete,
	UMJsonStreamParserWaitingForData,
	UMJsonStreamParserError,
} UMJsonStreamParserStatus;

@protocol UMJsonStreamParserDelegate
- (void)parserFoundObjectStart:(UMJsonStreamParser*)parser;
- (void)parser:(UMJsonStreamParser*)parser foundObjectKey:(NSString*)key;
- (void)parserFoundObjectEnd:(UMJsonStreamParser*)parser;
- (void)parserFoundArrayStart:(UMJsonStreamParser*)parser;
- (void)parserFoundArrayEnd:(UMJsonStreamParser*)parser;
- (void)parser:(UMJsonStreamParser*)parser foundBoolean:(BOOL)x;
- (void)parserFoundNull:(UMJsonStreamParser*)parser;
- (void)parser:(UMJsonStreamParser*)parser foundNumber:(NSNumber*)num;
- (void)parser:(UMJsonStreamParser*)parser foundString:(NSString*)string;
@end

@interface UMJsonStreamParser : UMObject
{
@private
	UMJsonTokeniser *tokeniser;
    UMJsonStreamParserState *state;
    
    NSMutableArray *stateStack;
    BOOL supportMultipleDocuments;
    id<UMJsonStreamParserDelegate> __unsafe_unretained delegate;
    NSUInteger maxDepth;
    NSString *error;
}

@property (nonatomic,strong) UMJsonStreamParserState *state;
@property (nonatomic, readonly,strong) NSMutableArray *stateStack;
@property BOOL supportMultipleDocuments;
@property (unsafe_unretained) id<UMJsonStreamParserDelegate> delegate;
@property NSUInteger maxDepth;
@property (copy) NSString *error;

- (UMJsonStreamParserStatus)parse:(NSData*)data;

@end
