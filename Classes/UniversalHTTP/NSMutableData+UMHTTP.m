//
//  NSMutableData+UMHTTP.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "NSMutableData+UMHTTP.h"

@implementation NSMutableData (UMHTTP)

- (void)binaryToBase64
{
    static const unsigned char base64[64] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    long triplets;
    long lines;
    long orig_len, len;
    unsigned char *data;
    long from, to;
    int left_on_line;
    NSMutableData *copy = NULL;
    
    if ([self length] == 0)
    {
        /* Always terminate with CR LF */
        char *crlf = "\015\012";
        NSData *dcrlf = [NSData dataWithBytes:crlf length:2];
        [self appendData:dcrlf];
        return;
    }
    
    copy = [[NSMutableData alloc] initWithData:self];
    
    /* The lines must be 76 characters each (or less), and each
     * triplet will expand to 4 characters, so we can fit 19
     * triplets on one line.  We need a CR LF after each line,
     * which will add 2 octets per 19 triplets (rounded up). */
    triplets = ([self length] + 2) / 3;   /* round up */
    lines = (triplets + 18) / 19;
    len = triplets * 4 + lines * 2;
    
    //octstr_grow(ostr, triplets * 4 + lines * 2);
    orig_len = [self length] + triplets * 4 + lines * 2;
    
    data = (unsigned char *)[copy bytes];
    data[len] = '\0';
    
    /* This function works back-to-front, so that encoded data will
     * not overwrite source data.
     * from points to the start of the last triplet (which may be
     * an odd-sized one), and to points to the start of where the
     * last quad should go.  */
    from = (triplets - 1) * 3;
    to = (triplets - 1) * 4 + (lines - 1) * 2;
    
    /* First write the CR LF after the last quad */
    data[to + 5] = 10;   /* LF */
    data[to + 4] = 13;   /* CR */
    left_on_line = (int)(triplets - ((lines - 1) * 19));
    
    /* base64 encoding is in 3-octet units.  To handle leftover
     * octets, conceptually we have to zero-pad up to the next
     * 6-bit unit, and pad with '=' characters for missing 6-bit
     * units.
     * We do it by first completing the first triplet with
     * zero-octets, and after the loop replacing some of the
     * result characters with '=' characters.
     * There is enough room for this, because even with a 1 or 2
     * octet source string, space for four octets of output
     * will be reserved.
     */
    switch (orig_len % 3) {
        case 0:
            break;
        case 1:
            data[orig_len] = 0;
            data[orig_len + 1] = 0;
            break;
        case 2:
            data[orig_len + 1] = 0;
            break;
    }
    
    /* Now we only have perfect triplets. */
    while (from >= 0) {
        long whole_triplet;
        
        /* Add a newline, if necessary */
        if (left_on_line == 0) {
            to -= 2;
            data[to + 5] = 10;  /* LF */
            data[to + 4] = 13;  /* CR */
            left_on_line = 19;
        }
        
        whole_triplet = (data[from] << 16) |
        (data[from + 1] << 8) |
        data[from + 2];
        data[to + 3] = base64[whole_triplet % 64];
        data[to + 2] = base64[(whole_triplet >> 6) % 64];
        data[to + 1] = base64[(whole_triplet >> 12) % 64];
        data[to] = base64[(whole_triplet >> 18) % 64];
        
        to -= 4;
        from -= 3;
        left_on_line--;
    }
    
    /* Insert padding characters in the last quad.  Remember that
     * there is a CR LF between the last quad and the end of the
     * string. */
    switch (orig_len % 3) {
        case 0:
            break;
        case 1:
            data[len - 3] = '=';
            data[len - 4] = '=';
            break;
        case 2:
            data[len - 3] = '=';
            break;
    }
    
    NSData *ddata = [[NSData alloc] initWithBytesNoCopy:data length:len];
    [self setData:ddata];
    return;
}

- (BOOL)blankAtBeginning:(int)start
{
    unsigned char buf[1];
    
    if (start <= [self length])
        return NO;
    
    [self getBytes:buf range:NSMakeRange(start, 1)];
    
    if (isspace(buf[0]))
        return YES;
    
    return NO;
}

- (BOOL)blankAtEnd:(int)end
{
    unsigned char buf[1];
    
    if (end < 0)
        return NO;
    
    [self getBytes:buf range:NSMakeRange(end, 1)];
    
    if (isspace(buf[0]))
        return YES;
    
    return NO;
}

- (void)stripBlanks
{
    int start = 0, end, len = 0;
    NSRange blanks;
    
    /* Remove white space from the beginning of the text */
    while ([self blankAtBeginning:start])
        start ++;
    
    if (start > 0)
        [self replaceBytesInRange:NSMakeRange(0, start) withBytes:nil length:0];
    
    /* and from the end. */
    
    if ((len = (int)[self length]) > 0) {
        end = len = len - 1;
        while ([self blankAtEnd:end])
            end--;
        
        blanks = NSMakeRange(end, len - end);
        [self replaceBytesInRange:blanks withBytes:nil length:0];
    }
}

@end
