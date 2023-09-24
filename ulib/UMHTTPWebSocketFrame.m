//
//  UMHTTPWebSocketFrame.m
//  ulib
//
//  Created by Andreas Fink on 08.02.2020.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMHTTPWebSocketFrame.h>

@implementation UMHTTPWebSocketFrame


- (NSData *)encode
{
    uint8_t byte[32];
    int headerLen;
    
    byte[0] = (_fin ? 0x80 : 0x00 )
                | (_rsv1 ? 0x40 : 0x00 )
                | (_rsv2 ? 0x20 : 0x00 )
                | (_rsv3 ? 0x10 : 0x00 )
                | (_opcode & 0x0F);
    NSUInteger payloadLen = [_payload length];
    if(payloadLen <=125)
    {
        /* 1 bit length */
        byte[1] = (_mask ? 0x80 : 0x00) & (payloadLen);
        headerLen = 2;
    }
    else if(payloadLen<65536)
    {
        /* 16 bit length */
        byte[1] = (_mask ? 0x80 : 0x00) & 126;
        byte[2] = (payloadLen & 0xFF00) >> 8;
        byte[3] = (payloadLen & 0x00FF) >> 0;
        headerLen = 4;
    }
    else
    {
        /* 64 bit length */
        byte[1] = (_mask ? 0x80 : 0x00) & 127;
        byte[2] = (payloadLen & 0xFF00000000000000) >> 56;
        byte[3] = (payloadLen & 0x00FF000000000000) >> 48;
        byte[4] = (payloadLen & 0x0000FF0000000000) >> 40;
        byte[5] = (payloadLen & 0x000000FF00000000) >> 32;
        byte[6] = (payloadLen & 0x00000000FF000000) >> 24;
        byte[7] = (payloadLen & 0x0000000000FF0000) >> 16;
        byte[8] = (payloadLen & 0x000000000000FF00) >> 8;
        byte[9] = (payloadLen & 0x00000000000000FF) >> 0;
        headerLen = 10;
    }
    
    if(_mask)
    {
        byte[headerLen++] = (_maskingKey & 0xFF000000) >> 24;
        byte[headerLen++] = (_maskingKey & 0x00FF0000) >> 16;
        byte[headerLen++] = (_maskingKey & 0x0000FF00) >> 8;
        byte[headerLen++] = (_maskingKey & 0x000000FF) >> 0;
    }
    NSMutableData *data = [[NSMutableData alloc]initWithBytes:byte length:headerLen];
    [data appendData:_payload];
    return data;
}
@end
