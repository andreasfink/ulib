//
//  UMTokenizer.m
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMTokenizer.h>
#import <ulib/UMScannerChar.h>
#import <ulib/UMTokenizerWord.h>

@implementation UMTokenizer

- (UMTokenizer *)init
{
    self = [super init];
    if(self)
    {
        _whitespace  = [UMObject whitespaceAndNewlineCharacterSet];
        _comment     = [NSCharacterSet characterSetWithCharactersInString:@"!#"];
        _endOfLine   = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
        _digits      = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        _tokenizerLock = [[UMMutex alloc]initWithName:@"tokenizer-lock"];
        [self reset];
    }
    return self;
}


- (void) reset
{
    _inCommentLine = NO;
    _currentTokenString = [[NSMutableString alloc]init];
    _currentWord = [[UMTokenizerWord alloc]init];
    _words = [[NSMutableArray alloc]init];
    _lines = [[NSMutableArray alloc]init];
    _positionSet = NO;
}

- (void)pushLine
{
    NSInteger count = _words.count;
    if(count == 0)
    {
        _inCommentLine = NO;
        return;
    }
    UMTokenizerWord *lastWord = [_words objectAtIndex:count-1];
    lastWord.terminal = YES;
    [_lines addObject:_words];
    _words = [[NSMutableArray alloc]init];
    _inCommentLine = NO;
    _positionSet = NO;
}

- (void)pushWord
{
    if([_currentTokenString isEqualToString:@""])
    {
        return;
    }
    _currentWord.value = _currentTokenString;
    [_words addObject:_currentWord];
    _currentTokenString = [[NSMutableString alloc] init];
    _currentWord = [[UMTokenizerWord alloc]init];
    _positionSet = NO;
}

- (void)pushChar:(UMScannerChar *)sc
{
    if(_positionSet == NO)
    {
        [self pushPosition:sc];
    }
    unichar chr = sc.character;
    if([_currentTokenString isEqualToString:@""])
    {
        if([_whitespace characterIsMember:chr])
        {
            return; /* no leading whitespace */
        }
    }
    NSString *c = [NSString stringWithCharacters:&chr length:1];
    [_currentTokenString appendString:c];
}

- (void)pushPosition:(UMScannerChar *)sc
{
    _currentWord.sourceFile = sc.sourceFile;
    _currentWord.line = sc.line;
    _currentWord.colum = sc.colum;
    _positionSet = YES;
}

- (NSArray *)tokensFromChars:(NSArray *)chars
{
    UMMUTEX_LOCK(_tokenizerLock);
    [self reset];
    NSInteger len = chars.count;
    
    for(NSInteger i=0;i<len;i++)
    {
        UMScannerChar *sc = chars[i];
        unichar chr = sc.character;
        
        if([_endOfLine characterIsMember:chr])
        {
            [self pushWord];
            [self pushLine];
            continue;
        }
        
        if(_inCommentLine)
        {
            [self pushChar:sc];
            continue;
        }
        
        if([_comment characterIsMember:chr])
        {
            [self pushWord];
            [self pushChar:sc];
            _inCommentLine=YES;
            continue;
        }
        
        if([_whitespace characterIsMember:chr])
        {
            [self pushWord];
            continue;
        }
        [self pushChar:sc];
    }
    [self pushWord];
    [self pushLine];
    NSArray *result = _lines;
    _lines = [[NSMutableArray alloc]init];
   UMMUTEX_UNLOCK(_tokenizerLock);
    return result;
}

@end
