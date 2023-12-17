//
//  UMKeypair.h
//  ulib
//
//  Created by Andreas Fink on 28.07.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>

@class UMPublicKey;
@class UMPrivateKey;

@interface UMKeypair : UMObject
{
    UMPublicKey *_publicKey;
    UMPrivateKey *_privateKey;
}
@end
