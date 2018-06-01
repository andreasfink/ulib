//
//  UMCrypto.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import "UMAssert.h"
#import "UMCrypto.h"
#import "UMSocket.h"

#include <stdio.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>
#include "ulib_config.h"

#ifdef HAVE_OPENSSL
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/evp.h>
#include <openssl/err.h>
#include <openssl/ssl.h>
#include <openssl/des.h>
#include <openssl/rsa.h>
#include <openssl/x509.h>
#include <openssl/rand.h>
#include <string.h>
#endif


#ifdef HAVE_COMMON_CRYPTO
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/SecRandom.h>
#endif


@implementation UMCrypto

@synthesize enable;
@synthesize pos;
@synthesize method;
@synthesize vectorSize;
@synthesize salt;
@synthesize iv;
@synthesize publicKey;
@synthesize privateKey;
@synthesize deskey;
@synthesize cryptorKey;
//@synthesize fileDescriptor;
@synthesize relatedSocket;


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
        relatedSocket=s;
    }
    return self;
}

- (UMCrypto *)initWithKey
{
    
#ifdef HAS_COMMON_CRYPTO
    SecKeyRef cryptokey;
    CFErrorRef error;
#endif
    
    self = [super init];
    if(self)
    {
#ifdef HAS_COMMON_CRYPTO
        CFMutableDictionaryRef parameters = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                                      &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionarySetValue(parameters, kSecAttrKeyType, kSecAttrKeyType3DES);
        
        int32_t rawnum = kCCKeySize3DES * 8;
        CFNumberRef num = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &rawnum);
        CFDictionarySetValue(parameters, kSecAttrKeySizeInBits, num);
        CFRelease(num);
        
        cryptokey = SecKeyGenerateSymmetric(parameters, &error);
        if (!cryptokey)
        {
            return nil;
        }
        cryptorKey = [self dataFromRef:cryptokey];
#endif
    }
	return self;
}

#ifdef HAS_COMMON_CRYPTO
- (UMCrypto *)initPublicCrypto
{
    self = [super init];
    if (self)
    {
        NSArray *keys = @[[NSString stringWithUTF8String:kSecAttrKeyType],
                            [NSString stringWithUTF8String:kSecAttrKeySizeInBits]];
    
        NSArray *values = @[[NSString stringWithUTF8String:kSecAttrKeyTypeRSA],
                           @RSA_KEY_LEN];
        NSDictionary *parameters = [NSDictionary dictionaryWithObjects:values forKeys:keys];


        SecKeyRef public, private;
        OSStatus status = SecKeyGeneratePair((__bridge CFDictionaryRef)parameters, &public, &private);
        if (status != errSecSuccess)
        {
            return nil;
        }
        publicKey = [self dataFromRef:public];
        privateKey = [self dataFromRef:private];
    }    
    return self;
}
#endif

- (int)fileDescriptor
{
    if(relatedSocket)
    {
        return relatedSocket.fileDescriptor;
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
#if USE_SSL
    useSSL = YES;
#endif
}

- (void)disableCrypto
{
	[self setEnable: 0];
#if USE_SSL
    useSSL = NO;
#endif

}

#ifdef HAS_COMMON_CRYPTO
- (const char *)cryptErrorString:(int)code
{
    switch(code)
    {
        case kCCSuccess:
            return "kCCSuccess";
        case kCCParamError:
            return "kCCParamError";
        case kCCBufferTooSmall:
            return "kCCBufferTooSmall";
        case kCCMemoryFailure:
            return "kCCMemoryFailure";
        case kCCAlignmentError:
            return "kCCAlignmentError";
        case kCCDecodeError:
            return "kCCDecodeError";
        case kCCUnimplemented:
            return "kCCUnimplemented";
    }
    return "";
}
#endif

- (void)setSeed:(NSInteger)seed
{
	pos = seed % vectorSize;
	method = 0;
}


#pragma mark -
#pragma mark Generic Read/Write IO

- (ssize_t)writeByte:(unsigned char)byte
          errorCode:(int *)eno
{
    size_t i = 0;
	if(!enable)
	{
		i = write(self.fileDescriptor,  &byte,  1);
        *eno = errno;
		return i;
	}
    else
    {
        i = SSL_write((SSL *)relatedSocket.ssl, &byte, 1);
    }
	return i;
}

- (ssize_t)writeBytes:(const unsigned char *)bytes
              length:(size_t)length
           errorCode:(int *)eno
{
    ssize_t i = 0;
	if(!enable)
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
        i = (int)SSL_write((SSL *)relatedSocket.ssl, bytes, (int)length);
        *eno = errno;
    }
	return i;
}

