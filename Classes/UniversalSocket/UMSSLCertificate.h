//
//  UMSSLCertificate.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMObject.h"

#if defined(HAS_OPENSSL1)
#import <openssl1/openssl1.h>
#endif

@interface UMSSLCertificate : UMObject
{
#if defined(HAS_OPENSSL1)
    SSL *ssl;
    X509 *peer_certificate;
#endif
}
@end
