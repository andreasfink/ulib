//
//  TestUMLogFeed.h
//  ulib
//
//  Created by Aarno Syvänen on 20.04.12.
//  Copyright (c) 2012 Aliosanus GmbH. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UMTestCase.h"

@class UMLogFile;

@interface TestUMLogFeed : XCTestCase
{
}

+ (void) messagesInLogFile:(UMLogFile *)dst withText:(NSMutableDictionary **)text withLevel:(NSMutableDictionary **)level andWithSubsection:(NSMutableDictionary **)ss;


@end
