//
//  UMCrypto.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include "ulib_config.h"

#import "UMObject.h"

#define DES_BLOCK_SIZE 64
#define DES_SALT_LEN 56
#define DES_KEY_LEN 56

#define DES3_BLOCK_SIZE 64
#define DES3_KEY_LEN 168
#define DES3_SALT_LEN 56

#define CAST5_BLOCK_SIZE 64

#define RSA_KEY_LEN 4096
#define RSA_EXPONENT 65537
#define RSA_PADDING_LEN 41

/* note: under OS X we use a framework packaged openssl1.0.x, not the OS installed old 0.9 version of SSL which is there for backwards compatibility. Due to name conflict of the headerfiles, the frameworks version of openssl has its header files in openssl1 instead.
 
    if this framework version is used, then HAVE_OPENSSL_AS_FRAMEWORK is defined. This is checked in ./configure and sets ulib_config.h accordingly
 */



@class UMSocket;

@interface UMCrypto : UMObject
{
	NSInteger	        enable;
	NSInteger	        pos;
	NSInteger	        method;
	NSInteger	        vectorSize;
    NSData              *deskey;              /* For symmetric cryptography*/
    NSData              *cryptorKey;
    unsigned char       *salt;
    NSData              *iv;
    NSData              *publicKey;           /* For unsymmetric cryptography, having PEM format*/
    NSData              *privateKey;          /* Ditto */
    int                 public_keylen;
    int                 private_keylen;
    NSData              *cryptorPublicKey;
    NSData              *cryptorPrivateKey;
    int                 _fileDescriptor;
    UMSocket __weak     *relatedSocket;
}

@property(readwrite,assign)		NSInteger	  enable;
@property(readwrite,assign)		NSInteger	  pos;
@property(readwrite,assign)		NSInteger	  method;
@property(readwrite,assign)		NSInteger	  vectorSize;
@property(readwrite,assign)		unsigned char *salt;
@property(readwrite,strong)		NSData        *iv;
@property(readwrite,strong)		NSData        *publicKey;
@property(readwrite,strong)		NSData        *privateKey;
@property(readwrite,strong)		NSData        *deskey;
@property(readwrite,strong)		NSData        *cryptorKey;
@property(readwrite,assign)     int           fileDescriptor;
@property(readwrite,weak)       UMSocket      *relatedSocket;



#pragma mark -
#pragma mark Initialisation
- (UMCrypto *)initWithKey;
- (void)enableCrypto;
- (void)disableCrypto;



#pragma mark -
#pragma mark Generic Read/Write IO

- (ssize_t)readBytes:(unsigned char *)bytes
             length:(size_t)length
          errorCode:(int *)eno;

- (ssize_t)writeByte:(unsigned char)byte
          errorCode:(int *)eno;

- (ssize_t)writeBytes:(const unsigned char *)bytes
              length:(size_t)length
           errorCode:(int *)eno;


#pragma mark -
#pragma mark Encryption


#ifdef HAS_COMMON_CRYPTO
- (UMCrypto *)initPublicCrypto;
#endif


- (UMCrypto *)initWithFileDescriptor:(int)fileDescriptor;
- (UMCrypto *)initWithRelatedSocket:(UMSocket *)s;

- (void)setSeed:(NSInteger)seed;

#ifdef HAS_COMMON_CRYPTO
- (const char *)cryptErrorString:(int)code;
#endif

#pragma mark -
#pragma mark Keychain Utilities
#ifdef HAS_KEYCHAIN_UTILITIES
- (NSData *)dataFromRef:(SecKeyRef)keyRef;
- (SecKeyRef)refFromData:(NSData *)data isPublicKey:(BOOL)isPublic;
#endif

#pragma mark -
#pragma mark DES

- (NSData *)randomDataOfLength:(size_t)length;

#if (HAS_OPENSSL || HAS_OPENSSL1)
- (NSData *)SSLRandomDataOfLength:(size_t)length;
- (UMCrypto *)initDESInitWithSaltAndIV;
- (UMCrypto *)initDESInitWithKeyWithEntropySource:(NSString *)file withGrade:(int)grade;
- (UMCrypto *)initSSLPublicCryptoWithEntropySource:(NSString *)file;
#endif

#ifdef HAS_COMMON_CRYPTO
- (NSData *)DES3KeyForPassword:(NSData *)password withGrade:(int)grade;
- (NSData *)RSAEncryptWithPlaintextPublic:(NSData *)plaintext;
- (NSData *)RSADecryptWithCiphertextPrivate:(NSData *)ciphertext;
- (NSData *)encryptData:(NSData *)data withPassword:(NSData *)password withKey:(NSData **)key withGrade:(int)grade;
- (NSData *)encryptData:(NSData *)data withPassword:(NSData *)password;
- (NSData *)decryptData:(NSData *)data withPassword:(NSData *)key;
#endif


#if (HAS_OPENSSL || HAS_OPENSSL1)
- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext havingLength:(int *)len withPassword:(NSData *)password withKey:(NSData **)key withGrade:(int)grade;
- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext havingLength:(int *)len withPassword:(NSData *)password;
- (NSData *)DESDecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;

- (NSData *)RSAEncryptWithPlaintextSSLPublic:(NSData *)plaintext;
- (NSData *)RSADecryptWithCiphertextSSLPrivate:(NSData *)ciphertext;
- (NSData *)RSAEncryptWithPlaintextSSLPrivate:(NSData *)plaintext;
- (NSData *)RSADecryptWithCiphertextSSLPublic:(NSData *)ciphertext;
- (NSData *)RC4DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;
- (NSData *)DES3DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;
- (NSData *)CAST5DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;
- (NSData *)decryptDataWithSSL:(NSData *)data withKey:(NSData *)key;
#endif

@end
