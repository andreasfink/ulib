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


@class UMSocket;

@interface UMCrypto : UMObject
{
	NSInteger	        _enable;
	NSInteger	        _pos;
	NSInteger	        _method;
	NSInteger	        _vectorSize;
    NSData              *_deskey;              /* For symmetric cryptography*/
    NSData              *_cryptorKey;
    NSData              *_saltData;
    NSData              *_iv;
    NSString            *_publicKey;           /* For unsymmetric cryptography, having PEM format*/
    NSString            *_privateKey;          /* Ditto */
    int                 _public_keylen;
    int                 _private_keylen;
    NSData              *_cryptorPublicKey;
    NSData              *_cryptorPrivateKey;
    NSData              *_aes256Key;
    int                 _fileDescriptor;
    UMSocket __weak     *_relatedSocket;
}

@property(readwrite,assign)		NSInteger	  enable;
@property(readwrite,assign)		NSInteger	  pos;
@property(readwrite,assign)		NSInteger	  method;
@property(readwrite,assign)		NSInteger	  vectorSize;
@property(readwrite,strong)		NSData        *saltData;
@property(readwrite,strong)		NSData        *iv;
@property(readwrite,strong)		NSString      *publicKey;
@property(readwrite,strong)		NSString      *privateKey;

@property(readwrite,strong)		NSData        *deskey;
@property(readwrite,strong)     NSData        *cryptorKey;
@property(readwrite,strong)     NSData        *aes256Key;
@property(readwrite,assign)     int           fileDescriptor;
@property(readwrite,weak)       UMSocket      *relatedSocket;



#pragma mark -
#pragma mark Initialisation
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

- (UMCrypto *)initWithFileDescriptor:(int)fileDescriptor;
- (UMCrypto *)initWithRelatedSocket:(UMSocket *)s;
- (UMCrypto *)initPublicCrypto;

- (void)setSeed:(NSInteger)seed;


#pragma mark -
#pragma mark DES

+ (NSData *)randomDataOfLength:(size_t)length;

+ (NSData *)SSLRandomDataOfLength:(size_t)length;
- (UMCrypto *)initDESInitWithSaltAndIV;
- (UMCrypto *)initDESInitWithKeyWithEntropySource:(NSString *)file withGrade:(int)grade;

- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext havingLength:(int *)len withPassword:(NSData *)password withKey:(NSData **)key withGrade:(int)grade;
- (NSData *)DESEncryptWithPlaintext:(NSData *)plaintext havingLength:(int *)len withPassword:(NSData *)password;
- (NSData *)DESDecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;

- (NSData *)RSAEncryptWithPlaintextSSLPublic:(NSData *)plaintext;
- (NSData *)RSADecryptWithCiphertextSSLPrivate:(NSData *)ciphertext;

- (NSData *)RC4DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;
- (NSData *)DES3DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;
- (NSData *)CAST5DecryptWithCiphertext:(NSData *)ciphertext havingLength:(int *)len withKey:(NSData *)key;
- (NSData *)decryptDataWithSSL:(NSData *)data withKey:(NSData *)key;

- (void)generateRsaKeyPair;
- (void)generateRsaKeyPair:(int)keyLength pub:(unsigned long)pubInt;


- (NSData *)aes256RandomKey;
- (NSData *)aes256RandomIV;
- (void)logOpenSSLErrorsForSection:(NSString *)section;
- (NSData *)aes256Encrypt:(NSData *)plaintext;
- (NSData *)aes256Decrypt:(NSData *)ciphertext;
- (NSData *)aes256Encrypt:(NSData *)plaintext key:(NSData *)key;
- (NSData *)aes256Decrypt:(NSData *)plaintext key:(NSData *)key;
- (NSData *)aes256Encrypt:(NSData *)plaintext key:(NSData *)key iv:(NSData *)iv;
- (NSData *)aes256Decrypt:(NSData *)plaintext key:(NSData *)key iv:(NSData *)iv;

@end
