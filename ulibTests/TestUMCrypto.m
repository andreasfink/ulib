//
//  TestUMCrypto.m
//  ulib
//
//  Created by Aarno Syvänen on 27.08.12.
//
//

#import "TestUMCrypto.h"

#include <stdio.h>

#import "UMCrypto.h"

#define DEBUG_DISPLAY_WIDTH_DEFAULT 24

@implementation TestUMCrypto

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

+ (void)displayMemHex:(NSData*) data withSize:(unsigned int)size withColumn:(unsigned char)outputWidth
{
    unsigned char act_column=0;
    unsigned char line_count=0;
    unsigned int  byte_pos=1;
    unsigned char *pData = (unsigned char *)[data bytes];
    
    while (size)
    {
        if (act_column == 0)
        {
			NSLog(@"%3u) ", byte_pos);
        }
        
        NSLog(@"%02x ", *pData);
        ++pData;
        --size;
        ++act_column;
        ++byte_pos;
		
        if (outputWidth != 0) {
			if (outputWidth <= DEBUG_DISPLAY_WIDTH_DEFAULT)
            {
				if (act_column==outputWidth)
					puts("\r");
			}
            
			else
            {
				if (act_column == outputWidth)
					puts("\r");
				else if ((act_column % DEBUG_DISPLAY_WIDTH_DEFAULT)==0)
					printf("\r\n     ");
			}
            
			if (act_column == outputWidth)
            {
				act_column=0;
				line_count++;
			}
		}
        
		else
        {
			if (act_column == DEBUG_DISPLAY_WIDTH_DEFAULT)
            {
				act_column = 0;
				puts("\r");
			}
		}
	}
	
    if (act_column != DEBUG_DISPLAY_WIDTH_DEFAULT)
        puts("\r");
}

#ifdef HAS_COMMON_CRYPTO
/* 
 * Encryption uses key generated from password, both iv and salt would be added. Decryption requires knowledge of IV used * when encrypting.
 * Decryption returs block sixed data, only first bytes are pertinent.
 */
