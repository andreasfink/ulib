//
//  NSMutableString+UMTestString.m
//  ulib
//
//  Created by Aarno Syvänen on 11.10.12.
//
//

#import "NSMutableString+UMTestString.h"
#import "NSMutableData+UMTestString.h"

@implementation NSMutableString (UMTestString)

- (void)binaryToBase64
{
    NSMutableData *dos;
    NSMutableString *bos;
    
    dos = [[self dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [dos binaryToBase64];
    bos = [[NSMutableString alloc] initWithData:dos encoding:NSUTF8StringEncoding];
    [self setString:bos];
}

- (BOOL)blankAtBeginning:(int)start
{
    unichar c;
    
    if (start >= [self length])
        return FALSE;
    
    c = [self characterAtIndex:start];
    if (isspace(c))
        return TRUE;
    
    return FALSE;
}

- (BOOL)blankAtEnd:(int)end
{
    unichar c;
    
    if (end < 0)
        return FALSE;
    
    c = [self characterAtIndex:end];
    if (isspace(c))
        return TRUE;
    
    return FALSE;
}

- (BOOL)spaceAtBeginning:(int)start
{
    unichar c;
    
    if (start >= [self length])
        return FALSE;
    
    c = [self characterAtIndex:start];
    if (c == ' ')
        return TRUE;
    
    return FALSE;
}

- (BOOL)spaceAtEnd:(int)end
{
    unichar c;
    
    if (end < 0)
        return FALSE;
    
    c = [self characterAtIndex:end];
    if (c == ' ')
        return TRUE;
    
    return FALSE;
}

- (void)stripSpaces
{
    int start = 0, end, len = 0;
    
    /* Remove white space from the beginning of the text */
    while ([self spaceAtBeginning:start])
        start++;
    
    if (start > 0)
        [self deleteCharactersInRange:NSMakeRange(0, start)];
    
    /* and from the end. */
    
    if ((len = (int)[self length]) > 0)
    {
        end = len = len - 1;
        while ([self spaceAtEnd:end])
            end--;
        
        [self deleteCharactersInRange:NSMakeRange(end + 1, len - end)];
    }
}


- (void)stripQuotes
{
    unichar c;
    long len;
    
    c = [self characterAtIndex:0];
    if (c == '"')
        [self deleteCharactersInRange:NSMakeRange(0, 1)];
    
    len = [self length];
    c = [self characterAtIndex:len - 1];
    if (c == '"')
        [self deleteCharactersInRange:NSMakeRange(len - 1, 1)];
    
}

@end
