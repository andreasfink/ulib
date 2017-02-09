//
//  UMTestHTTPEntity.m
//  ulib
//
//  Created by Aarno Syvanen on 27.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMTestHTTPEntity.h"
#import "UMTestHTTP.h"
#import "NSMutableString+UMTestString.h"
#import "NSMutableArray+UMHTTP.h"

@implementation UMTestHTTPEntity

@synthesize headers;
@synthesize body;
@synthesize expect_state;
@synthesize state;
@synthesize chunked_body_chunk_len;
@synthesize expected_body_len;

- (UMTestHTTPEntity *)initWithBodyExpectation:(enum body_expectation)exp
{
    if((self=[super init]))
    {
        self.headers = [[NSMutableArray alloc] init];
        self.body = [[NSMutableData alloc] init];
        self.chunked_body_chunk_len = -1;
        self.expected_body_len = -1;
        self.state = reading_headers;
        self.expect_state = exp;
    }
    return self;
}

- (UMTestHTTPEntity *)initWithEntity:(UMTestHTTPEntity *)ent
{
    if((self=[super init]))
    {
        self.headers = [ent headers];
        self.body = [ent body];
        self.chunked_body_chunk_len = [ent chunked_body_chunk_len];
        self.expected_body_len = [ent expected_body_len];
        self.state = [ent state];
        self.expect_state = [ent expect_state];
    }
    return self;
}


- (NSString *)description
{
    NSMutableString *desc;
    
    desc = [[NSMutableString alloc] initWithString:@"HTTP Entity dump starts\r\n"];
    [desc appendFormat:@"Entity headers were %@\r\n", headers];
    [desc appendFormat:@"Entity body was %@\r\n", body];
    [desc appendFormat:@"Chunked body len was %ld\r\n", chunked_body_chunk_len];
    [desc appendFormat:@"Expected body len was %ld\r\n", expected_body_len];
    [desc appendFormat:@"Entity state was %u\r\n", state];
    [desc appendFormat:@"Expected state was %u\r\n", expect_state];
    [desc appendString:@"HTTP Entity dump ends\r\n"];
    
    return desc;
}

/*  
 * The rules for message bodies (length and presence) are defined
 * in RFC2616 paragraph 4.3 and 4.4.
 */
- (void)deduceBodyState
{
    NSMutableString *h = nil;
    
    if (expect_state == expect_no_body) {
        self.state = entity_done;
        return;
    }
    
    self.state = body_error;  /* safety net */
    
    h = [[headers findFirstWithName:@"Transfer-Encoding"] mutableCopy];
    if (h) {
        [h stripBlanks];
        if ([h compare:@"chunked"] != NSOrderedSame) {
            self.state = body_error;
        } else {
            self.state = reading_chunked_body_len;
        }
        return;
    }
    
    h = [[headers findFirstWithName:@"Content-Length"] mutableCopy];
    if (h) {
        self.expected_body_len = [h integerValue];
        if (expected_body_len == -1 || expected_body_len < 0) {
            self.state = body_error;
        } else if (expected_body_len == 0) {
            self.state = entity_done;
        } else {
            self.state = reading_body_with_length;
        }
        return;
    }
    
    if (expect_state == expect_body)
        self.state = reading_body_until_eof;
    else
        self.state = entity_done;
}

- (void)readChunkedBodyLenFrom:(UMSocket *)sock
{
    NSMutableData *os;
    NSString *sos;
    long len;
    UMSocketError sErr;
    
    sErr = [sock receiveLineTo:&os]; 
    if (!os) 
    {
        if (sErr != UMSocketError_try_again)
            self.state = body_error;
        return;
    }
    
    sos = [[NSString alloc] initWithData:os encoding:NSASCIIStringEncoding];
    len = [sos integerValue];
    if (len == -1) 
    {
        self.state = body_error;
        return;
    }
    
    if (len == 0)
        self.state = reading_chunked_body_trailer;
    else 
    {
        self.state = reading_chunked_body_data;
        self.chunked_body_chunk_len = len;
    }

}

