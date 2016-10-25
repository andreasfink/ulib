//
//  NSArray+UMJson.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "NSArray+UMJson.h"
#import "UMJsonWriter.h"
#import "UMJsonParser.h"

@implementation NSArray(UMJson)

- (NSString *)jsonString;
{
    UMJsonWriter *writer = [[UMJsonWriter alloc] init];
    NSString *json = [writer stringWithObject:self];
    if (!json)
    {
        NSLog(@"jsonString encoding failed. Error is: %@", writer.error);
    }
    return json;
}

@end
