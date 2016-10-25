//
//  UMConfigParsedLine.m
//  ulib
//
//  Created by Andreas Fink on 17.12.11.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMConfigParsedLine.h"

@implementation UMConfigParsedLine

@synthesize filename;
@synthesize lineNumber;
@synthesize content;
@synthesize includedLines;



- (void) flattenConfigTo:(NSMutableArray *)writerArray;
{
    if(includedLines == NULL)
    {
        [writerArray addObject:self];
    }
    else 
    {
        UMConfigParsedLine *includeStatement = [[UMConfigParsedLine alloc]init];
        includeStatement.filename = filename;
        includeStatement.lineNumber = lineNumber;
        includeStatement.content = content;
        [writerArray addObject:includeStatement];
        for(UMConfigParsedLine *sub in includedLines)
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
    return [NSString stringWithFormat:@"[%@:%ld] %@",filename,lineNumber,content];
}
@end
