//
//  TestUMQueue.m
//  ulib
//
//  Created by Aarno Syvänen on 19.04.12.
//  Copyright (c) Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved
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
        
        UMQueue *unlockedQueue = [[UMQueue alloc] initWithoutLock];
        [unlockedQueue lock];
        [unlockedQueue append:@"first"];
        [unlockedQueue unlock];
        [unlockedQueue lock];
        [unlockedQueue append:@"second"];
        [unlockedQueue unlock];
        [unlockedQueue lock];
        [unlockedQueue append:@"third"];
        [unlockedQueue unlock];
        XCTAssertTrue([unlockedQueue count] == 3, @"unlocked queue should have 3 elements");
        [unlockedQueue lock];
        NSString *unlockedFirst = [unlockedQueue getFirst];
        [unlockedQueue unlock];
        XCTAssertTrue([unlockedFirst compare:@"first"] == NSOrderedSame, @"first element added to unlocked queue was first");
        [unlockedQueue lock];
        [unlockedQueue getFirst];
        [unlockedQueue unlock];
        [unlockedQueue lock];
        [unlockedQueue getFirst];
        [unlockedQueue unlock];
        XCTAssertTrue([unlockedQueue count] == 0, @"all elements removed from unlocked queuue");
    
    }
}

@end
