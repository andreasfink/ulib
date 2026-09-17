//
//  UMCrypto.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
#import <ulib/UMAssert.h>
#import <ulib/UMCrypto.h>
#import <ulib/UMSocket.h>

#include <stdio.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include "ulib_config.h"

#ifdef __APPLE__
    #include "TargetConditionals.h"
    #if TARGET_OS_WATCH
        #define HAVE_COMMON_CRYPTO 1
        #undef HAVE_OPENSSL
    #else
        #undef HAVE_COMMON_CRYPTO
        #define HAVE_OPENSSL 1
    #endif
#endif

#ifdef HAVE_OPENSSL
#include <openssl/bn.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/des.h>
#include <openssl/rsa.h>
#include <openssl/x509.h>
#include <openssl/rand.h>
#if OPENSSL_VERSION_NUMBER < 0x1010104fL
#error you need at least openssl 1.1.1d
#else
#define HAVE_TLS_METHOD 1
#endif

#endif

#include <string.h>



#ifdef HAVE_COMMON_CRYPTO
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/SecRandom.h>
#endif


@implementation UMCrypto

- (UMCrypto *)initWithFileDescriptor:(int)fd
{
    self = [super init];
    if(self)
    {
        _fileDescriptor=fd;
    }
    return self;
}

- (UMCrypto *)initWithRelatedSocket:(UMSocket *)s
{
    self = [super init];
    if(self)
    {
        _relatedSocket=s;
    }
    return self;
}


- (UMCrypto *)initPublicCrypto
{
    self = [super init];
    if(self)
    {
        [self generateRsaKeyPair];
    }
    return self;
}


- (int)fileDescriptor
{
    if(_relatedSocket)
    {
        return _relatedSocket.fileDescriptor;
    }
    else
    {
        return _fileDescriptor;
    }
}

- (void)setFileDescriptor:(int)fd
{
    _fileDescriptor = fd;
}

- (void)enableCrypto
{
	[self setEnable: 1];
}

- (void)disableCrypto
{
	[self setEnable: 0];
}

- (void)setSeed:(NSInteger)seed
{
	_pos = seed % _vectorSize;
	_method = 0;
}


#pragma mark -
#pragma mark Generic Read/Write IO

- (ssize_t)writeByte:(unsigned char)byte
          errorCode:(int *)eno
{
    size_t i = 0;
	if(!_enable)
	{
		i = write(self.fileDescriptor,  &byte,  1);
        *eno = errno;
		return i;
	}
    else
    {
        i = SSL_write((SSL *)_relatedSocket.ssl, &byte, 1);
    }
	return i;
}

- (ssize_t)writeBytes:(const unsigned char *)bytes
              length:(size_t)length
           errorCode:(int *)eno
{
    ssize_t i = 0;
	if(!_enable)
	{
        size_t bytesRemaining = length;
        size_t startPos = 0;
        size_t totalWritten=0;
        while((bytesRemaining > 0) && (startPos < length))
        {
            i = write(self.fileDescriptor,  &bytes[startPos],  bytesRemaining);
            if((i<0) && (errno==EAGAIN))
            {
                continue;
            }
            if(i>0)
            {

#ifdef HTTP_DEBUG
                NSLog(@"write (startpos=%d,bytes to write=%d) returns %d bytes written",(int)startPos,(int)bytesRemaining,(int)i);
#endif
                bytesRemaining = bytesRemaining -i;
                startPos = startPos + i;
                totalWritten = totalWritten + i;
            }
            if(i<0)
            {
                break;
            }
        }
        *eno = errno;
	}
    else
    {
        i = (int)SSL_write((SSL *)_relatedSocket.ssl, bytes, (int)length);
        *eno = errno;
    }
	return i;
}

- (ssize_t)readBytes:(unsigned char *)bytes
              length:(size_t)length
           errorCode:(int *)eno
{
	if(_enable)
	{
        int k2 = SSL_read((SSL *)_relatedSocket.ssl,bytes, (int)length);
        if(k2<0)
        {
            int e = SSL_get_error((SSL *)_relatedSocket.ssl,k2);
            if((e == SSL_ERROR_WANT_READ) || (e == SSL_ERROR_WANT_WRITE))
            {
                *eno = EAGAIN;
                return 0;
            }
            else if(e == SSL_ERROR_SYSCALL)
            {
                *eno = errno;
                return 0;
            }
            else if(e == SSL_ERROR_NONE)
            {
                *eno = 0;
                return 0;
            }
            else
            {
                NSLog(@"SSL read failed: OpenSSL error %d: %s",e, ERR_error_string(e, NULL));
                *eno = e;
                return -1;
            }
        }
        return k2;
	}
    else
    {
        ssize_t k = read(self.fileDescriptor,bytes, length);
        if(k<0)
        {
            int e = errno;
#if defined(EWOULDBLOCK)
            if ((e == EINTR) || (e == EAGAIN) || (e == EWOULDBLOCK))
#else
            if ((e == EINTR) || (e == EAGAIN))
#endif
            {
                *eno = e;
                return 0;
            }
        }
        else if(k==0)
        {
            *eno = ECONNRESET;
        }
        return k;
    }
}


