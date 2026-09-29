//
//  UMLayerSctpUser.h
//  ulibsctp
//
//  Created by Andreas Fink on 02.12.14.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import <ulib/UMObject.h>
#import <ulib/UMLayerSctpUserProtocol.h>

@class UMLayerSctpUserProfile;

@interface UMLayerSctpUser : UMObject
{
    id<UMLayerSctpUserProtocol>         _user;
    UMLayerSctpUserProfile              *_profile;
    id                                  _userId;
}

@property(readwrite,strong)   id<UMLayerSctpUserProtocol> user;
@property(readwrite,strong) UMLayerSctpUserProfile     *profile;
@property(readwrite,strong) id                          userId;

@end
