//
//  UMProtocolBuffer.h
//  ulib
//
//  Created by Andreas Fink on 20.09.18.
//  Copyright © 2018 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMObject.h"
#import "UMMutex.h"

#define PROTOBUF_WIRE_TYPE_VARINT            0
#define PROTOBUF_WIRE_TYPE_64BIT_FIXED       1
#define PROTOBUF_WIRE_TYPE_LENGTH_DELIMITED  2
#define PROTOBUF_WIRE_TYPE_START_GROUP       3
#define PROTOBUF_WIRE_TYPE_END_GROUP         4
#define PROTOBUF_WIRE_TYPE_32BIT_FIXED       5

@protocol UMProtocolBufferProtocol<NSObject>
@property(readwrite)    NSData *buffer;
@end

@interface UMProtocolBuffer : UMObject
{
    NSMutableData *_buffer;
    UMMutex *_lock;
}

@property(readwrite)    NSData *buffer;

-(void)appendVarint:(uint64_t)i;
-(void)appendTag:(int)code int32:(int32_t)i;
-(void)appendTag:(int)code int64:(int64_t)i;
-(void)appendTag:(int)code uint32:(uint32_t)i;
-(void)appendTag:(int)code uint64:(uint64_t)i;
-(void)appendTag:(int)code sint32:(int32_t)i;
-(void)appendTag:(int)code sint64:(int64_t)i;
-(void)appendTag:(int)code bool:(BOOL)i;
-(void)appendTag:(int)code enum:(int)i;
-(void)appendTag:(int)code fixed64:(uint64_t)i;
-(void)appendTag:(int)code sfixed64:(int64_t)i;
-(void)appendTag:(int)code double:(double)i;
-(void)appendTag:(int)code string:(NSString *)s;
-(void)appendTag:(int)code bytes:(NSData *)d;
-(void)appendTag:(int)code embeddedMessage:(id<UMProtocolBufferProtocol>)d;
-(void)appendTag:(int)code packetRepeatedFields:(NSArray<id<UMProtocolBufferProtocol>> *)d;
-(void)appendTag:(int)code fixed32:(uint32_t)i;
-(void)appendTag:(int)code sfixed32:(int32_t)i;
-(void)appendTag:(int)code startGroup:(NSData *)d;
-(void)appendTag:(int)code endGroup:(NSData *)d;

@end