- (void)readChunkedBodyDataFrom:(UMSocket *)sock
{
    NSMutableData *os = [NSMutableData data];
    UMSocketError sErr;
    
    sErr = [sock receive:chunked_body_chunk_len appendTo:os];
    if (!os) {
        if (sErr != UMSocketError_try_again)
            self.state = body_error;
    } else {
        [body appendData:os];
        self.state = reading_chunked_body_crlf;
    }
}

- (void)readChunkedBodyCRLFFrom:(UMSocket *)sock
{
    NSMutableData *os;
    UMSocketError sErr;
    
    sErr = [sock receiveLineTo:&os];
    if (!os) {
        if (sErr != UMSocketError_try_again)
            self.state = body_error;
    } else {
        self.state = reading_chunked_body_len;
    }
}

- (void)readChunkedBodyTrailerFrom:(UMSocket *)sock
{
    int ret;
    
    ret = [headers readSomeHeadersFrom:sock];
    if (ret == -1)
        self.state = body_error;
    if (ret == 0)
        self.state = entity_done;
}

- (void)readBodyUntilEOFFrom:(UMSocket *)sock
{
    NSMutableData *os = nil;
    UMSocketError sErr;
    
    while (TRUE) {
        sErr = [sock receiveEverythingTo:&os];
        if (!os)
            break;
        [body appendData:os];
    }
    
    if (sErr == UMSocketError_no_data || sErr == UMSocketError_try_again)
        self.state = entity_done;
    else if (sErr != UMSocketError_try_again)
        self.state = body_error;
}

- (void)readBodyWithLengthFrom:(UMSocket *)sock
{
    NSMutableData *os;
    UMSocketError sErr;
    
    sErr = [sock receive:expected_body_len to:&os];
    if (!os) {
        if (sErr != UMSocketError_try_again)
        self.state = body_error;
        return;
    }
    
    self.body = os;
    self.state = entity_done;
}

/*
 * Read headers and body (if any) from this socket.  Return 0 if it's
 * complete, 1 if we expect more input, and -1 if there is something wrong.
 */
- (int)readEntityFrom:(UMSocket *)sock
{
    int ret;
    enum entity_state old_state;
    NSMutableArray *ourHeaders = [[NSMutableArray alloc] init];
    
    /*
     * In this loop, each state will process as much input as it needs
     * and then switch to the next state, unless it's a final state in
     * which case it returns directly, or unless it needs more input.
     * So keep looping as long as the state changes.
     */
    do {
        old_state = state;
        switch (state) {
            case reading_headers:
                ret = [ourHeaders readSomeHeadersFrom:sock];
                self.headers = ourHeaders;
                if (ret == 0)
                    [self deduceBodyState];
                if (ret < 0)
                    return -1;
                break;
                
            case reading_chunked_body_len:
                [self readChunkedBodyLenFrom:sock];
                break;
                
            case reading_chunked_body_data:
                [self readChunkedBodyDataFrom:sock];
                break;
                
            case reading_chunked_body_crlf:
                [self readChunkedBodyCRLFFrom:sock];
                break;
                
            case reading_chunked_body_trailer:
                [self readChunkedBodyTrailerFrom:sock];
                break;
                
            case reading_body_until_eof:
                [self readBodyUntilEOFFrom:sock];
                break;
                
            case reading_body_with_length:
                [self readBodyWithLengthFrom:(UMSocket *)sock];
                break;
            
            case body_error:
                return -1;
                
            case entity_done:
                return 0;
                
            default:
                 @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Internal error: Invalid HTTPEntity state." userInfo:nil];
        }
    } while (state != old_state);
    
    /*
     * If we got here, then the loop ended because a non-final state
     * needed more input.
     */
    return 1;
}

@end
