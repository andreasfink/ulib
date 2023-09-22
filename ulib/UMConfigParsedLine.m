//
//  UMConfigParsedLine.m
//  ulib
//
//  Created by Andreas Fink on 17.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMConfigParsedLine.h>

@implementation UMConfigParsedLine

- (void) flattenConfigTo:(NSMutableArray *)writerArray;
{
    if(_includedLines == NULL)
    {
        [writerArray addObject:self];
    }
    else 
    {
        UMConfigParsedLine *includeStatement = [[UMConfigParsedLine alloc]init];
        includeStatement.filename = _filename;
        includeStatement.lineNumber = _lineNumber;
        includeStatement.content = _content;
        [writerArray addObject:includeStatement];
        for(UMConfigParsedLine *sub in _includedLines)
        {
            [sub flattenConfigTo:writerArray];
        }
    }
}

+ (NSArray *)flattenConfig:(NSArray *)input;
{
    NSMutableArray *out = [[NSMutableArray alloc]init];
    for(UMConfigParsedLine *item in input)
    {
        [item flattenConfigTo:out]; 
    }
    return out;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@:%ld] %@",_filename,_lineNumber,_content];
}
@end
