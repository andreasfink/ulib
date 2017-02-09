//
//  UMTestCase.m
//  ulib
//
//  Created by Aarno Syvänen on 20.04.12.
//  //  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMTestCase.h"
#import "ulib/UMLogEntry.h"

@implementation NSData (UMFileReaderAdditions)
@end

@implementation UMTestHandler

- (long)LogAnEntryAndGiveSize:(UMLogEntry *)logEntry
{
    NSString *s;
    NSData *data;
	
	s = [logEntry description];
    data = [s dataUsingEncoding:NSUTF8StringEncoding];
    
    [super logAnEntry:logEntry];
    
    return [data length];
}

@end

