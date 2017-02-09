//
//  TestUmLogFile.m
//  ulib
//
//  Created by Aarno Syvänen on 20.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUmLogFile.h"
#import "UMTestCase.h"
#import "UMLogEntry.h"
#import "UMLogFile.h"
#import "UMConfig.h"
#import "UMUtil.h"

@implementation TestUmLogFile

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

- (void)configLogWithLogFile:(NSString **)logFile
{
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString *cfgName = [thisBundle pathForResource:@"log-test" ofType:@"conf"];
    UMConfig *cfg = [[UMConfig alloc] initWithFileName:cfgName];
    [cfg allowSingleGroup:@"core"];
    [cfg read];

    NSDictionary *grp = [cfg getSingleGroup:@"core"];
    XCTAssert(grp,"configuration file must have group core");
    *logFile = grp[@"log-file"];
}

- (void)testFile
{
    @autoreleasepool
    {
        NSString *logFile;
        int ret;
        long first, second, third;
        NSRange firstText, secondText, thirdText;
        NSString *firstLine, *secondLine, *thirdLine;
        unsigned long long size;
        
        UMLogFile *dst1 = [[UMLogFile alloc] initWithFileName:@"" andSeparator:@"\r\n"];
        XCTAssertNil(dst1, @"tester must reject empty file name");
        UMLogFile *dst = [[UMLogFile alloc] initWithFileName:nil andSeparator:@"\r\n"];
        XCTAssertNil(dst, @"tester must reject nil file name");
        
        [self configLogWithLogFile:&logFile];
        dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
        XCTAssertNotNil(dst, @"tester must be able to create the file object");
        
        UMLogEntry *e1 = [[UMLogEntry alloc] init];
	    [e1 setLevel:UMLOG_DEBUG];
	    [e1 setSection:@"Universal tests"];
	    [e1  setSubsection:@"ulib tests"];
	    [e1 setName:@"UMLogFile tests"];
	    [e1 setErrorCode:0];
	    [e1  setMessage:@"first test string\r\n"];
        first = [dst logNowAndGiveSize:e1];
        size = [dst size];
        XCTAssertTrue(size == first, @"file size should the length of first line");    
        
        UMLogEntry *e2 = [[UMLogEntry alloc] init];
	[e2 setLevel:UMLOG_DEBUG];
	[e2 setSection:@"Universal tests"];
	[e2 setSubsection:@"ulib tests"];
	[e2 setName:@"UMLogFile tests"];
	[e2 setErrorCode:0];
	[e2 setMessage:@"second test string2\r\n"];
        second = [dst logNowAndGiveSize:e2];
        size = [dst size];              
        XCTAssertTrue(size == first + second, @"file size should the length of two lines");
        
        UMLogEntry *e3 = [[UMLogEntry alloc] init];
	[e3 setLevel:UMLOG_DEBUG];
	[e3 setSection:@"Universal tests"];
	[e3 setSubsection:@"ulib tests"];
	[e3 setName:@"UMLogFile tests"];
	[e3 setErrorCode:0];
	[e3 setMessage:@"third test string\r\n"];
        third = [dst logNowAndGiveSize:e3];
        size = [dst size];
        XCTAssertTrue(size == first + second + third, @"file size should the length of three lines");
        
        [dst updateFileSize];
        firstLine = [dst readLine:&ret];
        XCTAssertTrue(ret == 1, @"tester should be able to read the first line of the file");
        secondLine = [dst readLine:&ret];
        XCTAssertTrue(ret == 1, @"tester should be able to read the second line of the file");
        thirdLine = [dst readLine:&ret];
        XCTAssertTrue(ret == 1, @"tester should be able to read the third line of the file");
        
        firstText = [firstLine rangeOfString:@"first"];
        secondText = [secondLine rangeOfString:@"second"];
        thirdText = [thirdLine rangeOfString:@"third"];
        XCTAssertTrue(firstText.location != NSNotFound, @"first logged line should be in the file");
        XCTAssertTrue(secondText.location != NSNotFound, @"second logged line should be in the file");
        XCTAssertTrue(thirdText.location != NSNotFound, @"third logged line should be in the file");
        
        [dst emptyLog];
        size = [dst size];
        XCTAssertTrue(size == 0, @"file size should the zero after emptying operation");
        [dst closeLog];
        [dst removeLog];
    
    }
}

@end
