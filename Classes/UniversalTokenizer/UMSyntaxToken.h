//
//  UMSyntaxToken.h
//  ulib
//
//  Created by Andreas Fink on 24.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMObject.h"
#import "UMCommandActionProtocol.h"

@class UMSynchronizedSortedDictionary;
@class UMSyntaxAction;

#define UMSYNTAX_PRIORITY_NAME      2
#define UMSYNTAX_PRIORITY_NUMBER    1
#define UMSYNTAX_PRIORITY_CONSTANT  0
#define UMSYNTAX_PRIORITY_MAX       2

typedef enum UMSyntaxTokenType
{
    UMSyntaxToken_String,
    UMSyntaxToken_Integer,
    UMSyntaxToken_Real,
} UMSyntaxTokenType;

@interface UMSyntaxToken : UMObject
{
    NSString    *_string;
    BOOL        _caseSensitive;
    NSString    *_help;
    UMSynchronizedSortedDictionary *_subtokens;
    id<UMCommandActionProtocol> _delegate;
    NSString *_commandAction;
    UMSyntaxAction *_action;
}

@property(readwrite,strong,atomic)  UMSyntaxAction *action;
@property(readwrite,strong,atomic)  NSString    *string;
@property(readwrite,strong,atomic)  NSString    *help;
@property(readwrite,assign,atomic)  BOOL        caseSensitive;
@property(readwrite,strong,atomic)  UMSynchronizedSortedDictionary *subtokens;

@property(readwrite,strong,atomic)  id<UMCommandActionProtocol> delegate;
@property(readwrite,strong,atomic)  NSString *commandAction;


- (UMSyntaxToken *) initWithString:(NSString *)s  help:(NSString *)h caseSensitive:(BOOL)cs;
- (UMSyntaxToken *) initWithString:(NSString *)s  help:(NSString *)h;
- (UMSyntaxToken *) initWithString:(NSString *)s;
- (UMSyntaxToken *) initWithHelp:(NSString *)h;
- (NSString *)key;
- (void)addSubtoken:(UMSyntaxToken *)sub;
- (BOOL) matchesValue:(NSString *)value withPriority:(int)priority;
- (BOOL) startsWithValue:(NSString *)value withPriority:(int)prio fullValue:(NSString **)fullValue;

- (void) executeLines:(NSArray *)words
         usingContext:(UMSyntaxContext *)context;
- (void) executeWords:(NSArray *)words
         usingContext:(UMSyntaxContext *)context
          currentWord:(NSString *)word;

- (NSString *) helpWords:(NSArray *)words
            usingContext:(UMSyntaxContext *)context
             currentWord:(NSString *)currentWord;

- (NSString *) autocompleteWords:(NSArray *)words
                    usingContext:(UMSyntaxContext *)context
                     currentWord:(NSString *)currentWord;

- (NSArray *) lastTokens:(NSArray *)words;

@end
