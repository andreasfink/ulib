//
//  TestUMLogFeed.m
//  ulib
//
//  Created by Aarno Syvänen on 20.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "TestUMLogFeed.h"
#import "UMLogHandler.h"
#import "UMLogFeed.h"
#import "UMConfig.h"
#import "UMLogFile.h"
#import "UMUtil.h"

@implementation TestUMLogFeed

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    // Tear-down code here.
    [super tearDown];
}

+ (void) messagesInLogFile:(UMLogFile *)dst withText:(NSMutableDictionary **)text withLevel:(NSMutableDictionary **)level andWithSubsection:(NSMutableDictionary **)ss
{
    int ret;
    NSString *line;
    NSRange haveText;
    NSRange error;
    NSRange subsection;
    NSRange type;
    long i;
    NSString *item;
    NSArray *types;
    
    *text = [NSMutableDictionary dictionary];
    *level = [NSMutableDictionary dictionary];
    *ss = [NSMutableDictionary dictionary];
    types = @[@"DEBUG", @"INFO", @"WARNING", @"MAJOR", @"MINOR", @"PANIC"];
    [dst updateFileSize];
    ret = 1;
    
    while(ret == 1)
    {
        line = [dst readLine:&ret];
        if(ret != 1)
            continue;
        
        subsection = [line rangeOfString:@"subsection"];
        error = [line rangeOfString:@"error"];
        haveText = [line rangeOfString:@"text"];
        
        i = 0;
        for(item in types)
        {
            type = [line rangeOfString:item];
            if (type.location != NSNotFound)
            {
                if (subsection.location != NSNotFound)
                {
                    (*ss)[item] = @"has";
                }
                else if (error.location != NSNotFound)
                {
                    (*level)[item] = @"has";
                }
                else if (haveText.location != NSNotFound)
                {
                    (*text)[item] = @"has";
                }
            }
        }
    }
}

- (void)configLogWithLogFile:(NSString **)logFile
{

    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString *cfgName = [thisBundle pathForResource:@"log-test" ofType:@"conf"];
    UMConfig *cfg = [[UMConfig alloc] initWithFileName:cfgName];
    [cfg allowSingleGroup:@"core"];
    [cfg read];

    NSDictionary *grp = [cfg getSingleGroup:@"core"];
    if (!grp)
    {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group core"userInfo:@{@"backtrace": UMBacktrace(NULL,0) }];
    }
    *logFile = grp[@"log-file"];
}

- (void)testLog
{
    UMLogFile *dst;
    UMLogHandler *handler;
    UMLogFeed *logFeed;
    NSString *logFile;
    NSMutableDictionary *text;
    NSMutableDictionary *level;
    NSMutableDictionary *ss;
    NSString *item;
    NSArray *types;
    
    @autoreleasepool
    {
        types = @[@"DEBUG", @"INFO", @"WARNING", @"MAJOR", @"MINOR", @"PANIC"];
        
        [self configLogWithLogFile:&logFile];
        
        handler = [[UMLogHandler alloc] initWithConsole];
        XCTAssertNotNil(handler, @"Log handler was not allocated properly");
        dst = [[UMLogFile alloc] initWithFileName:logFile andSeparator:@"\r\n"];
        XCTAssertNotNil(dst, @"Log file reader was not allocated properly");
        logFeed = [UMLogFile setLogHandler:handler 
                                     withName:@"Universal tests" 
                                  withSection:@"ulib tests" 
                               withSubsection:@"UMLogFeed test"
                               andWithLogFile:dst];
        XCTAssertNotNil(logFeed, @"log feeder was not allocated properly");
        
        [self.logFeed debug:0 withText:@"log item with error\r\n"];
        [self.logFeed info:0	withText:@"log item with error\r\n"];
        [self.logFeed warning:0 withText:@"log item with error\r\n"];
        [self.logFeed minorError:0 withText:@"log item with error\r\n"];
        [self.logFeed majorError:0 withText:@"log item with error\r\n"];
        [self.logFeed panic:0 withText:@"log item with error\r\n"];
        
        [self.logFeed debug:0 inSubsection:@"UMLogFeed test" withText:@"log item with subsection\r\n"];
        [self.logFeed info:0 inSubsection:@"UMLogFeed test" withText:@"log item with subsection\r\n"];
        [self.logFeed warning:0 inSubsection:@"UMLogFeed test" withText:@"log item with subsection\r\n"];
        [self.logFeed minorError:0 inSubsection:@"UMLogFeed test" withText:@"log item with subsection\r\n"];
        [self.logFeed majorError:0 inSubsection:@"UMLogFeed test" withText:@"log item with subsection\r\n"];
        [self.logFeed panic:0 inSubsection:@"UMLogFeed test" withText:@"log item with subsection\r\n"];
        
        [self.logFeed debugText:@"log item with text\r\n"];
        [self.logFeed infoText:@"log item with text\r\n"];
        [self.logFeed warningText:@"log item with text\r\n"];
        [self.logFeed minorErrorText:@"log item with text\r\n"];
        [self.logFeed majorErrorText:@"log item with text\r\n"];
        [self.logFeed panicText:@"log item with text\r\n"];
        
        [TestUMLogFeed messagesInLogFile:dst withText:&text withLevel:&level andWithSubsection:&ss];
        XCTAssertTrue([text count] == 6, @"we logged 6 different levels log messages");
        XCTAssertTrue([text count] == [level count], @"log message types have same amount of levels");
        XCTAssertTrue([ss count] == [level count], @"log message types have same amount of levels");
        
        for (item in types)
        {
            XCTAssertNotNil(text[item], @"debugText did not log at level %@", item);
            XCTAssertNotNil(level[item], @"level:withText: not log at level %@", item);
            XCTAssertNotNil(level[item], @"level:subsection:withText: not log at level %@", item);
        }
        
        [dst emptyLog];
        [dst closeLog];
        [dst removeLog];
    
    }
}

@end
