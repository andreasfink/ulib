//
//  UMTokenizer.h
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import <ulib/UMObject.h>
@class UMTokenizerWord;

@interface UMTokenizer : UMObject
{
    NSCharacterSet *_whitespace;
    NSCharacterSet *_comment;
    NSCharacterSet *_endOfLine;
    NSCharacterSet *_digits;
    BOOL _inCommentLine;
    BOOL _inDoubleQuote;
    NSMutableString *_currentTokenString;
    UMTokenizerWord *_currentWord;
    NSMutableArray *_words;
    NSMutableArray *_lines;
    BOOL    _positionSet;
    UMMutex *_tokenizerLock;
}

- (NSArray *)tokensFromChars:(NSArray *)chars;

@end
