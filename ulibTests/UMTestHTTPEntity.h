//
//  UMTestHTTPEntity.h
//  ulib
//
//  Created by Aarno Syvänen on 27.04.12.
//  Copyright (c) Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

enum body_expectation {
    /*
     * Message must not have a body, even if the headers indicate one.
     * (i.e. response to HEAD method).
     */
    expect_no_body,
    /*
     * Message will have a body if Content-Length or Transfer-Encoding
     * headers are present (i.e. most request methods).
     */
    expect_body_if_indicated,
    /*
     * Message will have a body, possibly zero-length.
     * (i.e. 200 OK responses to a GET method.)
     */
    expect_body
};

enum entity_state {
    reading_headers,
    reading_chunked_body_len,
    reading_chunked_body_data,
    reading_chunked_body_crlf,
    reading_chunked_body_trailer,
    reading_body_until_eof,
    reading_body_with_length,
    body_error,
    entity_done
};

@class UMSocket;

@interface UMTestHTTPEntity : UMObject
{
    NSMutableArray *headers;
    NSMutableData *body;
    enum body_expectation expect_state;
    enum entity_state state;
    long chunked_body_chunk_len;
    long expected_body_len;
}

@property(readwrite,strong)	NSMutableArray *headers;
@property(readwrite,strong)	NSMutableData *body;
@property(readwrite,assign) enum body_expectation expect_state;
@property(readwrite,assign) enum entity_state state;
@property(readwrite,assign) long chunked_body_chunk_len;
@property(readwrite,assign) long expected_body_len;

- (UMTestHTTPEntity *)initWithBodyExpectation:(enum body_expectation)exp;
- (UMTestHTTPEntity *)initWithEntity:(UMTestHTTPEntity *)ent;
- (NSString *)description;
- (void)deduceBodyState;
- (void)readChunkedBodyLenFrom:(UMSocket *)sock;
- (void)readChunkedBodyDataFrom:(UMSocket *)sock;
- (void)readChunkedBodyCRLFFrom:(UMSocket *)sock;
- (void)readChunkedBodyTrailerFrom:(UMSocket *)sock;
- (void)readBodyUntilEOFFrom:(UMSocket *)sock;
- (void)readBodyWithLengthFrom:(UMSocket *)sock;
- (int)readEntityFrom:(UMSocket *)sock;

@end
