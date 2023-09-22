//
//  UMPacket.h
//  ulib
//
//  Created by Andreas Fink on 07.08.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMSocketDefs.h>

@interface UMPacket : UMObject
{
    NSNumber        *_socket;
    UMSocketError   _err;
    NSString        *_remoteAddress;
    int             _remotePort;
    NSData          *_data;
}


@property(readwrite,strong,atomic)  NSNumber        *socket;
@property(readwrite,assign,atomic)  UMSocketError   err;

@property(readwrite,strong,atomic)  NSString        *remoteAddress;
@property(readwrite,assign,atomic)  int             remotePort;
@property(readwrite,strong,atomic)  NSData          *data;

@end
