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
        NSString *publickey1;
        NSString *publickey2;
        NSString *privatekey1;
        NSString *privatekey2;
    
        cryptor1 = [[UMCrypto alloc] initPublicCrypto];
        publickey1 = [cryptor1 publicKey];
        privatekey1 = [cryptor1 privateKey];
        cryptor = [[UMCrypto alloc] initPublicCrypto];
        publickey2 = [cryptor publicKey];
        privatekey2 = [cryptor privateKey];
        XCTAssertNotNil(publickey1, @"creation a public key should be ´successful");
        XCTAssertNotNil(privatekey1, @"creation a private key should be ´successful");
        XCTAssertTrue(![publickey1 isEqualToString:publickey2], @"every instantiation should produce a new public key");
        XCTAssertTrue(![privatekey1 isEqualToString:privatekey2], @"every instantiation should produce a new private key");
    
        /* public cryptography */
        plaintext1 = [NSMutableData dataWithBytes:des_test[7].data length:108];
        for (j = 1; j < 4; j++)
        {
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
        ciphertext2 = [cryptor RSAEncryptWithPlaintextSSLPublic:plaintext1];
        XCTAssertNotNil(ciphertext2, @"encryption should be successful");
        NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext1);
    
        if (ciphertext2)
        {
            plaintext3 = [cryptor RSADecryptWithCiphertextSSLPrivate:ciphertext2];
            XCTAssertNotNil(plaintext3, @"decryption should be successful");
            XCTAssertTrue([plaintext1 isEqualToData:plaintext3], @"encrypting plus decrypting should equal original");
            XCTAssertTrue(![plaintext1 isEqualToData:ciphertext2], @"encrypting should change the data");
        }
    }
}

- (void)testAES256
{
    unsigned char key[]      = { 0x08,0x09,0x0A,0x0B,0x0D,0x0E,0x0F,0x10,0x12,0x13,0x14,0x15,0x17,0x18,0x19,0x1A,0x1C,0x1D,0x1E,0x1F,0x21,0x22,0x23,0x24,0x26,0x27,0x28,0x29,0x2B,0x2C,0x2D,0x2E};
    unsigned char plaintext[]= { 0x06,0x9A,0x00,0x7F,0xC7,0x6A,0x45,0x9F,0x98,0xBA,0xF9,0x17,0xFE,0xDF,0x95,0x21,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
    unsigned char ciphertext[] = { 0x08,0x0e,0x95,0x17,0xeb,0x16,0x77,0x71,0x9a,0xcf,0x72,0x80,0x86,0x04,0x0a,0xe3,
        0x9a,0x4f,0x27,0x6d,0x62,0xa2,0xab,0x69,0xc1,0x82,0x22,0x69,0xde,0xba,0x79,0x37,0x50,0x95,0x44,0x2a,0x2c,0xeb,0x4e,0x44,0x9e,0x6d,0x27,0xd3,0x75,0xff,0x8a,0xd4};

    NSData *plaintext1 = [NSData dataWithBytes:plaintext length:sizeof(plaintext)];
    NSData *ciphertext1 = [NSData dataWithBytes:ciphertext length:sizeof(ciphertext)];

    UMCrypto *crypto = [[UMCrypto alloc]init];
    crypto.aes256Key = [NSData dataWithBytes:key length:sizeof(key)];
    NSData *ciphertext2 = [crypto aes256Encrypt:plaintext1];
    XCTAssertTrue([ciphertext1 isEqualToData:ciphertext2],  @"encrypting did not return test case");
    NSData *plaintext2 = [crypto aes256Decrypt:ciphertext2];
    XCTAssertTrue([plaintext1 isEqualToData:plaintext2],  @"decrypting did not return test case");

    NSData *plaintext3 = [crypto aes256Decrypt:ciphertext1];
    XCTAssertTrue([plaintext1 isEqualToData:plaintext3],  @"decrypting did not return original test case");

}

@end
