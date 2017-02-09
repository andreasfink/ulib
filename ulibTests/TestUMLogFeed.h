//
//  TestUMLogFeed.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UMTestCase.h"

@class UMLogFile;

@interface TestUMLogFeed : XCTestCase
{
}

+ (void) messagesInLogFile:(UMLogFile *)dst withText:(NSMutableDictionary **)text withLevel:(NSMutableDictionary **)level andWithSubsection:(NSMutableDictionary **)ss;


@end