+ (NSData *)randomDataOfLength:(size_t)length
{
    return [UMCrypto SSLRandomDataOfLength:length];
}

#pragma mark -
#pragma mark DES

- (UMCrypto *)initDESInitWithSaltAndIV
{
    self = [super init];
    if (self)
    {
        unsigned char *iv_string = OPENSSL_malloc(DES_BLOCK_SIZE);
        unsigned char *_salt = OPENSSL_malloc(DES_SALT_LEN);
        RAND_seed(_salt, DES_SALT_LEN);
        RAND_seed(iv_string, DES_BLOCK_SIZE);
        _iv = [[NSData alloc] initWithBytes:iv_string length:DES_BLOCK_SIZE];
        _saltData = [NSData dataWithBytes:_salt length:DES_SALT_LEN];
        OPENSSL_free(_salt);
        OPENSSL_free(iv_string);
    }
    return self;
}

/*     int RAND_bytes(unsigned char *buf, int num); */

- (UMCrypto *)initDESInitWithKeyWithEntropySource:(NSString *)file withGrade:(int)grade;
{
    char *entropy;
    //int n;
    unsigned char block[8];
    unsigned char DESKey[DES_KEY_LEN];
    int i, nrounds = 1000/grade;
    unsigned char DESIV[DES_BLOCK_SIZE];

#define RANDOM_SIZE sizeof(block)
    

    self = [super init];
    if (self)
    {
        /* Seeding */
        entropy = (char *)[file UTF8String];
        /*n = */RAND_load_file(entropy, 4 * DES_KEY_LEN);
        
        /* Generating */
        unsigned char *salt = OPENSSL_malloc(DES_SALT_LEN);
        RAND_seed(salt, DES_SALT_LEN);
        int result = RAND_bytes(salt, DES_SALT_LEN);
        /* OpenSSL reports a failure, act accordingly */
        UMAssert((result != 0), @"Unable to generate random bytes: %d",
                 errno);
 
        RAND_bytes(&block[0], sizeof(block));
        i = EVP_BytesToKey(EVP_des_cbc(), EVP_sha1(), salt, block, sizeof(block), nrounds, DESKey, DESIV);
        if (i != 8)
        { //bytes !!!
            NSLog(@"Key size is %d bits - should be 56 bits\n", i);
            return nil;
        }
        
        _deskey = [[NSData alloc] initWithBytes:DESKey length:DES_KEY_LEN];
        OPENSSL_free(salt);
    }
	return self;
}

+ (NSData *)SSLRandomDataOfLength:(size_t)length
{
    unsigned char *ptr = calloc(1,length);
    int result = RAND_bytes(ptr, (int)length);
    /* OpenSSL reports a failure, act accordingly */
    UMAssert(result != 0, @"Unable to generate random bytes: %d %s",errno,strerror(errno));
    NSData *data = [NSData dataWithBytes:ptr length:length];
    free(ptr);
    return data;
}

- (void)logOpenSSLErrors:(NSString *)err
{
    NSLog(@"SSL Error: %@",err);
}

- (NSData *)RSAEncryptWithPlaintextSSLPublic:(NSData *)plaintext
{
    return plaintext;
}

- (NSData *)RSADecryptWithCiphertextSSLPrivate:(NSData *)ciphertext
{
    return ciphertext;
}



/**
 * Encrypt *len bytes of data, with initalization vector and generated DESK key
 * All data going in out is considered binary (NSData)
 * Returns ciphertext, and DES key created from the password.
 * Grade is number between 1 and 20. 1 némans highest security but slowest excution.
 */
- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext
                       havingLength:(int *)len
                       withPassword:(NSData *)password
                            withKey:(NSData **)key
                          withGrade:(int)grade
{
    return NULL;
}

/**
 * Encrypt *len bytes of data, with with input password
 * All data going in out is considered binary (NSData)
 * Returns ciphertext.
 */
- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext havingLength:(int *)len withPassword:(NSData *)password
{
    return NULL;
}

