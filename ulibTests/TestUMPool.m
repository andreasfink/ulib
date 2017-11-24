//
//  TestUMPool.m
//  ulibTests
//
//  Created by Andreas Fink on 24.11.17.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUMPool.h"
#import "UMPool.h"

@implementation TestUMPool

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)testQueue
{
    @autoreleasepool
    {
        UMPool *queue = [[UMPool alloc] init];
        [queue append:@"first"];
        [queue append:@"second"];
        [queue append:@"third"];
        XCTAssertTrue([queue count] == 3, @"queue should have 3 elements");
        NSString *first = [queue getAny];
        XCTAssertTrue([queue count] == 2, @"queue should have 2 elements");
        NSString *second = [queue getAny];
        XCTAssertTrue([queue count] == 1, @"queue should have 1 elements");
        NSString *third = [queue getAny];
        XCTAssertTrue([queue count] == 0, @"all elements removed from queue");
    }
}
@end
