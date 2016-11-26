
//
//  UMJSonStreamWriterState.m
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//
//


#import "UMJsonStreamWriterState.h"
#import "UMJsonStreamWriter.h"


@implementation UMJsonStreamWriterState
+ (id)sharedInstance
{
    return nil;
}


- (UMJsonStreamWriterState *)init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}

- (BOOL)isInvalidState:(UMJsonStreamWriter*)writer
{
    return NO;
}

- (void)appendSeparator:(UMJsonStreamWriter*)writer
{
}

- (BOOL)expectingKey:(UMJsonStreamWriter*)writer
{
    return NO;
}

- (void)transitionState:(UMJsonStreamWriter *)writer
{
}

- (void)appendWhitespace:(UMJsonStreamWriter*)writer
{
	[writer appendBytes:"\n" length:1];
	NSUInteger i = 0;
	for (i = 0; i < writer.stateStack.count; i++)
    {
	    [writer appendBytes:"  " length:2];
    }
}
@end

@implementation UMJsonStreamWriterStateObjectStart

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

- (void)transitionState:(UMJsonStreamWriter *)writer
{
	writer.state = [UMJsonStreamWriterStateObjectValue sharedInstance];
}
- (BOOL)expectingKey:(UMJsonStreamWriter *)writer
{
	writer.error = @"JSON object key must be string";
	return YES;
}
@end

@implementation UMJsonStreamWriterStateObjectKey

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


- (void)appendSeparator:(UMJsonStreamWriter *)writer
{
	[writer appendBytes:"," length:1];
}
@end

@implementation UMJsonStreamWriterStateObjectValue

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


- (void)appendSeparator:(UMJsonStreamWriter *)writer
{
	[writer appendBytes:":" length:1];
}
- (void)transitionState:(UMJsonStreamWriter *)writer
{
    writer.state = [UMJsonStreamWriterStateObjectKey sharedInstance];
}
- (void)appendWhitespace:(UMJsonStreamWriter *)writer
{
	[writer appendBytes:" " length:1];
}
@end

@implementation UMJsonStreamWriterStateArrayStart

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


- (void)transitionState:(UMJsonStreamWriter *)writer
{
    writer.state = [UMJsonStreamWriterStateArrayValue sharedInstance];
}
@end

@implementation UMJsonStreamWriterStateArrayValue

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


- (void)appendSeparator:(UMJsonStreamWriter *)writer
{
	[writer appendBytes:"," length:1];
}
@end

@implementation UMJsonStreamWriterStateStart

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

- (UMJsonStreamWriterStateStart *)init
{
    self = [super init];
    if(self)
    {
        
    }
    return self;
}

- (void)transitionState:(UMJsonStreamWriter *)writer
{
    writer.state = [UMJsonStreamWriterStateComplete sharedInstance];
}

- (void)appendSeparator:(UMJsonStreamWriter *)writer
{

}
@end

@implementation UMJsonStreamWriterStateComplete

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


- (BOOL)isInvalidState:(UMJsonStreamWriter*)writer
{
	writer.error = @"Stream is closed";
	return YES;
}
@end

@implementation UMJsonStreamWriterStateError

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


@end