- (void)testCryptorCrypto
{
    long j;
    NSData *ciphertext, *plaintext1, *plaintext2, *plaintext3, *password;
    NSString *plainString1, *plainString2;
    UMCrypto *cryptor = [[UMCrypto alloc] init];
    NSData *newkey = nil, *oldkey = nil;
    
    @autoreleasepool {
    
        for (j = 0; j < 8; j++)
        {
            NSLog(@"DES:%ld data_len:%u key_len:%u\r\n", j+1, des_test[j].data_len, des_test[j].key_len);
            //      debug_display_mem_hex(hmac_md5_test[j].data, hmac_md5_test[j].data_len, 0);
            plaintext1 = [NSData dataWithBytes:des_test[j].data length:des_test[j].data_len];
            plainString1 = [[NSString alloc] initWithData:plaintext1 encoding:NSUTF8StringEncoding];
            password = [NSData dataWithBytes:des_test[j].key length:des_test[j].key_len];
            
            if (newkey)
                oldkey = [NSData dataWithData:newkey];
            ciphertext = [cryptor encryptData:plaintext1 withPassword:password withKey:&newkey withGrade:1];
            XCTAssertNotNil(ciphertext, @"encryption should be successful");
            XCTAssertTrue(![oldkey isEqualToData:newkey], @"new key generated should differ form the previous one ");
            NSLog(@"TestUMCrypto: testCryptorCrypto: ciphertext: %@\r\n", ciphertext);
            
            if (ciphertext)
            {
                plaintext2 = [cryptor decryptData:ciphertext withPassword:newkey];
                plaintext3 = [plaintext2 subdataWithRange:NSMakeRange(0, [plaintext1 length])];
                plainString2 = [[NSString alloc] initWithData:plaintext2 encoding:NSUTF8StringEncoding];
                XCTAssertNotNil(plaintext2, @"decryption should be successful");
                //[TestUMCrypto displayMemHex:plaintext2 withSize:(unsigned int)[plaintext2 length] withColumn:0];
                XCTAssertTrue([plaintext3 isEqualToData:plaintext1], @"encrypting plus deacrypting should equal original (expect added \0s in the end)");
                XCTAssertTrue(![plaintext1 isEqualToData:ciphertext], @"encrypting should change the data");
            }
	}
    
    /* Testing generated CommonCrypto key*/
    
/* TODO: THIS TEST FAILS !! */

/*    cryptor = [[[UMCrypto alloc] initWithKey] autorelease];
    NSData *des3key = [cryptor cryptorKey];
    XCTAssertTrue(![des3key isEqualToData:newkey], @"new key generated should be differ from the previous one");
    
    NSData *plaintext4 = [NSData dataWithBytes:des_test[7].data length:des_test[7].data_len];
    NSData *ciphertext2 = [cryptor encryptData:plaintext4 withPassword:des3key];
    XCTAssertNotNil(ciphertext2, @"encryption should be successful");
    NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext2);
    
    if (ciphertext2)
    {
        NSData *plaintext5 = [cryptor decryptData:ciphertext2 withPassword:des3key];
        NSData *plaintext6 = [plaintext5 subdataWithRange:NSMakeRange(0, [plaintext4 length])];
        XCTAssertNotNil(plaintext5, @"decryption should be successful");
        NSLog(@"Plaintext4: \n%@",plaintext4);
        NSLog(@"Plaintext6: \n%@",plaintext6);
        XCTAssertTrue([plaintext4 isEqualToData:plaintext6], @"encrypting plus decrypting should equal original (expect trailing zeroes)");
        XCTAssertTrue(![plaintext4 isEqualToData:ciphertext2], @"encrypting should change the data");
    }
*/
    }
}
#endif
#ifdef HAS_OPENSSL
- (void)testSSLCrypto
{
    long j;
    int len;
    NSData *ciphertext, *plaintext1, *plaintext2, *plaintext3, *password;
    UMCrypto *cryptor = [[UMCrypto alloc] initDESInitWithSaltAndIV];
    NSString *plainString1, *plainString2;
    NSData *key;
    
    @autoreleasepool
    {
        for (j = 0; j < 8; j++)
        {
            NSLog(@"DES:%ld data_len:%u key_len:%u\r\n", j+1, des_test[j].data_len, des_test[j].key_len);
            //      debug_display_mem_hex(hmac_md5_test[j].data, hmac_md5_test[j].data_len, 0);
            plaintext1 = [NSData dataWithBytes:des_test[j].data length:des_test[j].data_len];
            password = [NSData dataWithBytes:des_test[j].key length:des_test[j].key_len];
            plainString1 = [[NSString alloc] initWithData:plaintext1 encoding:NSUTF8StringEncoding];
            len = (int)[plaintext1 length];
            ciphertext = [cryptor DESEncryptWithPlaintext:plaintext1 havingLength:&len withPassword:password withKey:&key withGrade:1];
        
            XCTAssertNotNil(ciphertext, @"encryption should be successful");
            NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext);
        
            if (ciphertext)
            {
                plaintext2 = [cryptor decryptDataWithSSL:ciphertext withKey:key];
                plaintext3 = [plaintext2 subdataWithRange:NSMakeRange(0, [plaintext1 length])];
                plainString2 = [[NSString alloc] initWithData:plaintext2 encoding:NSUTF8StringEncoding];
                XCTAssertNotNil(plaintext2, @"decryption should be successful");
                //[TestUMCrypto displayMemHex:plaintext2 withSize:(unsigned int)[plaintext2 length] withColumn:0];
                XCTAssertTrue([plaintext1 isEqualToData:plaintext2], @"encrypting plus deacrypting should equal original");
                XCTAssertTrue(![plaintext1 isEqualToData:ciphertext], @"encrypting should change the data");
            }
	    }
    
        /* If you do not want to use salt and iv, init accordingly, and use DESEncryptWithPlaintext:havingLength:
         * withPassword:
         */
        cryptor = [[UMCrypto alloc] init];
    
        for (j = 0; j < 8; j++)
        {
            NSLog(@"DES:%ld data_len:%u key_len:%u\r\n", j+1, des_test[j].data_len, des_test[j].key_len);
            // debug_display_mem_hex(hmac_md5_test[j].data, hmac_md5_test[j].data_len, 0);
            plaintext1 = [NSData dataWithBytes:des_test[j].data length:des_test[j].data_len];
            password = [NSData dataWithBytes:des_test[j].key length:des_test[j].key_len];
            plainString1 = [[NSString alloc] initWithData:plaintext1 encoding:NSUTF8StringEncoding];
            len = (int)[plaintext1 length];
            ciphertext = [cryptor DESEncryptWithPlaintext:plaintext1 havingLength:&len withPassword:password];
            XCTAssertNotNil(ciphertext, @"encryption should be successful");
            NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext);
        
            if (ciphertext)
            {
                plaintext2 = [cryptor decryptDataWithSSL:ciphertext withKey:password];
                plaintext3 = [plaintext2 subdataWithRange:NSMakeRange(0, [plaintext1 length])];
                plainString2 = [[NSString alloc] initWithData:plaintext2 encoding:NSUTF8StringEncoding];
                XCTAssertNotNil(plaintext2, @"decryption should be successful");
                //[TestUMCrypto displayMemHex:plaintext2 withSize:(unsigned int)[plaintext2 length] withColumn:0];
                XCTAssertTrue([plaintext1 isEqualToData:plaintext2], @"encrypting plus decrypting should equal original");
                XCTAssertTrue(![plaintext1 isEqualToData:ciphertext], @"encrypting should change the data");
            }
	    }
    
        /* Testing generated DES key*/
        cryptor = [[UMCrypto alloc] initDESInitWithKeyWithEntropySource:@"/tmp/random.data" withGrade:1];
        NSData *deskey = [cryptor deskey];
        plaintext1 = [NSData dataWithBytes:des_test[7].data length:des_test[7].data_len];
        len = (int)[plaintext1 length];
        ciphertext = [cryptor DESEncryptWithPlaintext:plaintext1 havingLength:&len withPassword:deskey];
        XCTAssertNotNil(ciphertext, @"encryption should be successful");
        NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext);
    
        if (ciphertext)
        {
            plaintext2 = [cryptor decryptDataWithSSL:ciphertext withKey:deskey];
            XCTAssertNotNil(plaintext2, @"decryption should be successful");
            XCTAssertTrue([plaintext1 isEqualToData:plaintext2], @"encrypting plus decrypting should equal original");
            XCTAssertTrue(![plaintext1 isEqualToData:ciphertext], @"encrypting should change the data");
        }
    }
}

