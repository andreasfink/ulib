//
//  UMScanner.m
//  ulib
//
//  Created by Andreas Fink on 26.02.17.
//  Copyright © 2017 Andreas Fink. All rights reserved.
//

#import "UMScanner.h"
#import "UMScannerChar.h"

@implementation UMScanner


- (NSArray *)scanFile:(NSString *)filename
{
    NSError *e = NULL;
    NSString *s = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&e];
    if(e)
    {
        NSLog(@"Error %@",e);
        return NULL;
    }
    else
    {
        return [self scanString:s forFilename:filename];
    }
}

- (NSArray *)scanString:(NSString *)s
{
    return [self scanString:s forFilename:@""];
}

- (NSArray *)scanString:(NSString *)s forFilename:(NSString *)filename
{
    NSInteger currentLine = 1;
    NSInteger currentColum = 1;
    NSMutableArray *chars = [[NSMutableArray alloc]init];
    NSInteger max = s.length;
    for(NSInteger i=0;i<max;i++)
    {
        UMScannerChar *sc = [[UMScannerChar alloc]init];
        sc.character = [s characterAtIndex:i];

        sc.line = currentLine;
        sc.colum = currentColum;
        sc.sourceFile  = filename;
        if(sc.character == '\r')
        {
            currentColum = 1;
            //currentLine++;
        }
        else if(sc.character == '\n')
        {
            currentColum = 1;
            currentLine++;
        }
        else
        {
            currentColum++;
        }
        [chars addObject:sc];
    }
    return chars;
}
@end
