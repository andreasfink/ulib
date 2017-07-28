//
//  UMPublicKey.h
//  ulib
//
//  Created by Andreas Fink on 28.07.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

@interface UMPublicKey : UMObject
{
    NSData *_pem_key;
    void *_pkey; /* this is actually EVP_PKEY * but we dont want to require to
                    include ssl headers on applications which use ulib */
}


- (UMPublicKey *)initWithFilename:(NSString *)filename;
- (UMPublicKey *)initWithData:(NSData *)filename;
- (UMPublicKey *)initWithFilename:(NSString *)filename password:(NSString *)password;
- (UMPublicKey *)initWithData:(NSData *)filename  password:(NSString *)password;


@end