/* Generate entropy source file with dd if=/dev/random of=/tmp/random.data" count=4*RSA_KEY_LEN */
- (void)testSSLPublicCrypto
{
    long j;
    NSData *ciphertext1, *ciphertext2, *plaintext2, *plaintext3;
    NSMutableData* plaintext1;
    @autoreleasepool
    {
        UMCrypto *cryptor, *cryptor1;
        NSData *publickey1, *publickey2, *privatekey1, *privatekey2;
    
        cryptor1 = [[UMCrypto alloc] initSSLPublicCryptoWithEntropySource:@"/tmp/random.data"];
        publickey1 = [cryptor1 publicKey];
        privatekey1 = [cryptor1 privateKey];
        cryptor = [[UMCrypto alloc] initSSLPublicCryptoWithEntropySource:@"/tmp/random.data"];
        publickey2 = [cryptor publicKey];
        privatekey2 = [cryptor privateKey];
        XCTAssertNotNil(publickey1, @"creation a public key should be ´successful");
        XCTAssertNotNil(privatekey1, @"creation a private key should be ´successful");
        XCTAssertTrue(![publickey1 isEqualToData:publickey2], @"every instantiation should produce a new public key");
        XCTAssertTrue(![privatekey1 isEqualToData:privatekey2], @"every instantiation should produce a new private key");
    
        /* public cryptography */
        plaintext1 = [NSMutableData dataWithBytes:des_test[7].data length:108];
        for (j = 1; j < 4; j++) {
            [plaintext1 appendBytes:des_test[4].data length:50];
       }
    
        ciphertext1 = [cryptor RSAEncryptWithPlaintextSSLPublic:plaintext1];
        XCTAssertNotNil(ciphertext1, @"encryption should be successful");
        NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext1);
    
        if (ciphertext1)
        {
            plaintext2 = [cryptor RSADecryptWithCiphertextSSLPrivate:ciphertext1];
            XCTAssertNotNil(plaintext2, @"decryption should be successful");
            XCTAssertTrue([plaintext1 isEqualToData:plaintext2], @"encrypting plus decrypting should equal original");
            XCTAssertTrue(![plaintext1 isEqualToData:ciphertext1], @"encrypting should change the data");
        }
    
        /* raw digital signature */
        ciphertext2 = [cryptor RSAEncryptWithPlaintextSSLPrivate:plaintext1];
        XCTAssertNotNil(ciphertext2, @"encryption should be successful");
        NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext1);
    
        if (ciphertext2)
        {
            plaintext3 = [cryptor RSADecryptWithCiphertextSSLPublic:ciphertext2];
            XCTAssertNotNil(plaintext3, @"decryption should be successful");
            XCTAssertTrue([plaintext1 isEqualToData:plaintext3], @"encrypting plus decrypting should equal original");
            XCTAssertTrue(![plaintext1 isEqualToData:ciphertext2], @"encrypting should change the data");
        }
    }
}

