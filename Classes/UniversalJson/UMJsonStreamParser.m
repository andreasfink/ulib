//
//  UMJsonParser.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import "UMAssert.h"
#import "UMJsonStreamParser.h"
#import "UMJsonTokeniser.h"
#import "UMJsonStreamParserState.h"

@implementation UMJsonStreamParser

@synthesize supportMultipleDocuments;
@synthesize error;
@synthesize delegate;
@synthesize maxDepth;
@synthesize state;
@synthesize stateStack;


- (id)init
{
    self = [super init];
    if(self)
	{
		maxDepth = 32u;
        stateStack = [[NSMutableArray alloc] initWithCapacity:maxDepth];
        state = [UMJsonStreamParserStateStart sharedInstance];
		tokeniser = [[UMJsonTokeniser alloc] init];
	}
	return self;
}


#pragma mark Methods

- (NSString*)tokenName:(UMjson_token_t)token
{
	switch (token)
    {
		case UMjson_token_array_start:
			return @"start of array";
			break;

		case UMjson_token_array_end:
			return @"end of array";
			break;

		case UMjson_token_number:
			return @"number";
			break;

		case UMjson_token_string:
			return @"string";
			break;

		case UMjson_token_true:
		case UMjson_token_false:
			return @"boolean";
			break;

		case UMjson_token_null:
			return @"null";
			break;

		case UMjson_token_keyval_separator:
			return @"key-value separator";
			break;

		case UMjson_token_separator:
			return @"value separator";
			break;

		case UMjson_token_object_start:
			return @"start of object";
			break;

		case UMjson_token_object_end:
			return @"end of object";
			break;

		case UMjson_token_eof:
		case UMjson_token_error:
			break;
	}
	UMAssert(NO, @"Should not get here");
	return @"<help!>";
}

- (void)maxDepthError
{
    self.error = [NSString stringWithFormat:@"Input depth exceeds max depth of %lu", (unsigned long)maxDepth];
    self.state = [UMJsonStreamParserStateError sharedInstance];
}

- (void)handleObjectStart
{
	if (stateStack.count >= maxDepth)
    {
        [self maxDepthError];
        return;
	}

    [delegate parserFoundObjectStart:self];
    [stateStack addObject:state];
    self.state = [UMJsonStreamParserStateObjectStart sharedInstance];
}

- (void)handleObjectEnd: (UMjson_token_t) tok
{
    self.state = [stateStack lastObject];
    [stateStack removeLastObject];
    [state parser:self shouldTransitionTo:tok];
    [delegate parserFoundObjectEnd:self];
}

- (void)handleArrayStart
{
	if (stateStack.count >= maxDepth)
    {
        [self maxDepthError];
        return;
    }
	
	[delegate parserFoundArrayStart:self];
    [stateStack addObject:state];
    self.state = [UMJsonStreamParserStateArrayStart sharedInstance];
}

- (void)handleArrayEnd: (UMjson_token_t) tok
{
    self.state = [stateStack lastObject];
    [stateStack removeLastObject];
    [state parser:self shouldTransitionTo:tok];
    [delegate parserFoundArrayEnd:self];
}

- (void) handleTokenNotExpectedHere: (UMjson_token_t) tok
{
    NSString *tokenName = [self tokenName:tok];
    NSString *stateName = [state name];

    self.error = [NSString stringWithFormat:@"Token '%@' is not expected %@", tokenName, stateName];
    self.state = [UMJsonStreamParserStateError sharedInstance];
}

- (UMJsonStreamParserStatus)parse:(NSData *)data_
{
    @autoreleasepool
    {
        
        [tokeniser appendData:data_];
        
        for (;;)
        {
            
            if ([state isError])
                return UMJsonStreamParserError;
            
            NSObject *token;
            UMjson_token_t tok = [tokeniser getToken:&token];
            switch (tok)
            {
                case UMjson_token_eof:
                    return [state parserShouldReturn:self];
                    break;
                    
                case UMjson_token_error:
                    self.state = [UMJsonStreamParserStateError sharedInstance];
                    self.error = tokeniser.error;
                    return UMJsonStreamParserError;
                    break;
                    
                default:
                    
                    if (![state parser:self shouldAcceptToken:tok])
                    {
                        [self handleTokenNotExpectedHere: tok];
                        return UMJsonStreamParserError;
                    }
                    
                    switch (tok)
                {
                    case UMjson_token_object_start:
                        [self handleObjectStart];
                        break;
                        
                    case UMjson_token_object_end:
                        [self handleObjectEnd: tok];
                        break;
                        
                    case UMjson_token_array_start:
                        [self handleArrayStart];
                        break;
                        
                    case UMjson_token_array_end:
                        [self handleArrayEnd: tok];
                        break;
                        
                    case UMjson_token_separator:
                    case UMjson_token_keyval_separator:
                        [state parser:self shouldTransitionTo:tok];
                        break;
                        
                    case UMjson_token_true:
                        [delegate parser:self foundBoolean:YES];
                        [state parser:self shouldTransitionTo:tok];
                        break;
                        
                    case UMjson_token_false:
                        [delegate parser:self foundBoolean:NO];
                        [state parser:self shouldTransitionTo:tok];
                        break;
                        
                    case UMjson_token_null:
                        [delegate parserFoundNull:self];
                        [state parser:self shouldTransitionTo:tok];
                        break;
                        
                    case UMjson_token_number:
                        [delegate parser:self foundNumber:(NSNumber*)token];
                        [state parser:self shouldTransitionTo:tok];
                        break;
                        
                    case UMjson_token_string:
                        if ([state needKey])
                        {
                            [delegate parser:self foundObjectKey:(NSString*)token];
                        }
                        else
                        {
                            [delegate parser:self foundString:(NSString*)token];
                        }
                        [state parser:self shouldTransitionTo:tok];
                        break;
                        
                    default:
                        break;
                }
                    break;
            }
        }
    }    
    return UMJsonStreamParserComplete;
}

@end
