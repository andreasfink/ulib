//
//  TestUmLogHandler.m
//  ulib
//
//  Created by Aarno Syvänen on 25.04.12.
//  Copyright (c) Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved
//

#import "TestUmLogHandler.h"
#import "UMTestCase.h"
#import "UMLogFile.h"
#import "UMConfig.h"
#import "UMUtil.h"

@implementation TestUmLogHandler

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

- (void)testLogHandler
{
    @autoreleasepool
    {
        NSString *logFile;
        UMTestHandler *handler;
        UMLogFile *dst;
        long first, second, third;
        NSRange firstText, secondText, thirdText, fourthText, bad;
        NSString *firstLine, *secondLine, *thirdLine, *fourthLine;
        int ret;
        
        [self configLogWithLogFile:&logFile];
        handler = [[UMTestHandler alloc] initWithConsole];
        dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
        [dst emptyLog];
        
        UMLogEntry *e = [[UMLogEntry alloc] init];
        [ e setLevel:UMLOG_DEBUG];
	    [ e setSection:@"Universal tests"];
	    [ e setSubsection:@"ulib tests"];
	    [ e setName:@"Log handler tests"];
	    [ e setErrorCode:0];
	    [ e setMessage:@"first log message\r\n"];
	    [ handler logAnEntry:e];
        XCTAssertTrue([dst size] == 0, @"nothing should bew logged, if no log destinatiion has been added");
        
        [handler addLogDestination:dst];
	    first = [handler LogAnEntryAndGiveSize:e];
        XCTAssertTrue([dst size] == first + 1, @"size of file should be the size of first log message (with an additional newline in logfile)");
        
        UMLogEntry *e2 = [[UMLogEntry alloc] init];
        [ e2 setLevel:UMLOG_DEBUG];
        [ e2 setSection:@"Universal tests"];
	    [ e2 setSubsection:@"ulib tests"];
	    [ e2 setName:@"Log handler tests"];
	    [ e2 setErrorCode:0];
	    [ e2 setMessage:@"second log message\r\n"];
        second = [handler LogAnEntryAndGiveSize:e2];
        XCTAssertTrue([dst size] == first + second + 2, @"size of file should be the size of two log messages(with an additional newline in logfile)");
        
        UMLogEntry *e3 = [[UMLogEntry alloc] init];
        [ e3 setLevel:UMLOG_DEBUG];
	    [ e3 setSection:@"Universal tests"];
	    [ e3 setSubsection:@"ulib tests"];
	    [ e3 setName:@"Log handler tests"];
	    [ e3 setErrorCode:0];
	    [ e3 setMessage:@"third log message\r\n"];
        third = [handler LogAnEntryAndGiveSize:e3];
        XCTAssertTrue([dst size] == first + second + third + 3, @"size of file should be the size of three log messages (with an additional newline in logfile)");
        
        [handler log:0 section:@"Universal tests" subsection:@"ulib tests" name:@"Log handler tests" text:@"fourth log message\r\n" errorCode:EBADMSG];
        
        [dst updateFileSize];
        firstLine = [dst readLine:&ret];
        XCTAssertTrue(ret == 1, @"log handler tester should be able to read the second line of the file");
        secondLine = [dst readLine:&ret];
        XCTAssertTrue(ret == 1, @"log handler tester should be able to read the second line of the file");
        thirdLine = [dst readLine:&ret];
        XCTAssertTrue(ret == 1, @"log handler tester should be able to read the third line of the file");
        fourthLine = [dst readLine:&ret];
        XCTAssertTrue(ret == 1, @"log handler tester should be able to read the fourth line of the file");
        
        firstText = [firstLine rangeOfString:@"first"];
        secondText = [secondLine rangeOfString:@"second"];
        thirdText = [thirdLine rangeOfString:@"third"];
        fourthText = [fourthLine rangeOfString:@"fourth"];
        bad = [fourthLine rangeOfString:@"Bad message."];
        
        XCTAssertTrue(firstText.location != NSNotFound, @"first logged line should be in the file");
        XCTAssertTrue(secondText.location != NSNotFound, @"second logged line should be in the file");
        XCTAssertTrue(thirdText.location != NSNotFound, @"third logged line should be in the file");
        XCTAssertTrue(fourthText.location != NSNotFound, @"fourth logged line should be in the file");
        
        [dst emptyLog];
        [handler removeLogDestination:dst];
        [handler logAnEntry:e];
        XCTAssertTrue([dst size] == 0, @"nothing should bew logged, if no log destinatiion has been added");
        [dst closeLog];
        [dst removeLog];
    
    }
}

@end
