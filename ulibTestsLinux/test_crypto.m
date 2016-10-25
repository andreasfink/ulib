#import "test_crypto.h"
#import "Foundation/Foundation.h"
#import "UMCrypto.h"

void testSSLCrypto(void)
{
    long j;
    int len;
    NSData *ciphertext, *plaintext1, *plaintext2, *plaintext3, *password;
    UMCrypto *cryptor = [[UMCrypto alloc] initDESInitWithSaltAndIV]];
    NSString *plainString1, *plainString2;
    NSData *key;
    NSData *new_salt, *old_salt, *old_iv, *new_iv;
    int ret = 0;
    
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
        old_salt = [NSData dataWithBytes:[cryptor salt] length:DES_SALT_LEN];
        old_iv = [NSData dataWithBytes:[cryptor iv] length:DES_BLOCK_SIZE];
        ciphertext = [cryptor DESEncryptWithPlaintext:plaintext1 havingLength:&len withPassword:password withKey:&key withGrade:1];

        new_salt = [NSData dataWithBytes:[cryptor salt] length:DES_SALT_LEN];
        new_iv = [NSData dataWithBytes:[cryptor iv] length:DES_BLOCK_SIZE];
        if (!ciphertext)
        {
            ret = 1;
            NSLog(@"encryption should be successful");
        }
        if (!old_salt)
        {
            ret = 1;
            NSLog(@"salt should never be nil (old_salt");
        }
        if (!new_salt)
        {
            ret	= 1;
       	    NSLog(@"salt should never be nil (new_salt");
       	}
        if (!old_iv)
        {
       	    ret = 1;
       	    NSLog(@"iv should never be nil (old_iv");
       	}
        if (!new_iv)
        {
            ret = 1;
       	    NSLog(@"iv should never be nil (new_iv");
       	}
        if ([old_salt isEqualTo:new_salt])
        {
            ret = 1;
            NSLog(@"salt value should change with every new encryption");
        }
        if ([old_iv isEqualTo:new_iv])
        {
            ret = 1;
            NSLog(@"iv value should change with every new encryption");
        }
        NSLog(@"test_crypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext);

        if (ciphertext)
        {
            plaintext2 = [cryptor decryptDataWithSSL:ciphertext withKey:key];
            plaintext3 = [plaintext2 subdataWithRange:NSMakeRange(0, [plaintext1 length])];
            plainString2 = [[NSString alloc] initWithData:plaintext2 encoding:NSUTF8StringEncoding];
            if (!plaintext2) {
                ret = 1;
                NSLog(@"decryption should be successful");
            }
            if (![plaintext1 isEqualToData:plaintext2])
            {
                ret = 1;
       	       	NSLog(@"encrypting plus decrypting should equal original");
            }
            if ([plaintext1 isEqualToData:ciphertext])
            {
                ret = 1;
                NSLog(@"encrypting should change the data");
            }
        }
    }

    /* If you do not want to use salt and iv, init accordingly, and use DESEncryptWithPlaintext:havingLength:
     * withPassword:
     */
    cryptor = [[UMCrypto alloc] init];
    for (j = 0; j < 8; j++) {
        NSLog(@"DES:%ld data_len:%u key_len:%u\r\n", j+1, des_test[j].data_len, des_test[j].key_len);
        //      debug_display_mem_hex(hmac_md5_test[j].data, hmac_md5_test[j].data_len, 0);
        plaintext1 = [NSData dataWithBytes:des_test[j].data length:des_test[j].data_len];
        password = [NSData dataWithBytes:des_test[j].key length:des_test[j].key_len];
        plainString1 = [[NSString alloc] initWithData:plaintext1 encoding:NSUTF8StringEncoding];
        len = (int)[plaintext1 length];
        ciphertext = [cryptor DESEncryptWithPlaintext:plaintext1 havingLength:&len withPassword:password];
        if (!ciphertext) {
            ret = 1;
            NSLog(@"encryption should be successful");
        }
        NSLog(@"test_crypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext);

        if (ciphertext) {
            plaintext2 = [cryptor decryptDataWithSSL:ciphertext withKey:password];
            plaintext3 = [plaintext2 subdataWithRange:NSMakeRange(0, [plaintext1 length])];
            plainString2 = [[NSString alloc] initWithData:plaintext2 encoding:NSUTF8StringEncoding];
            if (!plaintext2) {
                ret = 1;
                NSLog(@"decryption should be successful");
            }
            if (![plaintext1 isEqualToData:plaintext2]) {
                ret = 1;
                NSLog(@"encrypting plus decrypting should equal original");
            }
            if ([plaintext1 isEqualToData:ciphertext]) {
                ret = 1;
                NSLog(@"encrypting should change the data");
            }
        }
    }

    /* Testing generated DES key*/
    cryptor = [[UMCrypto alloc] DESInitWithKeyWithEntropySource:@"/tmp/random.data" withGrade:1];
    NSData *deskey = [cryptor deskey];
    if (!deskey) {
        ret = 1;
        NSLog(@"creating des key should be successful");
    }
    cryptor = [[UMCrypto alloc] DESInitWithKeyWithEntropySource:@"/tmp/random.data" withGrade:1;
    NSData *deskey2 = [cryptor deskey];
    if ([deskey isEqualToData:deskey2]) {
        ret = 1;
        NSLog(@"des keys created should be different");
    }
    plaintext1 = [NSData dataWithBytes:des_test[7].data length:des_test[7].data_len];
    len = (int)[plaintext1 length];
    ciphertext = [cryptor DESEncryptWithPlaintext:plaintext1 havingLength:&len withPassword:deskey];
    if (!ciphertext) {
        ret = 1;
        NSLog(@"encryption should be successful");
    }
    if (ciphertext) {
        plaintext2 = [cryptor decryptDataWithSSL:ciphertext withKey:deskey];
        if (!plaintext2) {
            ret = 1;
            NSLog(@"decryption should be successful");
        }
        if (![plaintext1 isEqualToData:plaintext2]) {
            ret = 1;
            NSLog(@"encrypting plus decrypting should equal original");
        }
        if ([plaintext1 isEqualToData:ciphertext]) {
            ret = 1;
            NSLog(@"encrypting should change the data");
        }
    }

    }
    if (ret == 1)
    {
        exit(1);
    }
}

