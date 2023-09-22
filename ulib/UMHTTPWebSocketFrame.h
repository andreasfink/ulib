//
//  UMHTTPWebSocketFrame.h
//  ulib
//
//  Created by Andreas Fink on 08.02.2020.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>

typedef enum UMHTTPWebSocketOpcode
{
    UMHTTPWebSocketOpcode_continuationFrame = 0x0,
    UMHTTPWebSocketOpcode_textFrame = 0x1,
    UMHTTPWebSocketOpcode_binaryFrame = 0x2,
    UMHTTPWebSocketOpcode_reservedNonControl3 = 0x4,
    UMHTTPWebSocketOpcode_reservedNonControl4 = 0x5,
    UMHTTPWebSocketOpcode_reservedNonControl5 = 0x6,
    UMHTTPWebSocketOpcode_reservedNonControl7 = 0x7,
    UMHTTPWebSocketOpcode_connectionClose = 0x8,
    UMHTTPWebSocketOpcode_ping = 0x9,
    UMHTTPWebSocketOpcode_pong = 0xA,
    UMHTTPWebSocketOpcode_reservedControlB = 0xB,
    UMHTTPWebSocketOpcode_reservedControlC = 0xC,
    UMHTTPWebSocketOpcode_reservedControlD = 0xD,
    UMHTTPWebSocketOpcode_reservedControlE = 0xE,
    UMHTTPWebSocketOpcode_reservedControlF = 0xF,
} UMHTTPWebSocketOpcode;

@interface UMHTTPWebSocketFrame : UMObject
{
    BOOL                    _fin;
    BOOL                    _rsv1;
    BOOL                    _rsv2;
    BOOL                    _rsv3;
    UMHTTPWebSocketOpcode   _opcode;
    BOOL                    _mask;
    uint32_t                _maskingKey;
    NSData                  *_payload;
}

@property(readwrite,assign,atomic)  BOOL                    fin;
@property(readwrite,assign,atomic)  BOOL                    rsv1;
@property(readwrite,assign,atomic)  BOOL                    rsv2;
@property(readwrite,assign,atomic)  BOOL                    rsv3;
@property(readwrite,assign,atomic)  UMHTTPWebSocketOpcode   opcode;
@property(readwrite,assign,atomic)  BOOL                    mask;
@property(readwrite,assign,atomic)  uint32_t                maskingKey;
@property(readwrite,strong,atomic)  NSData                  *payload;

- (NSData *)encode;
@end