/**
 * Decrypt *len bytes of ciphertext, DES
 */
- (NSData *)DESDecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    return NULL;
}
/**
 * Decrypt *len bytes of ciphertext, DES
 */
- (NSData *)RC4DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    return NULL;
}

/**
 * Decrypt *len bytes of ciphertext, 3DES
 */
- (NSData *)DES3DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    return NULL;
}

                                   
/**
 * Decrypt *len bytes of ciphertext, CSAT3
 */
- (NSData *)CAST5DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    return NULL;
}

- (NSData *)decryptDataWithSSL:(NSData *)data withKey:(NSData *)key
{    
    NSData *plaintext;
    int len;
    
    len = (int)[data length];
    
    plaintext = [self DESDecryptWithCiphertext:data havingLength:&len withKey:key];
    if (plaintext)
    {
        return plaintext;
    }
    plaintext = [self RC4DecryptWithCiphertext:data havingLength:&len withKey:key];
    if (plaintext)
    {
        return plaintext;
    }
    
    plaintext = [self DES3DecryptWithCiphertext:data havingLength:&len withKey:key];
    if (plaintext)
    {
        return plaintext;
    }
    
    plaintext = [self CAST5DecryptWithCiphertext:data havingLength:&len withKey:key];
    if (plaintext)
    {
        return plaintext;
    }
    return nil;
}

- (UMCrypto *) copyWithZone:(NSZone *)zone
{
    UMCrypto *no = [[UMCrypto alloc]init];
    no.enable = _enable;
    no.pos = 0;
    no.method = _method;
    no.vectorSize = _vectorSize;
    no.deskey = _deskey;
    no.cryptorKey = _cryptorKey;
    no.saltData = _saltData;
    no.iv = _iv;
    no.publicKey = _publicKey;
    no.privateKey = _privateKey;
    no->_fileDescriptor = _fileDescriptor;
    no.relatedSocket = _relatedSocket;
    no.publicKey = _publicKey;
    no.privateKey = _privateKey;
    no.aes256Key = _aes256Key;
//   no.peer_certificate = peer_certificate;
 //   no.local_certificate = local_certificate;

    return no;
}


-(void)generateRsaKeyPair
{
    [self generateRsaKeyPair:4096 pub:65537];
}

- (void)generateRsaKeyPair:(int)keyLength pub:(unsigned long)pubInt
{
    return;
}

- (NSData *)aes256RandomKey
{
    return [UMCrypto SSLRandomDataOfLength:32];
}

- (NSData *)aes256RandomIV
{
    return [UMCrypto SSLRandomDataOfLength:16];
}

- (void)logOpenSSLErrorsForSection:(NSString *)section
{

    NSLog(@"OpenSSL Error in %@:",section);

    unsigned long e = ERR_get_error();
    while(e)
    {
        char ebuf[256];
        memset(ebuf,0,sizeof(ebuf));
        ERR_error_string_n(e, &ebuf[0],sizeof(ebuf)-1);
        NSLog(@" %lu %s",e,ebuf);

        e = ERR_get_error();
    }
}

- (NSData *)aes256Encrypt:(NSData *)plaintext
{
    return [self aes256Encrypt:plaintext key:_aes256Key iv:NULL];
}

- (NSData *)aes256Decrypt:(NSData *)ciphertext
{
    return [self aes256Decrypt:ciphertext key:_aes256Key iv:NULL];
}

- (NSData *)aes256Encrypt:(NSData *)plaintext key:(NSData *)key
{
    return [self aes256Encrypt:plaintext key:key iv:NULL];
}

- (NSData *)aes256Decrypt:(NSData *)plaintext key:(NSData *)key
{
    return [self aes256Encrypt:plaintext key:key iv:NULL];
}

