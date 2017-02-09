//
//  UMJsonParser.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMJsonParser.h"
#import "UMJsonStreamParser.h"
#import "UMJsonStreamParserAdapter.h"
#import "UMJsonStreamParserAccumulator.h"

@implementation UMJsonParser

@synthesize maxDepth;
@synthesize error;

- (id)init
{
    self = [super init];
    if(self)
	{
        self.maxDepth = 32u;
    }
    return self;
}



- (id)objectWithData:(NSData *)data
{
    if (!data)
    {
        self.error = @"Input was 'nil'";
        return nil;
    }
    if([data length]==0)
    {
        self.error = @"Input was length 0";
        return nil;
    }
	UMJsonStreamParserAccumulator *accumulator = [[UMJsonStreamParserAccumulator alloc] init];
    UMJsonStreamParserAdapter *adapter = [[UMJsonStreamParserAdapter alloc] init];
    [adapter setDelegate:accumulator];
	UMJsonStreamParser *parser = [[UMJsonStreamParser alloc] init];
	parser.maxDepth = self.maxDepth;
	parser.delegate = adapter;
	switch ([parser parse:data])
    {
		case UMJsonStreamParserComplete:
            return accumulator.value;
			break;
			
		case UMJsonStreamParserWaitingForData:
		    self.error = @"Unexpected end of input";
			break;

		case UMJsonStreamParserError:
		    self.error = parser.error;
			break;
	}
	return nil;
}

- (id)objectWithString:(NSString *)repr
{
	return [self objectWithData:[repr dataUsingEncoding:NSUTF8StringEncoding]];
}

- (id)objectWithString:(NSString*)repr error:(NSError**)err
{
	id tmp = [self objectWithString:repr];
    if (tmp)
    {
        return tmp;
    }
    if (err)
    {
		NSDictionary *ui = @{NSLocalizedDescriptionKey: error};
        *err = [NSError errorWithDomain:@"me.fink.json.umparser" code:0 userInfo:ui];
	}
	
    return nil;
}

@end
