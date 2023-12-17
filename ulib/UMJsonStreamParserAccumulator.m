//
//  UMJSonStreamParserAccumulator.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMJsonStreamParserAccumulator.h>

@implementation UMJsonStreamParserAccumulator

@synthesize value;


#pragma mark UMJsonStreamParserAdapterDelegate

- (void)parser:(UMJsonStreamParser*)parser foundArray:(NSArray *)array
{
	value = array;
}

- (void)parser:(UMJsonStreamParser*)parser foundObject:(NSDictionary *)dict
{
	value = dict;
}

@end
