//
//  UMJSonStreamParserState.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//

#import "UMJsonStreamParserState.h"

#
@implementation UMJsonStreamParserState

+ (id)sharedInstance
{
    return nil;
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	return NO;
}

- (UMJsonStreamParserStatus)parserShouldReturn:(UMJsonStreamParser*)parser
{
	return UMJsonStreamParserWaitingForData;
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
}

- (BOOL)needKey
{
	return NO;
}

- (NSString*)name
{
	return @"<help!!>";
}

- (BOOL)isError
{
    return NO;
}

@end


@implementation UMJsonStreamParserStateStart

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	return token == UMjson_token_array_start || token == UMjson_token_object_start;
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{

	UMJsonStreamParserState *state = nil;
	switch (tok) {
		case UMjson_token_array_start:
			state = [UMJsonStreamParserStateArrayStart sharedInstance];
			break;

		case UMjson_token_object_start:
			state = [UMJsonStreamParserStateObjectStart sharedInstance];
			break;

		case UMjson_token_array_end:
		case UMjson_token_object_end:
			if (parser.supportMultipleDocuments)
				state = parser.state;
			else
				state = [UMJsonStreamParserStateComplete sharedInstance];
			break;

		case UMjson_token_eof:
			return;

		default:
			state = [UMJsonStreamParserStateError sharedInstance];
			break;
	}


	parser.state = state;
}

- (NSString*)name
{
    return @"before outer-most array or object";
}

@end

#pragma mark -

@implementation UMJsonStreamParserStateComplete

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"after outer-most array or object";
}

- (UMJsonStreamParserStatus)parserShouldReturn:(UMJsonStreamParser*)parser
{
	return UMJsonStreamParserComplete;
}

@end

@implementation UMJsonStreamParserStateError

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"in error";
}

- (UMJsonStreamParserStatus)parserShouldReturn:(UMJsonStreamParser*)parser
{
	return UMJsonStreamParserError;
}

- (BOOL)isError
{
    return YES;
}

@end


@implementation UMJsonStreamParserStateObjectStart

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}


- (NSString*)name
{
    return @"at beginning of object";
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	switch (token)
    {
		case UMjson_token_object_end:
		case UMjson_token_string:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	parser.state = [UMJsonStreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey
{
	return YES;
}

@end


@implementation UMJsonStreamParserStateObjectGotKey

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}


- (NSString*)name
{
    return @"after object key";
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	return token == UMjson_token_keyval_separator;
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	parser.state = [UMJsonStreamParserStateObjectSeparator sharedInstance];
}

@end

@implementation UMJsonStreamParserStateObjectSeparator

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"as object value";
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	switch (token)
    {
		case UMjson_token_object_start:
		case UMjson_token_array_start:
		case UMjson_token_true:
		case UMjson_token_false:
		case UMjson_token_null:
		case UMjson_token_number:
		case UMjson_token_string:
			return YES;
			break;

		default:
			return NO;
			break;
	}
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	parser.state = [UMJsonStreamParserStateObjectGotValue sharedInstance];
}

@end

@implementation UMJsonStreamParserStateObjectGotValue

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"after object value";
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	switch (token)
    {
		case UMjson_token_object_end:
		case UMjson_token_separator:
			return YES;
			break;
		default:
			return NO;
			break;
	}
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	parser.state = [UMJsonStreamParserStateObjectNeedKey sharedInstance];
}


@end


@implementation UMJsonStreamParserStateObjectNeedKey

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"in place of object key";
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
    return UMjson_token_string == token;
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	parser.state = [UMJsonStreamParserStateObjectGotKey sharedInstance];
}

- (BOOL)needKey
{
	return YES;
}

@end

@implementation UMJsonStreamParserStateArrayStart

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"at array start";
}

- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	switch (token)
    {
		case UMjson_token_object_end:
		case UMjson_token_keyval_separator:
		case UMjson_token_separator:
			return NO;
			break;

		default:
			return YES;
			break;
	}
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	parser.state = [UMJsonStreamParserStateArrayGotValue sharedInstance];
}

@end

@implementation UMJsonStreamParserStateArrayGotValue

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"after array value";
}


- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	return token == UMjson_token_array_end || token == UMjson_token_separator;
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	if (tok == UMjson_token_separator)
    {
        parser.state = [UMJsonStreamParserStateArrayNeedValue sharedInstance];
    }
}

@end


@implementation UMJsonStreamParserStateArrayNeedValue

+ (id)sharedInstance
{ 
    static id state = nil;
    if (!state)
    {
        @synchronized(self)
        {
            if (!state)
            {
                state = [[self alloc] init];
            }
        }
    }
    return state;
}

- (NSString*)name
{
    return @"as array value";
}


- (BOOL)parser:(UMJsonStreamParser*)parser shouldAcceptToken:(UMjson_token_t)token
{
	switch (token)
    {
		case UMjson_token_array_end:
		case UMjson_token_keyval_separator:
		case UMjson_token_object_end:
		case UMjson_token_separator:
			return NO;
			break;

		default:
			return YES;
			break;
	}
}

- (void)parser:(UMJsonStreamParser*)parser shouldTransitionTo:(UMjson_token_t)tok
{
	parser.state = [UMJsonStreamParserStateArrayGotValue sharedInstance];
}

@end

