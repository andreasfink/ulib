//
//  UMTokenizerWord.h
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMObject.h"

@interface UMTokenizerWord : UMObject
{
    NSString *_value;
    NSString *_sourceFile;
    NSInteger _line;
    NSInteger _colum;
    BOOL    _terminal;
    BOOL    _comment;
    BOOL    _digits;
}

@property(readwrite,strong,atomic)  NSString *value;
@property(readwrite,strong,atomic)  NSString *sourceFile;
@property(readwrite,assign,atomic)  NSInteger line;
@property(readwrite,assign,atomic)  NSInteger colum;
@property(readwrite,assign,atomic)  BOOL    terminal;
@property(readwrite,assign,atomic)  BOOL    comment;
@property(readwrite,assign,atomic)  BOOL    digits;


@end
