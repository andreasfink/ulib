//
//  TestUMDate.m
//  ulibTests
//
//  Created by Andreas Fink on 30.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUMDate.h"
#import "NSDate+stringFunctions.h"

@implementation TestUMDate



- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testDate
{
    NSString *s = @"2020-30-05 12:00:00";

    NSDate *d = [NSDate dateWithStandardDateString:s];
    XCTAssertNotNil(d,@"can not convert date string");
}

@end
