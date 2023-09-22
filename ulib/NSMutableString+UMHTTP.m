//
//  NSMutableString+UMHTTP.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSMutableString+UMHTTP.h>
#import <ulib/NSMutableData+UMHTTP.h>


@implementation NSMutableString (UMHTTP)

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
    {
        return NO;
    }
    c = [self characterAtIndex:start];
    if (isspace(c))
    {
        return YES;
    }
    return NO;
}

- (BOOL)blankAtEnd:(int)end
{
    unichar c;
    
    if (end < 0)
    {
        return NO;
    }
    c = [self characterAtIndex:end];
    if (isspace(c))
    {
        return YES;
    }
    return NO;
}

- (BOOL)spaceAtBeginning:(int)start
{
    unichar c;
    
    if (start >= [self length])
    {
        return NO;
    }
    c = [self characterAtIndex:start];
    if (c == ' ')
    {
        return YES;
    }
    return NO;
}

- (BOOL)spaceAtEnd:(int)end
{
    unichar c;
    
    if (end < 0)
    {
        return NO;
    }
    c = [self characterAtIndex:end];
    if (c == ' ')
    {
        return YES;
    }
    return NO;
}

- (void)stripSpaces
{
    int start = 0, end, len = 0;
    
    /* Remove white space from the beginning of the text */
    while ([self spaceAtBeginning:start])
    {
        start++;
    }
    if (start > 0)
    {
        [self deleteCharactersInRange:NSMakeRange(0, start)];
    }
    /* and from the end. */
    
    if ((len = (int)[self length]) > 0)
    {
        end = len = len - 1;
        while ([self spaceAtEnd:end])
        {
            end--;
        }
        [self deleteCharactersInRange:NSMakeRange(end + 1, len - end)];
    }
}

- (void)stripBlanks
{
    int start = 0, end, len = 0;
    
    /* Remove white space from the beginning of the text */
    while ([self blankAtBeginning:start])
    {
        start++;
    }
    if (start > 0)
    {
        [self deleteCharactersInRange:NSMakeRange(0, start)];
    }
    /* and from the end. */
    
    if ((len = (int)[self length]) > 0)
    {
        end = len = len - 1;
        while ([self blankAtEnd:end])
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
    {
        [self deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    len = [self length];
    c = [self characterAtIndex:len - 1];
    if (c == '"')
    {
        [self deleteCharactersInRange:NSMakeRange(len - 1, 1)];
    }
}


@end
