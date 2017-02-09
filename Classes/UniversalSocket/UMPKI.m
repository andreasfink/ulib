//
//  UMPKI.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMPKI.h"

#if defined(HAS_OPENSSL1)
#import <openssl1/openssl1.h>
#endif

static UMPKI *gSharedUMPKI;

@implementation UMPKI
{
    
}

- (UMPKI *)sharedInstance
{
    if(gSharedUMPKI)
    {
        return gSharedUMPKI;
    }
    else
    {
        gSharedUMPKI = [[UMPKI alloc]init];
    }
    return gSharedUMPKI;
}

- (UMPKI *)init
{
    self = [super init];
    if(self)
    {
#if defined(HAS_OPENSSL1)
        OpenSSL_add_all_algorithms();
        ERR_load_crypto_strings();
#endif
    }
    return self;
}

- (void)destroy
{
#if defined(HAS_OPENSSL1)
    EVP_cleanup();
#endif
}

@end
