//
//  UMProtocolBuffer.m
//  ulib
//
//  Created by Andreas Fink on 20.09.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMProtocolBuffer.h"
#import "UMMutex.h"

static inline uint64_t ZigZag(int64_t a)
{
    if(a < 0)
    {
        return ((a<<2) | 0x01);
    }
    return ((a<<2) | 0x01);
}

@implementation UMProtocolBuffer

- (UMProtocolBuffer *)init
{
    self = [super init];
    if(self)
    {
        _buffer = [[NSMutableData alloc]init];
        _lock = [[UMMutex alloc]initWithName:@"protocol-buffer"];
    }
    return self;
}

- (UMProtocolBuffer *)initWithBuffer:(NSData *)d
{
    self = [super init];
    if(self)
    {
        _buffer = [d mutableCopy];
        _lock = [[UMMutex alloc]initWithName:@"protocol-buffer"];
    }
    return self;
}

- (NSData *)buffer
{
    return [_buffer copy];
}

- (void)setBuffer:(NSData *)buffer
{
    _buffer = [buffer mutableCopy];
}

/* see also https://developers.google.com/protocol-buffers/docs/encoding */

-(void)appendVarint:(uint64_t)i
{
    uint8_t buf[10];
    int bufcount=0;
    while(1)
    {
        uint8_t val = i & 0x7F;
        i = i >> 7;
        if(i>0) /* we set bit 8 if theres more to follow */
        {
            val = val | 0x80;
        }
        buf[bufcount++] = val;
        if((i==0) || (bufcount >= sizeof(buf)))
        {
            break;
        }
    }
    [_buffer appendBytes:&buf length:bufcount];
}

#define APPEND_CODE_VARTYPE(field_number,wire_type) \
    [self appendVarint: (field_number << 3) | wire_type];

-(void)appendTag:(int)code int32:(int32_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}

#define PROTOBUF_WIRE_TYPE_VARINT            0
#define PROTOBUF_WIRE_TYPE_64BIT_FIXED       1
#define PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED  2
#define PROTOBUF_WIRE_TYPE_START_GROUP       3
#define PROTOBUF_WIRE_TYPE_END_GROUP         4
#define PROTOBUF_WIRE_TYPE_32BIT_FIXED       5


-(void)appendTag:(int)code int64:(int64_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}

-(void)appendTag:(int)code uint32:(uint32_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}
-(void)appendTag:(int)code uint64:(uint64_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}
-(void)appendTag:(int)code sint32:(int32_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}
-(void)appendTag:(int)code sint64:(int64_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}
-(void)appendTag:(int)code bool:(BOOL)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}
-(void)appendTag:(int)code enum:(int)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}

-(void)appendTag:(int)code fixed64:(uint64_t)i
{
    uint8_t buf[8];
    buf[7] = (i >> 56) & 0xFF;;
    buf[6] = (i >> 48) & 0xFF;;
    buf[5] = (i >> 40) & 0xFF;;
    buf[4] = (i >> 32) & 0xFF;;
    buf[3] = (i >> 24) & 0xFF;
    buf[2] = (i >> 16) & 0xFF;;
    buf[1] = (i >> 8) & 0xFF;
    buf[0] = i & 0xFF;
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_64BIT_FIXED];
    [_buffer appendBytes:&buf length:8];
}

-(void)appendTag:(int)code sfixed64:(int64_t)i
{
    [self appendTag:code fixed64:ZigZag(i)];
}

-(void)appendTag:(int)code double:(double)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_64BIT_FIXED];
    [self appendVarint: (uint64_t)i];
}
-(void)appendTag:(int)code string:(NSString *)s
{
    NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED];
    [self appendVarint: d.length];
    [_buffer appendBytes:d.bytes length:d.length];

}
-(void)appendTag:(int)code bytes:(NSData *)d
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED];
    [self appendVarint: d.length];
    [_buffer appendBytes:d.bytes length:d.length];
}

-(void)appendTag:(int)code embeddedMessage:(id<UMProtocolBufferProtocol>)pb
{
    NSData *d = pb.buffer;
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED];
    [self appendVarint: d.length];
    [_buffer appendBytes:d.bytes length:d.length];
}

-(void)appendTag:(int)code packetRepeatedFields:(NSArray<id<UMProtocolBufferProtocol>> *)protocolBuffers
{
    NSMutableData *d = [[NSMutableData alloc]init];
    for(id<UMProtocolBufferProtocol>pb in protocolBuffers)
    {
        NSData *d1 = pb.buffer;
        [d appendData:d1];
    }
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED];
    [self appendVarint: d.length];
    [_buffer appendBytes:d.bytes length:d.length];
}

-(void)appendTag:(int)code fixed32:(uint32_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}

-(void)appendTag:(int)code sfixed32:(int32_t)i
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_VARINT];
    [self appendVarint: i];
}

-(void)appendTag:(int)code startGroup:(NSData *)d
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED];
    [self appendVarint: d.length];
    [_buffer appendBytes:d.bytes length:d.length];

}

-(void)appendTag:(int)code endGroup:(NSData *)d
{
    [self appendVarint: (code << 3) | PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED];
    [self appendVarint: d.length];
    [_buffer appendBytes:d.bytes length:d.length];
}

@end
