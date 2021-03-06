//
//  UMPublicKey.m
//  ulib
//
//  Created by Andreas Fink on 28.07.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMPublicKey.h"

#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>
#include <openssl/bio.h>
#include <openssl/err.h>

//static int password_read_callback(char *buf, int size, int rwflag, void *u);

@implementation UMPublicKey

- (UMPublicKey *)initWithFilename:(NSString *)filename
{
    return [self initWithData:[NSData dataWithContentsOfFile:filename]];
}


- (void)dealloc
{
    if(_pkey)
    {
        EVP_PKEY_free((EVP_PKEY *)_pkey);
    }
    _pkey = NULL;
}


- (UMPublicKey *)initWithData:(NSData *)data
{
    self = [super init];
    if(self)
    {
        BIO *bufio = BIO_new_mem_buf((void*)data.bytes, (int)data.length);
        if(bufio == NULL)
        {
            NSString *s = [NSString stringWithFormat:@"BIO_new_mem_buf() returns NULL, Error=%ld",ERR_get_error()];
            @throw([NSException exceptionWithName:@"MEMORY_ALLOC_FAIL" reason:s userInfo:NULL]);
        }

        EVP_PKEY *_pkey2 = EVP_PKEY_new();
        if(_pkey2 == NULL)
        {
            NSString *s = [NSString stringWithFormat:@"RSA_new() returns NULL, Error=%ld",ERR_get_error()];
            @throw([NSException exceptionWithName:@"MEMORY_ALLOC_FAIL" reason:s userInfo:NULL]);
        }
// what about?        b2i_PublicKey(<#const unsigned char **in#>, <#long length#>)
        {
            _pkey = (void *)PEM_read_bio_PrivateKey(bufio, &_pkey2,NULL,NULL);
        }
        BIO_free(bufio);
    }
    return self;
}

#if 0
/* The default passphrase callback is sometimes inappropriate (for example in a GUI
 application) so an alternative can be supplied. The callback routine has the
 following form:

 int cb(char *buf, int size, int rwflag, void *u);

 buf is the buffer to write the passphrase to. size is the maximum length of the
 passphrase (i.e. the size of buf). rwflag is a flag which is set to 0 when
 reading and 1 when writing. A typical routine will ask the user to verify the
 passphrase (for example by prompting for it twice) if rwflag is 1. The u
 parameter has the same value as the u parameter passed to the PEM routine. It
 allows arbitrary data to be passed to the callback by the application (for
 example a window handle in a GUI application). The callback must return the
 number of characters in the passphrase or 0 if an error occurred.
 */

static int password_read_callback(char *buf, int size, int rwflag, void *u)
{
    int n = (int)strlen((char *)u);
    if(n>size)
    {
        n=size;
    }
    strncpy(buf,u,size);
    return n;
}

/*
password callback function:
        int cb(char *buf, int size, int rwflag, void *u);
*/
#endif

@end
