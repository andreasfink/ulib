//
//  UMConfigParsedLine.h
//  ulib
//
//  Created by Andreas Fink on 17.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

/*!
 @class UMConfigParsedLine
 @brief  UMConfigParsedLine is a line in a config file. usedby UMConfig internally
 
*/

@interface UMConfigParsedLine : UMObject
{
    NSString    *filename;
    long        lineNumber;
    NSString    *content;
    NSArray     *includedLines;
}

@property(readwrite,strong) NSString *filename;
@property(readwrite,strong) NSString *content;
@property(readwrite,assign) long lineNumber;
@property(readwrite,strong) NSArray *includedLines;

- (void) flattenConfigTo:(NSMutableArray *)writerArray;
+ (NSArray *)flattenConfig:(NSArray *)input;

@end