- (ssize_t)readBytes:(unsigned char *)bytes
             length:(size_t)length
          errorCode:(int *)eno
{
	if(enable)
	{
        int k2 = SSL_read((SSL *)relatedSocket.ssl,bytes, (int)length);
        if(k2<0)
        {
            int e = SSL_get_error((SSL *)relatedSocket.ssl,k2);
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
            if (e == EINTR || e == EAGAIN || e == EWOULDBLOCK)
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

#ifdef HAS_KEYCHAIN_UTILITIES

#pragma mark Keychain Stuff

-(NSData *)dataFromRef:(SecKeyRef)keyRef
{
    // Create and populate the parameters object with a basic set of values
    SecItemImportExportKeyParameters params;
    params.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
    params.flags = 0;
    params.passphrase = NULL;
    params.alertTitle = NULL;
    params.alertPrompt = NULL;
    params.accessRef = NULL;
    // These two values are for import
    params.keyUsage = NULL;
    params.keyAttributes = NULL;
    
    // Create and populate the key usage array
    CFMutableArrayRef keyUsage = (__bridge CFMutableArrayRef)[NSMutableArray arrayWithObjects:kSecAttrCanEncrypt, kSecAttrCanDecrypt, nil];
    
    // Create and populate the key attributes array
    CFMutableArrayRef keyAttributes = (__bridge CFMutableArrayRef)[NSMutableArray array];
    
    // Set the keyUsage and keyAttributes in the params object
    params.keyUsage = keyUsage;
    params.keyAttributes = keyAttributes;
    
    // Set the external format and flag values appropriately
    SecExternalFormat externalFormat = kSecFormatPEMSequence; // We store keys in PEM format
    int flags = 0;
    
    // Export the CFData Key
    CFDataRef keyData = NULL;
    CFShow(keyRef);
    OSStatus oserr = SecItemExport(keyRef, externalFormat, flags, &params, &keyData);
    if (oserr)
    {
        NSLog(@"SecItemExport failed (oserr= %ld)\n", (unsigned long)oserr);
    }
    
    NSData *data2 = (__bridge_transfer NSData *)keyData;
    
    NSString* keyString = [[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding];
    NSLog(@"Exported Key Data: %@", keyString);
    return data2;
}

-(SecKeyRef)refFromData:(NSData *)data isPublicKey:(BOOL)isPublicKey
{
    // Create and populate the parameters object with a basic set of values
    SecItemImportExportKeyParameters params;
    params.keyUsage = NULL;
    params.keyAttributes = NULL;
    
    //Set the item type, external format, and flag values appropriately.
    SecExternalItemType itemType;
    if (isPublicKey)
        itemType = kSecItemTypePublicKey;
    else
        itemType = kSecItemTypePrivateKey;
    
    SecExternalFormat externalFormat = kSecFormatPEMSequence;
    int flags = 0;
    
    //Import the key.
    CFArrayRef temparray;
    OSStatus oserr = SecItemImport((__bridge CFDataRef)data,
                                   NULL,                    // filename or extension
                                   &externalFormat,         // We use PEM for storage
                                   &itemType,               // key, public or private
                                   flags,
                                   &params,
                                   NULL,                    // Don't import into a keychain
                                   &temparray);
    if (oserr)
    {
        fprintf(stderr, "SecItemImport failed (oserr=%ld)\n", (unsigned long)oserr);
        CFShow(temparray);
        return NULL;
    }
    
    SecKeyRef key = (SecKeyRef)CFArrayGetValueAtIndex(temparray, 0);
    return key;
}
#endif

+ (NSData *)randomDataOfLength:(size_t)length
{
#if defined(__APPLE__)
    NSMutableData *data = [NSMutableData dataWithLength:length];
    int result = SecRandomCopyBytes(kSecRandomDefault,
                                    length,
                                    (unsigned char *)[data bytes]);
    int eno = errno;
    UMAssert((result == 0), @"Unable to generate random bytes: %d",
             eno);
    return data;
#else
    
#if HAS_OPENSSL
    return [self SSLRandomDataOfLength:length];
#else
    NSMutableData *data = [NSMutableData dataWithLength:length];
    int i;
    for(i=0;i<length;i++)
    {
        uint8_t randomByte = random() % 8;
        [data replaceBytesInRange:NSMakeRange(i,1) withBytes:&randomByte];
    }
    return data;
#endif
#endif
}

#pragma mark -
#pragma mark DES

#ifdef HAS_OPENSSL
- (UMCrypto *)initDESInitWithSaltAndIV
{
    unsigned char *iv_string = malloc(DES_BLOCK_SIZE);
    self = [super init];
    if (self)
    {
        salt = malloc(DES_SALT_LEN);
        RAND_seed(salt, DES_SALT_LEN);
        RAND_seed(iv_string, DES_BLOCK_SIZE);
        iv = [[NSData alloc] initWithBytes:iv_string length:DES_BLOCK_SIZE];
    }
    
    free(iv_string);
    return self;
}

- (UMCrypto *)initDESInitWithKeyWithEntropySource:(NSString *)file withGrade:(int)grade;
{
    char *entropy;
    //int n;
    DES_cblock block;
    unsigned char DESKey[DES_KEY_LEN];
    int i, nrounds = 1000/grade;
    unsigned char DESIV[DES_BLOCK_SIZE];
    unsigned char *DESSalt;
    
#define RANDOM_SIZE 8
    
    self = [super init];
    if (self)
    {
        /* Seeding */
        entropy = (char *)[file UTF8String];
        /*n = */RAND_load_file(entropy, 4 * DES_KEY_LEN);
        
        /* Generating */
        DESSalt = malloc(DES_SALT_LEN);
        RAND_seed(DESSalt, DES_SALT_LEN);
        int result = RAND_bytes(DESSalt, DES_SALT_LEN);
        /* OpenSSL reports a failure, act accordingly */
        UMAssert((result != 0), @"Unable to generate random bytes: %d",
                 errno);
 
        DES_random_key(&block);
        i = EVP_BytesToKey(EVP_des_cbc(), EVP_sha1(), DESSalt, block, RANDOM_SIZE, nrounds, DESKey, DESIV);
        if (i != 8)
        { //bytes !!!
            NSLog(@"Key size is %d bits - should be 56 bits\n", i);
            return nil;
        }
        
        deskey = [[NSData alloc] initWithBytes:DESKey length:DES_KEY_LEN];
    }
	return self;
}

+ (NSData *)SSLRandomDataOfLength:(size_t)length
{
    NSData *data;
    
   int result = RAND_bytes(salt, DES_SALT_LEN);
    /* OpenSSL reports a failure, act accordingly */
    UMAssert(result != 0, @"Unable to generate random bytes: %d",
             errno);

    data = [NSData dataWithBytes:salt length:length];
    
    return data;
}

- (UMCrypto *)initSSLPublicCryptoWithEntropySource:(NSString *)file
{
    RSA *rsa;
    char *pem_private_key;
    char *pem_public_key;
    int ret;
    int private_pem_len, public_pem_len;
    char *entropy;
    
    self = [super init];
    if(self)
    {
        SSL_library_init();
        SSL_load_error_strings();
        ERR_load_crypto_strings();
        OpenSSL_add_all_algorithms();
        BIO *bio = BIO_new(BIO_s_mem());
        pem_private_key = malloc(RSA_KEY_LEN);
        pem_public_key = malloc(RSA_KEY_LEN);
        
        /* Seeding */
        entropy = (char *)[file UTF8String];
        /*n = */RAND_load_file(entropy, 4 * RSA_KEY_LEN);
        
        /* Generating */
        rsa = RSA_generate_key(RSA_KEY_LEN, RSA_F4, NULL, NULL);
        if (RSA_check_key(rsa) != 1)
        {
            free(pem_private_key);
            free(pem_public_key);
            return nil;
        }
        
        /* To get the C-string PEM form: */
        ret = PEM_write_bio_RSAPrivateKey(bio, rsa, NULL, NULL, 0, NULL, NULL);
        if (ret == 0)
        {
            free(pem_private_key);
            free(pem_public_key);
            return nil;
        }
        
        private_keylen = RSA_KEY_LEN/2;
        private_pem_len = BIO_pending(bio);
        BIO_read(bio, pem_private_key, private_pem_len); /* Key stored in PEM format */
        privateKey = [[NSData alloc] initWithBytes:pem_private_key length:private_pem_len];
        NSString *privateString = [[NSString alloc] initWithData:privateKey encoding:NSUTF8StringEncoding];
        NSLog(@"we have PEM privateKey \n <%@>, length %d", privateString, (int)[privateKey length]);
        
        ret = PEM_write_bio_RSA_PUBKEY(bio, rsa);
        if (ret == 0)
        {
            free(pem_private_key);
            free(pem_public_key);
            return nil;
        }
        
        public_keylen = RSA_size(rsa);;
        public_pem_len = BIO_pending(bio);
        BIO_read(bio, pem_public_key, public_pem_len);   /* Ditto */
        publicKey = [[NSData alloc] initWithBytes:pem_public_key length:public_pem_len];
        NSString *publicString = [[NSString alloc] initWithData:publicKey encoding:NSUTF8StringEncoding];
        NSLog(@"we have PEM publicKey \n <%@>", publicString);
        
        BIO_free_all(bio);
        RSA_free(rsa);
        free(pem_private_key);
        free(pem_public_key);
    }
    return self;
}
#endif
                                   
#ifdef HAS_COMMON_CRYPTO
/* Grade is a number between 1 and 20. 1 means highest security and slowest execution*/
- (NSData *)DES3KeyForPassword:(NSData *)password withGrade:(int)grade
{
    const NSUInteger kAlgorithmKeySize = kCCKeySize3DES;
    NSMutableData *derivedKey = [NSMutableData dataWithLength:kAlgorithmKeySize];
    NSUInteger kPBKDFRounds;
    NSData *saltData;
    
    if (grade < 1)
        grade = 1;
    
    if (grade > 20)
        grade = 20;
    
    kPBKDFRounds = 1000/grade;
    
    saltData = [self randomDataOfLength:DES3_SALT_LEN];
    salt = (unsigned char *)[saltData bytes];
    int result = CCKeyDerivationPBKDF(kCCPBKDF2,            // algorithm
                                      (char *)[password bytes], // password
                                      [password length],        // passwordLength
                                      salt,                     // salt
                                      DES3_SALT_LEN,             // saltLen
                                      kCCPRFHmacAlgSHA1,        //The Pseudo Random Algorithm to use for the derivation iterations.
                                      (unsigned int)kPBKDFRounds, // rounds
                                      (unsigned char *)[derivedKey bytes], // derivedKey
                                      [derivedKey length]);     // derivedKeyLen
    
    // Do not log password here
    UMAssert(result == kCCSuccess, @"Unable to create triple DES key for password: %d", result);
    
    return derivedKey;
}

- (NSData *)RSAEncryptWithPlaintextPublic:(NSData *)plaintext
{
    SecKeyRef public;
    
    if (!publicKey)
    {
        return nil;
    }
    __block SecGroupTransformRef group = SecTransformCreateGroupTransform();
    __block CFReadStreamRef readStream = NULL;
    __block SecTransformRef readTransform = NULL;
    __block SecTransformRef encryptTransform = NULL;
    NSData *ciphertext = nil;
    
   /* void (^cleanupBlock) () =
    ^{
        if (group)
        {
            CFRelease(group);
            group = NULL;
        }
        
        if (readStream)
        {
            CFRelease(readStream);
            readStream = NULL;
        }
        
        if (readTransform)
        {
            CFRelease(readTransform);
            readTransform = NULL;
        }
        
        if (encryptTransform)
        {
            CFRelease(encryptTransform);
            encryptTransform = NULL;
        }
    };*/
    
    readStream = CFReadStreamCreateWithBytesNoCopy(kCFAllocatorDefault,
                                                   [plaintext bytes],
                                                   [plaintext length],
                                                   kCFAllocatorNull);
    
    readTransform = SecTransformCreateReadTransformWithReadStream(readStream);
    CFRelease(readStream);
    if (!readTransform)
    {
        //cleanupBlock();
        CFRelease(group);
        return nil;
    }
    
    public = [self refFromData:publicKey isPublicKey:YES];
    encryptTransform = SecEncryptTransformCreate(public, NULL);
    
    if (!encryptTransform)
    {
        CFRelease(readTransform);
        CFRelease(group);
        //cleanupBlock();
        return nil;
    }
    
    // Configure and then run group
    SecTransformConnectTransforms(readTransform, kSecTransformOutputAttributeName,
                                  encryptTransform, kSecTransformInputAttributeName,
                                  group, NULL);
    
    // Execute group

    ciphertext = (__bridge_transfer NSData *)SecTransformExecute(group, NULL);
    
    //cleanupBlock();
    CFRelease(readTransform);
    CFRelease(encryptTransform);
    CFRelease(group);
    
    return ciphertext;
}

- (NSData *)RSADecryptWithCiphertextPrivate:(NSData *)ciphertext
{
    SecKeyRef private;
    
    if (!privateKey)
        return nil;
    
    __block SecGroupTransformRef group = SecTransformCreateGroupTransform();
    __block CFReadStreamRef readStream = NULL;
    __block SecTransformRef readTransform = NULL;
    __block SecTransformRef decryptTransform = NULL;
    NSData *plaintext = nil;
    
   /* void (^cleanupBlock) () =
    ^{
        if (group)
        {
            CFRelease(group);
            group = NULL;
        }
        
        if (readStream)
        {
            CFRelease(readStream);
            readStream = NULL;
        }
        
        if (readTransform)
        {
            CFRelease(readTransform);
            readTransform = NULL;
        }
        
        if (decryptTransform)
        {
            CFRelease(decryptTransform);
            decryptTransform = NULL;
        }
    };*/
    
    readStream = CFReadStreamCreateWithBytesNoCopy(kCFAllocatorDefault,
                                                   [ciphertext bytes],
                                                   [ciphertext length],
                                                   kCFAllocatorNull);
    
    readTransform = SecTransformCreateReadTransformWithReadStream(readStream);
    CFRelease(readStream);
    if (!readTransform)
    {
        //cleanupBlock();
        CFRelease(group);
        return nil;
    }
    
    private = [self refFromData:privateKey isPublicKey:NO];
    decryptTransform = SecDecryptTransformCreate(private, NULL);
    
    if (!decryptTransform)
    {
        CFRelease(group);
        CFRelease(readTransform);
        //cleanupBlock();
        return nil;
    }
    
    // Configure and then run group
    SecTransformConnectTransforms(readTransform, kSecTransformOutputAttributeName,
                                  decryptTransform, kSecTransformInputAttributeName,
                                  group, NULL);
    
    // Execute group
    CFErrorRef error = NULL;
    plaintext = CFBridgingRelease(SecTransformExecute(group, &error));
    
    if (error)
    {
        NSLog(@"%@", (__bridge NSError *)error);
        CFRelease(error);
        error = NULL;
    }
    
    //cleanupBlock();
    CFRelease(group);
    CFRelease(readTransform);
    CFRelease(decryptTransform);
    
    return plaintext;
}
#endif

#ifdef   HAS_OPENSSL
- (NSData *)RSAEncryptWithPlaintextSSLPublic:(NSData *)plaintext
{
    int cipherlen;
    unsigned char *pt;
    unsigned char *ct;
    RSA *rsa;
    int len;
    
    len = (int)[plaintext length];
    if (len > public_keylen - RSA_PADDING_LEN)
        return nil;
    
    rsa = RSA_new();
    BIO *bio = BIO_new(BIO_s_mem());
    BIO_write(bio, (unsigned char *)[publicKey bytes], (int)[publicKey length]);
    PEM_read_bio_RSA_PUBKEY(bio, &rsa, NULL, NULL);
    if (!rsa)
        return nil;
    
    pt = (unsigned char *)[plaintext bytes];
    ct = OPENSSL_malloc(RSA_size(rsa));
    cipherlen = RSA_public_encrypt(len, pt, ct, rsa, RSA_PKCS1_OAEP_PADDING);
    if (cipherlen == -1)
    {
        char *err_string = malloc(120);
        ERR_error_string(ERR_get_error(), err_string);
        NSLog(@"encryption returned %s, key length %d", err_string, RSA_size(rsa));
        free(err_string);
        return nil;
    }
    
    NSData *ciphertext = [NSData dataWithBytes:ct length:cipherlen];
    
    BIO_free_all(bio);
    RSA_free(rsa);
    free(ct);
    
    return ciphertext;
}

- (NSData *)RSAEncryptWithPlaintextSSLPrivate:(NSData *)plaintext
{
    int cipherlen;
    unsigned char *pt;
    unsigned char *ct;
    RSA *rsa;
    int len;
    
    len = (int)[plaintext length];
    if (len > private_keylen - RSA_PADDING_LEN)
        return nil;
    
    rsa = RSA_new();
    BIO *bio = BIO_new(BIO_s_mem());
    BIO_write(bio, (unsigned char *)[privateKey bytes], (int)[privateKey length]);
    PEM_read_bio_RSAPrivateKey(bio, &rsa, NULL, NULL);
    if (!rsa)
        return nil;
    
    pt = (unsigned char *)[plaintext bytes];
    ct = OPENSSL_malloc(RSA_KEY_LEN/2);
    cipherlen = RSA_private_encrypt(len, pt, ct, rsa, RSA_PKCS1_PADDING);
    if (cipherlen == -1)
    {
        char *err_string = malloc(120);
        ERR_error_string(ERR_get_error(), err_string);
        NSLog(@"encryption returned %s, key length %d", err_string, RSA_KEY_LEN/2);
        free(err_string);
        return nil;
    }
    
    NSData *ciphertext = [NSData dataWithBytes:ct length:cipherlen];
    
    BIO_free_all(bio);
    RSA_free(rsa);
    free(ct);
    
    return ciphertext;
}

- (NSData *)RSADecryptWithCiphertextSSLPrivate:(NSData *)ciphertext
{
    int plainlen;
    unsigned char *pt;
    unsigned char *ct;
    RSA *rsa;
    
    rsa = RSA_new();
    BIO *bio = BIO_new(BIO_s_mem());
    BIO_write(bio, (unsigned char *)[privateKey bytes], (int)[privateKey length]);
    PEM_read_bio_RSAPrivateKey(bio, &rsa, NULL, NULL);
    if (!rsa)
        return nil;
    
    ct = (unsigned char *)[ciphertext bytes];
    pt = OPENSSL_malloc(RSA_KEY_LEN);
    plainlen = RSA_private_decrypt((int)[ciphertext length], ct, pt, rsa, RSA_PKCS1_OAEP_PADDING);
    if (plainlen == -1)
        return nil;
    
    NSData *cipher= [NSData dataWithBytes:pt length:plainlen];
    
    BIO_free_all(bio);
    RSA_free(rsa);
    
    return cipher;
}

- (NSData *)RSADecryptWithCiphertextSSLPublic:(NSData *)ciphertext
{
    int plainlen;
    unsigned char *pt;
    unsigned char *ct;
    RSA *rsa;
    
    rsa = RSA_new();
    BIO *bio = BIO_new(BIO_s_mem());
    BIO_write(bio, (unsigned char *)[publicKey bytes], (int)[publicKey length]);
    PEM_read_bio_RSA_PUBKEY(bio, &rsa, NULL, NULL);
    if (!rsa)
        return nil;
    
    ct = (unsigned char *)[ciphertext bytes];
    pt = OPENSSL_malloc(RSA_KEY_LEN);
    plainlen = RSA_public_decrypt((int)[ciphertext length], ct, pt, rsa, RSA_PKCS1_PADDING);
    if (plainlen == -1)
        return nil;
    
    NSData *cipher= [NSData dataWithBytes:pt length:plainlen];
    
    BIO_free_all(bio);
    RSA_free(rsa);
    
    return cipher;
}
#endif
                                   
#ifdef HAS_COMMON_CRYPTO
- (NSData *)encryptData:(NSData *)data withPassword:(NSData *)password withKey:(NSData **)key withGrade:(int)grade
{
    CCCryptorStatus ccStatus;
    CCOptions options = 0; //kCCOptionPKCS7Padding;
    const NSUInteger kAlgorithmIVSize = kCCBlockSize3DES * 8; /* in bytes*/
    
    iv = [self randomDataOfLength:kAlgorithmIVSize];
    *key = [self DES3KeyForPassword:password withGrade:grade];
    
    size_t output_size  = (([data length]*4+1023) / 1024) * 1024;
    void *output_ptr    =  malloc(output_size);
    memset(output_ptr,0x00,output_size);

    size_t input_size   = (([data length]+1023) / 1024) * 1024;
    void *input_ptr     =  malloc(input_size);
    memset(input_ptr,0x00,input_size);
    memcpy(input_ptr,[data bytes],[data length]);
    
    /* we pad to the next 1k with zero's */
    size_t new_output_size = 0;
    
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithm3DES,
                       options,
                       [*key bytes],
                       kCCKeySize3DES,
                       [iv bytes],
                       input_ptr,
                       input_size,
                       output_ptr,          /* data RETURNED here */
                       output_size ,
                       &new_output_size);
    if(ccStatus !=0)
    {
        free(input_ptr);
        free(output_ptr);
        NSLog(@"Encrypt fails with Error: %d %s",ccStatus,[self cryptErrorString:ccStatus]);
        return nil;
    }
    NSData *result = [NSData dataWithBytes:output_ptr length:new_output_size];
    
    free(input_ptr);
    free(output_ptr);
    return result;
}
#endif

#ifdef HAS_COMMON_CRYPTO
- (NSData *)encryptData:(NSData *)data withPassword:(NSData *)password
{
    CCCryptorStatus ccStatus;
    CCOptions options = 0; //kCCOptionPKCS7Padding;
    const NSUInteger kAlgorithmIVSize = kCCBlockSize3DES * 8; /* in bytes*/
    
    size_t output_size = (([data length]*4+1023) / 1024) * 1024;
    void *output_ptr =  malloc(output_size);
    
    size_t input_size = (([data length]+1023) / 1024) * 1024;
    void *input_ptr =  malloc(input_size);
    memset(input_ptr,0x00,input_size);
    memcpy(input_ptr,[data bytes],[data length]);
    
    /* we pad to the next 1k with zero's */
    size_t new_output_size = 0;
    
    if (!iv)
        iv = [self randomDataOfLength:kAlgorithmIVSize];
    
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithm3DES,
                       options,
                       [password bytes],
                       kCCKeySize3DES,
                       [iv bytes],
                       input_ptr,
                       input_size,
                       output_ptr,          /* data RETURNED here */
                       output_size ,
                       &new_output_size);
    if(ccStatus !=0)
    {
        free(input_ptr);
        free(output_ptr);
        NSLog(@"Encrypt fails with Error: %d %s",ccStatus,[self cryptErrorString:ccStatus]);
        return nil;
    }
    NSData *result = [NSData dataWithBytes:output_ptr length:new_output_size];
    
    free(input_ptr);
    free(output_ptr);
    return result;
}

- (NSData *)decryptData:(NSData *)data withPassword:(NSData *)key
{
    
    CCCryptorStatus ccStatus;
    CCOptions options = 0; //kCCOptionPKCS7Padding;
    
    size_t input_size = (([data length]+1023) / 1024) * 1024;
    void *input_ptr =  malloc(input_size);
    memset(input_ptr,0x00,input_size);
    memcpy(input_ptr,[data bytes],[data length]);
    
    size_t output_size = (([data length]+1023) / 1024) * 1024;
    void *output_ptr =  malloc(output_size);
    size_t new_output_size = 0;
    ccStatus = CCCrypt(kCCDecrypt,
                       kCCAlgorithm3DES,
                       options,
                       [key bytes],
                       [key length],
                       [iv bytes],
                       input_ptr,
                       input_size,
                       output_ptr,          /* data RETURNED here */
                       output_size ,
                       &new_output_size);
    
    if(ccStatus !=0)
        ccStatus = CCCrypt(kCCDecrypt,
                           kCCAlgorithmRC4,
                           options,
                           [key bytes],
                           [key length],
                           [iv bytes],
                           [data bytes],
                           [data length],
                           output_ptr,          /* data RETURNED here */
                           output_size ,
                           &new_output_size);
    if(ccStatus !=0)
        ccStatus = CCCrypt(kCCDecrypt,
                           kCCAlgorithmDES,
                           options,
                           [key bytes],
                           [key length],
                           [iv bytes],
                           [data bytes],
                           [data length],
                           output_ptr,          /* data RETURNED here */
                           output_size ,
                           &new_output_size);
    if(ccStatus !=0)
        ccStatus = CCCrypt(kCCDecrypt,
                           kCCAlgorithmCAST,
                           options,
                           [key bytes],
                           [key length],
                           [iv bytes],
                           [data bytes],
                           [data length],
                           output_ptr,          /* data RETURNED here */
                           output_size ,
                           &new_output_size);
    
    if(ccStatus !=0)
        ccStatus = CCCrypt(kCCDecrypt,
                           kCCAlgorithmAES128,
                           options,
                           [key bytes],
                           [key length],
                           [iv bytes],
                           [data bytes],
                           [data length],
                           output_ptr,          /* data RETURNED here */
                           output_size ,
                           &new_output_size);
    
    if(ccStatus !=0)
    {
        free(input_ptr);
        free(output_ptr);
        return nil;
    }
    NSData *result = [NSData dataWithBytes:output_ptr length:new_output_size];
    
    free(input_ptr);
    free(output_ptr);
    return result;
}
#endif

#ifdef HAS_OPENSSL


/**
 * Encrypt *len bytes of data, with initalization vector and generated DESK key
 * All data going in out is considered binary (NSData)
 * Returns ciphertext, and DES key created from the password.
 * Grade is number between 1 and 20. 1 némans highest security but slowest excution.
 */
- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext havingLength:(int *)len withPassword:(NSData *)password withKey:(NSData **)key  withGrade:(int)grade
{
    /* max ciphertext len for a n bytes of plaintext is n + AES_BLOCK_SIZE -1 bytes */
    int cLen = *len + DES_BLOCK_SIZE, fLen = 0;
    unsigned char *ciphertext = malloc(cLen);
    EVP_CIPHER_CTX e;
    
    if (grade < 1)
        grade = 1;
    
    if (grade > 20)
        grade = 20;
    
    int i, nrounds = 1000/grade;
    unsigned char DESKey[DES_KEY_LEN];
    unsigned char DESIV[DES_BLOCK_SIZE];
    
    salt = (unsigned char *)[[self SSLRandomDataOfLength:DES_SALT_LEN] bytes];
    /*
     * Gen key and IV for DES CBC mode. A SHA1 digest is used to hash the supplied key material.
     * nrounds is the number of times the we hash the material. More rounds are more secure but
     * slower.
     */
    i = EVP_BytesToKey(EVP_des_cbc(), EVP_sha1(), salt, (unsigned char *)[password bytes], (int)[password length], nrounds, DESKey, DESIV);
    if (i != 8)
    { //bytes !!!
        free(ciphertext);
        NSLog(@"Key size is %d bits - should be 56 bits\n", i);
        return nil;
    }
    
    EVP_CIPHER_CTX_init(&e);
    EVP_EncryptInit_ex(&e, EVP_des_cbc(), NULL, DESKey, DESIV);
    iv = [[NSData alloc] initWithBytes:DESIV length:DES_BLOCK_SIZE];
    
    /* update ciphertext, cLen is filled with the length of ciphertext generated,
     *len is the size of plaintext in bytes */
    EVP_EncryptUpdate(&e, ciphertext, &cLen, (unsigned char *)[plaintext bytes], *len);
    
    /* update ciphertext with the final remaining bytes */
    EVP_EncryptFinal_ex(&e, ciphertext+cLen, &fLen);
    
    *len = cLen + fLen;
    
    NSData *result = [NSData dataWithBytes:ciphertext length:*len];
    *key = [NSData dataWithBytes:DESKey length:DES_KEY_LEN];
    
    return result;
}

/**
 * Encrypt *len bytes of data, with with input password
 * All data going in out is considered binary (NSData)
 * Returns ciphertext.
 */
- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext havingLength:(int *)len withPassword:(NSData *)password
{
    /* max ciphertext len for a n bytes of plaintext is n + AES_BLOCK_SIZE -1 bytes */
    int cLen = *len + DES_BLOCK_SIZE, fLen = 0;
    unsigned char *ciphertext = malloc(cLen);
    EVP_CIPHER_CTX e;
    
    EVP_CIPHER_CTX_init(&e);
    EVP_EncryptInit_ex(&e, EVP_des_cbc(), NULL,  (unsigned char *)[password bytes], NULL);
    
    /* update ciphertext, cLen is filled with the length of ciphertext generated,
     *len is the size of plaintext in bytes */
    EVP_EncryptUpdate(&e, ciphertext, &cLen, (unsigned char *)[plaintext bytes], *len);
    
    /* update ciphertext with the final remaining bytes */
    EVP_EncryptFinal_ex(&e, ciphertext+cLen, &fLen);
    
    *len = cLen + fLen;
    
    NSData *result = [NSData dataWithBytes:ciphertext length:*len];
    return result;
}

#ifdef  HAS_OPENSSL
/**
 * Decrypt *len bytes of ciphertext, DES
 */
- (NSData *)DESDecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    /* because we have padding ON, we must allocate an extra cipher block size of memory */
    int pLen = *len, fLen = 0;
    unsigned char *plaintext = malloc(pLen + DES_BLOCK_SIZE);
    int ret;
    EVP_CIPHER_CTX e;
    
    EVP_CIPHER_CTX_init(&e);
    ret = EVP_DecryptInit_ex(&e, EVP_des_cbc(), NULL, (unsigned char *)[key bytes], (unsigned char *)[iv bytes]);
    if (ret == 0) {
        free(plaintext);
        return nil;
    }
    
    ret = EVP_DecryptUpdate(&e, plaintext, &pLen, (unsigned char *)[ciphertext bytes], *len);
    if (ret == 0) {
        free(plaintext);
        return nil;
    }
    
    ret = EVP_DecryptFinal_ex(&e, plaintext+pLen, &fLen);
    if (ret == 0)
        return nil;
    
    *len = pLen + fLen;
    NSData *result = [NSData dataWithBytes:plaintext length:*len];
    return result;
}
/**
 * Decrypt *len bytes of ciphertext, DES
 */
- (NSData *)RC4DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    int pLen = *len, fLen = 0;
    unsigned char *plaintext = malloc(pLen);
    int ret;
    EVP_CIPHER_CTX e;
    
    EVP_CIPHER_CTX_init(&e);
    EVP_DecryptInit_ex(&e, EVP_rc4(), NULL, (unsigned char *)[key bytes], (unsigned char *)[iv bytes]);
    
    ret = EVP_DecryptUpdate(&e, plaintext, &pLen, (unsigned char *)[ciphertext bytes], *len);
    if (ret == 0) {
        free(plaintext);
        return nil;
    }
    ret = EVP_DecryptFinal_ex(&e, plaintext+pLen, &fLen);
    if (ret == 0)
        return nil;
    
    *len = pLen + fLen;
    NSData *result = [NSData dataWithBytes:plaintext length:*len];
    return result;
}
#endif
                                   
