//
//  UMJSonStreamParserAccumulator.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMJsonStreamParserAccumulator.h"

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
