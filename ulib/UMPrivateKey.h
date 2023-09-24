//
//  UMPrivateKey.h
//  ulib
//
//  Created by Andreas Fink on 28.07.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>

@interface UMPrivateKey : UMObject
{
    NSData *_pem_key;
    void *_pkey; /* this is actually EVP_PKEY * but we dont want to require to
                  include ssl headers on applications which use ulib */
}
@end