/**
 * Decrypt *len bytes of ciphertext, 3DES
 */
- (NSData *)DES3DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    /* because we have padding ON, we must allocate an extra cipher block size of memory */
    int pLen = *len, fLen = 0;
    unsigned char *plaintext = malloc(pLen + DES3_BLOCK_SIZE);
    int ret;
    EVP_CIPHER_CTX e;
    
    EVP_CIPHER_CTX_init(&e);
    ret = EVP_DecryptInit_ex(&e, EVP_des_ede3_cbc(), NULL, (unsigned char *)[key bytes], (unsigned char *)[iv bytes]);
    if (ret == 0) {
        free(plaintext);
        return nil;
    }
    
    ret = EVP_DecryptUpdate(&e, plaintext, &pLen, (unsigned char *)[ciphertext bytes], *len);
    if (ret == 0) {
        free(plaintext);
        return nil;
    }
    
    ret = EVP_DecryptFinal_ex(&e, plaintext+pLen, &fLen);
    if (ret == 0)
        return nil;
    
    *len = pLen + fLen;
    NSData *result = [NSData dataWithBytes:plaintext length:*len];
    return result;
}

                                   
/**
 * Decrypt *len bytes of ciphertext, CSAT3
 */
- (NSData *)CAST5DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key
{
    /* because we have padding ON, we must allocate an extra cipher block size of memory */
    int pLen = *len, fLen = 0;
    unsigned char *plaintext = malloc(pLen + CAST5_BLOCK_SIZE);
    int ret;
    EVP_CIPHER_CTX e;
    
    EVP_CIPHER_CTX_init(&e);
    ret = EVP_DecryptInit_ex(&e, EVP_cast5_cbc(), NULL, (unsigned char *)[key bytes], (unsigned char *)[iv bytes]);
    if (ret == 0) {
        free(plaintext);
        return nil;
    }
    
    ret = EVP_DecryptUpdate(&e, plaintext, &pLen, (unsigned char *)[ciphertext bytes], *len);
    if (ret == 0) {
        free(plaintext);
        return nil;
    }
    
    ret = EVP_DecryptFinal_ex(&e, plaintext+pLen, &fLen);
    if (ret == 0)
        return nil;
    
    *len = pLen + fLen;
    NSData *result = [NSData dataWithBytes:plaintext length:*len];
    return result;
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
#endif
                                   
- (UMCrypto *) copyWithZone:(NSZone *)zone
{
    UMCrypto *no = [[UMCrypto alloc]init];
    no.enable = enable;
    no.pos = 0;
    no.method = method;
    no.vectorSize = vectorSize;
    no.deskey = deskey;
    no.cryptorKey = cryptorKey;
    no.salt = salt;
    no.iv = iv;
    no.publicKey = publicKey;
    no.privateKey = privateKey;
    no->_fileDescriptor = _fileDescriptor;
    no.relatedSocket = relatedSocket;
    
//    no.public_keylen = public_keylen;
//    no.private_keylen = private_keylen;
//    no.private_keylen = private_keylen;
 //   no.peer_certificate = peer_certificate;
 //   no.local_certificate = local_certificate;

    return no;
}


+(NSDictionary *)generateRsaKeyPair
{
    return [UMCrypto generateRsaKeyPair:4096 pub:65537];
}

+(NSDictionary *)generateRsaKeyPair:(int)keyLength pub:(unsigned long)pubInt
{
    NSMutableDictionary *dict = NULL;

    int             ret = 0;
    RSA             *r = NULL;
    BIGNUM          *bne = NULL;
    BIO             *bp_public = NULL;
    BIO             *bp_private = NULL;

    int             bits = keyLength;
    unsigned long   e = pubInt; //RSA_F4;

    while(RAND_status() == 0)
    {
        NSData *d = [UMCrypto randomDataOfLength:256];
        RAND_add(d.bytes, (int)d.length, 3.1415926);
    }

    // 1. generate rsa key
    bne = BN_new();
    ret = BN_set_word(bne,e);
    if(ret == 1)
    {
        r = RSA_new();
        ret = RSA_generate_key_ex(r, bits, bne, NULL);

        // 2. save public key
        bp_public = BIO_new(BIO_s_secmem());
        ret = PEM_write_bio_RSAPublicKey(bp_public, r);
        if(ret == 1)
        {

            // 3. save private key
            bp_private = BIO_new(BIO_s_secmem());
            ret = PEM_write_bio_RSAPrivateKey(bp_private, r, NULL, NULL, 0, NULL, NULL);
            if(ret==1)
            {
                size_t pri_len = BIO_pending(bp_private);
                size_t pub_len = BIO_pending(bp_public);
                char *pri_key = malloc(pri_len + 1);
                char *pub_key = malloc(pub_len + 1);
                BIO_read(bp_private, pri_key,(int)pri_len);
                BIO_read(bp_public, pub_key,(int)pub_len);
                pri_key[pri_len] = '\0';
                pub_key[pub_len] = '\0';
                dict = [[NSMutableDictionary alloc]init];
                dict[@"private-key"] = @(pri_key);
                dict[@"public-key"] = @(pub_key);
                memset(pri_key,0x00,pri_len);
                memset(pub_key,0x00,pub_len);
                free(pri_key);
                free(pub_key);
            }
        }
    }
    if(bp_public)
    {
        BIO_free_all(bp_public);
        bp_public = NULL;
    }
    if(bp_private)
    {
        BIO_free_all(bp_private);
        bp_private = NULL;
    }
    if(r)
    {
        RSA_free(r);
        r = NULL;
    }
    if(bne)
    {
        BN_free(bne);
        bne=NULL;
    }
    return dict;
}

@end
