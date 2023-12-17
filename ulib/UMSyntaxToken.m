//
//  UMSyntaxToken.m
//  ulib
//
//  Created by Andreas Fink on 24.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/UMSyntaxToken.h>
#import <ulib/UMTokenizerWord.h>
#import <ulib/UMSyntaxContext.h>
#import <ulib/UMSyntaxAction.h>
#import <ulib/UMSynchronizedSortedDictionary.h>

@implementation UMSyntaxToken

- (UMSyntaxToken *)init
{
    return [self initWithString:@""];
}

-(UMSyntaxToken *) initWithString:(NSString *)s
{
    return [self initWithString:s help:@"" caseSensitive:NO];
}

-(UMSyntaxToken *) initWithHelp:(NSString *)h
{
    return [self initWithString:NULL help:h caseSensitive:NO];
}

-(UMSyntaxToken *) initWithString:(NSString *)s  help:(NSString *)h
{
    return [self initWithString:s help:h caseSensitive:NO];
}

-(UMSyntaxToken *) initWithString:(NSString *)s  help:(NSString *)h caseSensitive:(BOOL)cs
{
    self = [super init];
    if(self)
    {
        _string = s;
        _help = h;
        _subtokens = [[UMSynchronizedSortedDictionary alloc]init];
        _caseSensitive = cs;
    }
    return self;
}

- (void)addSubtoken:(UMSyntaxToken *)sub
{
    [_subtokens addObject:sub forKey:sub.key];
}

- (NSString *)key
{
    if(_caseSensitive)
    {
        return _string;
    }
    return [_string lowercaseString];
}

- (BOOL) matchesValue:(NSString *)value withPriority:(int)priority
{
    return NO;
}

- (BOOL) startsWithValue:(NSString *)value withPriority:(int)prio fullValue:(NSString **)fullValue
{
    return NO;
}


- (void) executeLines:(NSArray *)lines
         usingContext:(UMSyntaxContext *)context
{
    for(NSArray *line in lines)
    {
        [self executeWords:line usingContext:context currentWord:@""];
    }
}

- (void) executeWords:(NSArray *)words
         usingContext:(UMSyntaxContext *)context
          currentWord:(NSString *)currentWord
{
    NSMutableArray *remainingWords;
    UMTokenizerWord *tword =NULL;

    if(words.count > 0)
    {
        tword = words[0];
        UMSyntaxToken *choosenToken = NULL;
        NSArray *keys = [_subtokens allKeys];
        for(int i=UMSYNTAX_PRIORITY_MAX; i>=0 ;i--)
        {
            for(NSString *key in keys)
            {
                UMSyntaxToken *subtoken  = _subtokens[key];
                if([subtoken matchesValue:tword.value withPriority:i])
                {
                    choosenToken = subtoken;
                }
            }
        }
        if(choosenToken == NULL)
        {
            @throw([NSException exceptionWithName:@"SYNTAX" reason:@"unknown command" userInfo:
                   @{
                     @"line" : @(tword.line),
                     @"colum" :@(tword.colum),
                     @"file" : tword.sourceFile,
                     }]);
        }
        remainingWords = [words mutableCopy];
        [remainingWords removeObjectAtIndex:0];

        [self preAction:currentWord context:context];
        [choosenToken executeWords:remainingWords usingContext:context currentWord:tword.value];
        [self postAction:currentWord context:context];
        return;
    }
    [self preAction:currentWord context:context];
    [self action:currentWord context:context];
    [self postAction:currentWord context:context];
}