- (NSData *)aes256Encrypt:(NSData *)plaintext
                      key:(NSData *)key
                       iv:(NSData *)iv;
{
    const unsigned char *plaintext_ptr = plaintext.bytes;
    int plaintext_len = (int)plaintext.length;

    unsigned char *ciphertext_ptr = NULL;
    int ciphertext_len = 0;
    NSData *ciphertext=NULL;

    const unsigned char *key_ptr = key.bytes;
    int key_len = (int)key.length;
    const unsigned char *iv_ptr = NULL;
    if(iv)
    {
        iv_ptr = iv.bytes;
    }

    int len = 0;
    /* Create and initialise the context */
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if(ctx==NULL)
    {
        NSLog(@"can not allocate EVP_CIPHER_CTX_new context");
    }
    else
    {

        /* Initialise the encryption operation. IMPORTANT - ensure you use a key
         * and IV size appropriate for your cipher
         * In this example we are using 256 bit AES (i.e. a 256 bit key). The
         * IV size for *most* modes is the same as the block size. For AES this
         * is 128 bits */
        if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key_ptr, iv_ptr))
        {
            [self logOpenSSLErrorsForSection: @"aes256Encrypt: EVP_EncryptInit_ex"];
        }
        else
        {
            /* Provide the message to be encrypted, and obtain the encrypted output.
             * EVP_EncryptUpdate can be called multiple times if necessary
             */
            ciphertext_len = plaintext_len + 2*key_len; /* leave enough space for padding etc */
            ciphertext_ptr = malloc(ciphertext_len);
            memset(ciphertext_ptr,0x00,ciphertext_len);
            if(1 != EVP_EncryptUpdate(ctx, ciphertext_ptr, &len, plaintext_ptr, plaintext_len))
            {
                [self logOpenSSLErrorsForSection: @"aes256Encrypt: EVP_EncryptUpdate"];
            }
            else
            {
                ciphertext_len = len;

                /* Finalise the encryption. Further ciphertext bytes may be written at
                 * this stage.
                 */
                if(1 != EVP_EncryptFinal_ex(ctx, ciphertext_ptr + len, &len))
                {
                    [self logOpenSSLErrorsForSection: @"aes256Encrypt: EVP_EncryptFinal_ex"];
                }
                else
                {
                    ciphertext_len += len;
                    ciphertext = [NSData dataWithBytes:ciphertext_ptr length:ciphertext_len];
                    free((void *)ciphertext_ptr);
                    ciphertext_ptr=NULL;
                }
            }
        }
        /* Clean up */
        EVP_CIPHER_CTX_free(ctx);
    }
    if(ciphertext_ptr)
    {
        free((void *)ciphertext_ptr);
        ciphertext_ptr=NULL;
    }
    return ciphertext;
}


- (NSData *)aes256Decrypt:(NSData *)ciphertext key:(NSData *)key iv:(NSData *)iv
{
    const unsigned char *ciphertext_ptr = ciphertext.bytes;
    int ciphertext_len = (int)ciphertext.length;
    
    unsigned char *plaintext_ptr = NULL;
    int plaintext_len = 0;
    NSData *plaintext=NULL;
    
    const unsigned char *key_ptr = key.bytes;
    int key_len = (int)key.length;

    const unsigned char *iv_ptr = NULL;
    if(iv)
    {
        iv_ptr = iv.bytes;
    }
    
    int len = 0;
    /* Create and initialise the context */
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if(ctx==NULL)
    {
        NSLog(@"can not allocate EVP_CIPHER_CTX_new context");
    }
    else
    {
        
        /* Initialise the encryption operation. IMPORTANT - ensure you use a key
         * and IV size appropriate for your cipher
         * In this example we are using 256 bit AES (i.e. a 256 bit key). The
         * IV size for *most* modes is the same as the block size. For AES this
         * is 128 bits */
        if(1 != EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key_ptr, iv_ptr))
        {
            [self logOpenSSLErrorsForSection: @"aes256Decrypt: EVP_DecryptInit_ex"];
        }
        else
        {
            /* Provide the message to be decrypted, and obtain the encrypted output.
             * EVP_EncryptUpdate can be called multiple times if necessary
             */
            
            plaintext_len = ciphertext_len + 2*key_len; /* leave enough space for padding etc */
            plaintext_ptr = OPENSSL_malloc(plaintext_len);
            memset(plaintext_ptr,0x00,plaintext_len);

            if(1 != EVP_DecryptUpdate(ctx, plaintext_ptr, &len, ciphertext_ptr, ciphertext_len))
            {
                [self logOpenSSLErrorsForSection: @"aes256Decrypt: EVP_DecryptUpdate"];
            }
            else
            {
                plaintext_len = len;
                
                /* Finalise the decryption. Further plaintext bytes may be written at
                 * this stage.
                 */
                if(1 != EVP_DecryptFinal_ex(ctx, plaintext_ptr + len, &len))
                {
                }
                else
                {
                    plaintext_len += len;
                }
                plaintext = [NSData dataWithBytes:plaintext_ptr length:plaintext_len];
                OPENSSL_free((void *)plaintext_ptr);
                plaintext_ptr=NULL;
            }
        }
        /* Clean up */
        EVP_CIPHER_CTX_free(ctx);
    }
    
    if(plaintext_ptr)
    {
        OPENSSL_free((void *)plaintext_ptr);
        plaintext_ptr=NULL;
    }

    return plaintext;
}

@end
