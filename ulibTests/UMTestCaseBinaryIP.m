//
//  UMTestCaseBinaryIP.m
//  ulibTests
//
//  Created by Andreas Fink on 01.06.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+UMSocket.h"

@interface test : XCTestCase

@end

@implementation test

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}



- (void)testBinaryIp4
{
    uint8_t b1[4] = {1,2,3,4};
    NSString *s = @"1.2.3.4";
    NSData *a = [s binaryIPAddress];
    NSData *b = [[NSData alloc]initWithBytes:b1 length:4];
    XCTAssert([a isEqualToData:b],@"data doesnt match");
}


@end