- (NSString *) autocompleteWords:(NSArray *)words
                    usingContext:(UMSyntaxContext *)context
                     currentWord:(NSString *)currentWord
{
    NSMutableArray *remainingWords;
    UMTokenizerWord *tword =NULL;

    if(words.count > 0)
    {
        NSString *fullWord = @"";
        tword = words[0];
        UMSyntaxToken *choosenToken = NULL;
        NSArray *keys = [_subtokens allKeys];
        for(int i=UMSYNTAX_PRIORITY_MAX; i>=0 ;i--)
        {
            for(NSString *key in keys)
            {
                UMSyntaxToken *subtoken  = _subtokens[key];
                if([subtoken startsWithValue:tword.value withPriority:i fullValue:&fullWord])
                {
                    choosenToken = subtoken;
                }
            }
        }
        if(choosenToken == NULL)
        {
            return @"";
        }
        remainingWords = [words mutableCopy];
        [remainingWords removeObjectAtIndex:0];
        if(remainingWords.count > 0)
        {
            NSString *s = [NSString stringWithFormat: @"%@ %@",fullWord, [choosenToken autocompleteWords:remainingWords usingContext:context currentWord:tword.value]];
            return s;
        }
        else
        {
            NSString *s = [NSString stringWithFormat: @"%@ ",fullWord];
            return s;
        }
    }
    return currentWord;
}


- (NSArray *) lastTokens:(NSArray *)words
{
    if(words.count == 0)
    {
        return @[self];
    }

    NSMutableArray *remainingWords = [words mutableCopy];
    [remainingWords removeObjectAtIndex:0];
    UMTokenizerWord *tword = words[0];
    NSArray *keys = [_subtokens allKeys];
    NSString *fullWord = NULL;
    UMSyntaxToken *choosenToken = NULL;
    NSMutableArray *foundMatchingTokens = [[NSMutableArray alloc]init];
    for(int i=UMSYNTAX_PRIORITY_MAX; i>=0 ;i--)
    {
        for(NSString *key in keys)
        {
            UMSyntaxToken *subtoken  = _subtokens[key];
            if([subtoken startsWithValue:tword.value withPriority:i fullValue:&fullWord])
            {
                choosenToken = subtoken;
                [foundMatchingTokens addObject:subtoken];
            }
        }
    }
    if(remainingWords.count > 0)
    {
        if(choosenToken)
        {
            return [choosenToken lastTokens:remainingWords];
        }
        return @[self];
    }
    return foundMatchingTokens;
}


- (NSArray  *) helpStrings
{
    return @[ _string,_help];
}

- (NSString *) helpWords:(NSArray *)words
            usingContext:(UMSyntaxContext *)context
             currentWord:(NSString *)currentWord
{
    UMTokenizerWord *tword = NULL;

    NSInteger i;
    NSInteger n = words.count;

    UMSyntaxToken *choosenToken = NULL;
    NSString *fullWord = NULL;

    NSMutableArray *helpTokens = NULL;
    for(i=0;i<n;i++)
    {
        tword = words[i];
        NSArray *keys = [_subtokens allKeys];
        helpTokens = [[NSMutableArray alloc]init];

        for(int i=UMSYNTAX_PRIORITY_MAX; i>=0 ;i--)
        {
            for(NSString *key in keys)
            {
                UMSyntaxToken *subtoken  = _subtokens[key];
                if([subtoken startsWithValue:tword.value withPriority:i fullValue:&fullWord])
                {
                    choosenToken = subtoken;
                    [helpTokens addObject:subtoken];
                }
            }
        }
        if(choosenToken == NULL)
        {
            break;
        }
    }
    if(choosenToken == NULL)
    {
        [helpTokens addObject:self];
    }
    /* lets find the longest word */
    NSInteger maxlen = 0;
    for(UMSyntaxToken *token in helpTokens)
    {
        NSInteger len = token.string.length;
        if(len > maxlen)
        {
            maxlen = len;
        }
    }
    NSString *formatString = [NSString stringWithFormat:@"%%0%d%%@ %%@\r\n",(int)maxlen];
    NSMutableString *helpString =[[NSMutableString alloc]init];

    for(UMSyntaxToken *token in helpTokens)
    {
        [helpString appendFormat:formatString,token.string,token.help];
    }
    return helpString;
}

- (void)preAction:(NSString *)word context:(UMSyntaxContext *)context
{
    [_delegate commandPreAction:_commandAction value:word context:context];
}

- (void)postAction:(NSString *)word context:(UMSyntaxContext *)context
{
    [_delegate commandPostAction:_commandAction value:word context:context];
}

- (void)action:(NSString *)word context:(UMSyntaxContext *)context
{
    [_delegate commandAction:_commandAction value:word context:context];
}
@end