void testSSLPublicCrypto(void)
{
    long j;
    int ret;
    NSData *ciphertext1, *ciphertext2, *plaintext2, *plaintext3;
    NSMutableData* plaintext1;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    UMCrypto *cryptor, *cryptor1;
    NSData *publickey1, *publickey2, *privatekey1, *privatekey2;

    cryptor1 = [[UMCrypto alloc] initSSLPublicCryptoWithEntropySource:@"/tmp/random.data"];
    publickey1 = [cryptor1 publicKey];
    privatekey1 = [cryptor1 privateKey];
    cryptor = [[UMCrypto alloc] initSSLPublicCryptoWithEntropySource:@"/tmp/random.data"];
    publickey2 = [cryptor publicKey];
    privatekey2 = [cryptor privateKey];
    if (!publickey1) {
        ret = 1;
        NSLog(@"creation a public key should be successful");
    }
    if (!privatekey1) {
       	ret = 1;
       	NSLog(@"creation a private key should be successful");
    }
    if ([publickey1 isEqualToData:publickey2])
    {
        ret = 1;
        NSLog(@"every instantiation should produce a new public key");
    }
    if ([privatekey1 isEqualToData:privatekey2]) 
    {
       	ret = 1;
       	NSLog(@"every instantiation should produce a new private key");
    }
    
    /* public cryptography */
    plaintext1 = [NSMutableData dataWithBytes:des_test[7].data length:108];
    for (j = 1; j < 4; j++)
    {
        [plaintext1 appendBytes:des_test[4].data length:50];
    }
    
    ciphertext1 = [cryptor RSAEncryptWithPlaintextSSLPublic:plaintext1];
    if (!ciphertext1)
    {
        ret = 1;
        NSLog(@"encryption should be successful");
    }
    if (ciphertext1)
    {
        plaintext2 = [cryptor RSADecryptWithCiphertextSSLPrivate:ciphertext1];
        if (!plaintext2)
        {
            ret = 1;
            NSLog(@"decryption should be successful");
        }
        if (![plaintext1 isEqualToData:plaintext2])
        {
            ret = 1;
            NSLog(@"encrypting plus decrypting should equal original");
        }
        if ([plaintext1 isEqualToData:ciphertext1])
        {
            ret = 1;
            NSLog(@"encrypting should change the data");
        }
    }

    /* raw digital signature */
    ciphertext2 = [cryptor RSAEncryptWithPlaintextSSLPrivate:plaintext1];
    if (!ciphertext2) {
       	ret = 1;
       	NSLog(@"encryption should be successful");
    }
    NSLog(@"TestUMCrypto: testSSLCrypto: ciphertext: %@\r\n", ciphertext2);
    if (ciphertext2)
    {
        plaintext3 = [cryptor RSADecryptWithCiphertextSSLPublic:ciphertext2];
        if (!plaintext3)
        {
            ret = 1;
            NSLog(@"decryption should be successful");
        }
        if (![plaintext1 isEqualToData:plaintext3])
        {
            ret = 1;
            NSLog(@"encrypting plus decrypting should equal original");
        }
        if ([plaintext1 isEqualToData:ciphertext2])
        {
            ret = 1;
            NSLog(@"encrypting should change the data");
        }
    }

    if (ret == 1)
    {
        exit(1);
    }
}

int main(void)
{
    testSSLCrypto();
    testSSLPublicCrypto();    

    return 0;
}