#endif

#ifdef HAS_COMMON_CRYPTO
- (void)testCryptorPublicCrypto
{
    @autoreleasepool
    {
        UMCrypto *cryptor, *cryptor1;
        NSData *publickey1, *publickey2, *privatekey1, *privatekey2, *ciphertext1, *plaintext2;
        NSMutableData *plaintext1;
        long j;
        
        cryptor1 = [[UMCrypto alloc] initPublicCrypto];
        publickey1 = [cryptor1 publicKey];
        privatekey1 = [cryptor1 privateKey];
        cryptor = [[UMCrypto alloc] initPublicCrypto];
        publickey2 = [cryptor publicKey];
        privatekey2 = [cryptor privateKey];
        XCTAssertNotNil(publickey1, @"creation a public key should be successful");
        XCTAssertNotNil(privatekey1, @"creation a private key should be successful");
        XCTAssertTrue(![publickey1 isEqualToData:publickey2], @"every instantiation should produce a new public key");
        XCTAssertTrue(![privatekey1 isEqualToData:privatekey2], @"every instantiation should produce a new private key");
        
        /* public cryptography */
        plaintext1 = [NSMutableData dataWithBytes:des_test[7].data length:108];
        for (j = 1; j < 4; j++) {
            [plaintext1 appendBytes:des_test[4].data length:50];
        }
        
        ciphertext1 = [cryptor RSAEncryptWithPlaintextPublic:plaintext1];
        XCTAssertNotNil(ciphertext1, @"encryption should be successful");
        NSLog(@"TestUMCrypto: testCryptorPublicCryptoCrypto: ciphertext: %@\r\n", ciphertext1);
        
        if (ciphertext1)
        {
            plaintext2 = [cryptor RSADecryptWithCiphertextPrivate:ciphertext1];
            XCTAssertNotNil(plaintext2, @"decryption should be successful");
            XCTAssertTrue([plaintext1 isEqualToData:plaintext2], @"encrypting plus decrypting should equal original");
            XCTAssertTrue(![plaintext1 isEqualToData:ciphertext1], @"encrypting should change the data");
        }
        
    }
}
#endif
@end
