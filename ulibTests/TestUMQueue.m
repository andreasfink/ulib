//
//  TestUMQueue.m
//  ulib
//
//  Created by Aarno Syvänen on 19.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUMQueue.h"
#import "UMQueue.h"

@implementation TestUMQueue

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
        UMQueue *queue = [[UMQueue alloc] init];
        [queue append:@"first"];
        [queue append:@"second"];
        [queue append:@"third"];
        XCTAssertTrue([queue count] == 3, @"queue should have 3 elements");
        NSString *first = [queue getFirst];
        XCTAssertTrue([first compare:@"first"] == NSOrderedSame, @"first element added to queuewas first");
        [queue getFirst];
        [queue getFirst];
        XCTAssertTrue([queue count] == 0, @"all elements removed from queue");
        
    
    }
}

@end
