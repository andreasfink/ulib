//
//  TestUMDate.m
//  ulibTests
//
//  Created by Andreas Fink on 30.03.20.
//  Copyright © 2020 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUMDate.h"
#import <ulib/ulib.h>

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
    NSString *s = @"2020-05-30 12:00:00";

    NSDate *d = [NSDate dateWithStandardDateString:s];
    XCTAssertNotNil(d,@"can not convert date string");
}

- (void)testDate2
{
    NSString *a   = @"2020-04-22 09:55:58.000000";
    NSDate *d     = [a dateValue];
    NSString *b   = [d stringValue];
    NSLog(@"\na=%@\nb=%@\n",a,b);
}
@end
