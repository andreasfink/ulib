//
//  NSMutableArray+ulib.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/NSMutableString+ulib.h>
#import <ulib/UMSocket.h>

@implementation NSMutableArray (HTTPHeader)

/*
 * Given an headers list and a position, returns its header name and value,
 * or (X-Unknown, header) if it doesn't exist or if it's malformed - missing
 * ":" for example
 */
- (void) getHeaderAtIndex:(long)i
                 withName:(NSString **)name
                 andValue:(NSMutableString **)value
{
    NSString *os;
    NSRange colon;
    
    if (i < 0)
        return;
    
    os = [self objectAtIndex:i];
    if (!os)
    {
        colon.location = NSNotFound;
    }
    else
    {
        colon = [os rangeOfString:@":"];
    }
    if (colon.location == NSNotFound)
    {
        *name = @"X-Unknown";
        *value = [os mutableCopy];
    }
    else
    {
        *name = [os substringToIndex:colon.location];
        *value = [[os substringFromIndex:colon.location + 1] mutableCopy];
        [*value stripBlanks];
    }
}


- (void)getContentType:(NSMutableString **)type andCharset:(NSMutableString **)charset
{
    NSMutableString *h;
    NSRange semicolon, equals;
    long len;
    
    h = [[self findFirstWithName:@"Content-Type"] mutableCopy];
    if (!h)
    {
        *type = [[NSMutableString alloc] initWithString:@"application/octet-stream"];
        *charset = [[NSMutableString alloc] init];
    }
    else
    {
        [h stripBlanks];
        semicolon = [h rangeOfString:@";"];
        if (semicolon.location == NSNotFound)
        {
            *type = h;
            *charset = [NSMutableString string];
        }
        else
        {
            *charset = [h mutableCopy];
            [*charset deleteCharactersInRange:NSMakeRange(0, semicolon.location + 1)];
            [*charset stripBlanks];
            equals = [*charset rangeOfString:@"="];
            if (equals.location == NSNotFound)
                [*charset deleteCharactersInRange:NSMakeRange(0, [*charset length])];
            else
            {
                [*charset deleteCharactersInRange:NSMakeRange(0, equals.location + 1)];
                if ([*charset characterAtIndex:0] == '"')
                    [*charset deleteCharactersInRange:NSMakeRange(0, 1)];
                len = [*charset length];
                if ([*charset characterAtIndex:len - 1] == '"')
                    [*charset deleteCharactersInRange:NSMakeRange(len - 1, 1)];
            }
            
            [h deleteCharactersInRange:NSMakeRange(semicolon.location, [h length] - semicolon.location)];
            [h stripBlanks];
            *type = h;
        }
        
        /*
         * According to HTTP/1.1 (RFC 2616, section 3.7.1) we have to ensure
         * to return charset 'iso-8859-1' in case of no given encoding and
         * content-type is a 'text' subtype.
         */
        if ([*charset length] == 0 &&
            [*type compare:@"text" options:NSCaseInsensitiveSearch range:NSMakeRange(0, 4)] == NSOrderedSame)
            [*charset appendString:@"ISO-8859-1"];
    }
}

- (void)addBasicAuthWithUserName:(NSString *)username andPassword:(NSString *)password
{
    NSMutableString *os;
    
    if (password)
        os = [[NSMutableString alloc] initWithFormat:@"%@:%@", username, password];
    else
        os = [[NSMutableString alloc] initWithFormat:@"%@", username];
    
    [os binaryToBase64];
    [os stripBlanks];
    [os insertString:@"Basic " atIndex:0];
    [self addHeaderWithName:@"Authorization" andValue:os];
}

- (void)addHeaderWithName:(NSString *)name andValue:(NSString *)value
{
    NSString *h;
    
    if (!name)
        return;
    
    if (!value)
        return;;
    
    h = [NSString stringWithFormat:@"%@: %@", name, value];
    [self addObject:h];
}

+ (BOOL)nameOf:(NSString *)header is:(NSString *)name
{
    NSRange colon;
    NSComparisonResult ret;
    NSRange start;
    
    colon = [header rangeOfString:@":"];
    if (colon.location == NSNotFound)
        return NO;
    
    if ((long) [name length]!= colon.location)
        return NO;
    
    start = NSMakeRange(0, colon.location);
    ret = [header compare:name options:NSCaseInsensitiveSearch range:start];
    return ret == NSOrderedSame;
}

- (long)removeAllWithName:(NSString *)name
{
    NSString *h;
    long count, i;
    
    if (!name)
        return 0;
    
    i = 0;
    count = 0;
    while (i < [self count]) {
        h = [self objectAtIndex:i];
        if ([NSMutableArray nameOf:h is:name]) {
            [self removeObjectAtIndex:i];
            count++;
        } else
            i++;
    }
    
    return count;
}

- (void)proxyAddAuthenticationWithUserName:(NSString *)username andPassword:(NSString *)password
{
    NSMutableString *os;
    
    if (!username || !password)
        return;
    
    os = [NSMutableString stringWithFormat:@"%@:%@", username, password];
    [os binaryToBase64];
    [os stripBlanks];
    [os replaceCharactersInRange:NSMakeRange(0,0) withString:@"Basic "];
    [self addHeaderWithName:@"Proxy-Authorization" andValue:os];
}

- (NSString *)findFirstWithName:(NSString *)name
{
    long i, name_len;
    NSString *h;
    NSMutableString *value;
    
    if(!name)
        return nil;
    
    name_len = [name length];
    
    for (i = 0; i < [self count]; ++i)
    {
        h = [self objectAtIndex:i];
        if ([NSMutableArray nameOf:h is:name])
        {
            value = [[h substringWithRange:NSMakeRange(name_len + 1, [h length] - name_len - 1)] mutableCopy];
            [value stripBlanks];
            return value;
        }
    }
    return nil;
}

/*
 * Read some headers, i.e., until the first empty line (read and discard
 * the empty line as well). Return -1 for error, 0 for all headers read,
 * 1 for more headers to follow.
 */
- (int)readSomeHeadersFrom:(UMSocket *)sock
{
    NSMutableString *line, *prev;
    long len;
    NSMutableData *dline;
    UMSocketError sErr;
    char first;
    
    if ((len = [self count]) == 0)
        prev = NULL;
    else
    {
        prev = [self objectAtIndex:len - 1];
    }
    
    for (;;) {
        sErr = [sock receiveLineTo:&dline];
        if (!dline)
        {
            if (sErr != UMSocketError_try_again)
                return -1;
            return 1;
        }
        
        if ([dline length] == 0) {
            break;
        }
        
        line = [[NSMutableString alloc] initWithData:dline encoding:NSASCIIStringEncoding];
        first = [line characterAtIndex:0];
        if (isspace(first) && prev) {
            [prev appendString:line];
        } else {
            [self addObject:line];
            prev = line;
        }
    }
    
    return 0;
}

@end
