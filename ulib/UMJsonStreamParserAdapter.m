//
//  UMJSonStreamParserAdapter.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <ulib/UMJsonStreamParserAdapter.h>

@interface UMJsonStreamParserAdapter ()

- (void)pop;
- (void)parser:(UMJsonStreamParser*)parser found:(id)obj;

@end



@implementation UMJsonStreamParserAdapter

@synthesize delegate;
@synthesize levelsToSkip;

#pragma mark Housekeeping

- (id)init
{
    self = [super init];
    if(self)
	{
		keyStack = [[NSMutableArray alloc] initWithCapacity:32];
		stack = [[NSMutableArray alloc] initWithCapacity:32];
		
		currentType = UMJsonStreamParserAdapterNone;
	}
	return self;
}	


#pragma mark Private methods

- (void)pop
{
	[stack removeLastObject];
	array = nil;
	dict = nil;
	currentType = UMJsonStreamParserAdapterNone;
	
	id value = [stack lastObject];
	
	if ([value isKindOfClass:[NSArray class]])
    {
		array = value;
		currentType = UMJsonStreamParserAdapterArray;
	}
    else if ([value isKindOfClass:[NSDictionary class]])
    {
		dict = value;
		currentType = UMJsonStreamParserAdapterObject;
	}
}

- (void)parser:(UMJsonStreamParser*)parser found:(id)obj
{
	NSParameterAssert(obj);
	
	switch (currentType)
    {
		case UMJsonStreamParserAdapterArray:
			[array addObject:obj];
			break;

		case UMJsonStreamParserAdapterObject:
			NSParameterAssert(keyStack.count);
            [dict setObject:obj forKey:[keyStack lastObject]];
			[keyStack removeLastObject];
			break;
			
		case UMJsonStreamParserAdapterNone:
			if ([obj isKindOfClass:[NSArray class]])
            {
				[delegate parser:parser foundArray:obj];
			}
            else
            {
				[delegate parser:parser foundObject:obj];
			}				
			break;

		default:
			break;
	}
}

- (void)parserFoundObjectStart:(UMJsonStreamParser*)parser
{
	if (++depth > self.levelsToSkip)
    {
		dict = [NSMutableDictionary new];
		[stack addObject:dict];
		currentType = UMJsonStreamParserAdapterObject;
	}
}

- (void)parser:(UMJsonStreamParser*)parser foundObjectKey:(NSString*)key_
{
	[keyStack addObject:key_];
}

- (void)parserFoundObjectEnd:(UMJsonStreamParser*)parser
{
	if (depth-- > self.levelsToSkip)
    {
		id value = dict;
		[self pop];
		[self parser:parser found:value];
	}
}

- (void)parserFoundArrayStart:(UMJsonStreamParser*)parser
{
	if (++depth > self.levelsToSkip)
    {
		array = [NSMutableArray new];
		[stack addObject:array];
		currentType = UMJsonStreamParserAdapterArray;
	}
}

- (void)parserFoundArrayEnd:(UMJsonStreamParser*)parser
{
	if (depth-- > self.levelsToSkip)
    {
		id value = array;
		[self pop];
		[self parser:parser found:value];
	}
}

- (void)parser:(UMJsonStreamParser*)parser foundBoolean:(BOOL)x
{
	[self parser:parser found:@(x)];
}

- (void)parserFoundNull:(UMJsonStreamParser*)parser
{
	[self parser:parser found:[NSNull null]];
}

- (void)parser:(UMJsonStreamParser*)parser foundNumber:(NSNumber*)num
{
	[self parser:parser found:num];
}

- (void)parser:(UMJsonStreamParser*)parser foundString:(NSString*)string
{
	[self parser:parser found:string];
}

@end
