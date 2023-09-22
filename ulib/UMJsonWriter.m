//
//  UMJSonWriter.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//


#import <ulib/UMJsonWriter.h>
#import <ulib/UMJsonStreamWriter.h>
#import <ulib/UMJsonStreamWriterAccumulator.h>
#import <ulib/UMSynchronizedSortedDictionary.h>
#import <ulib/UMSynchronizedDictionary.h>
#import <ulib/UMSynchronizedArray.h>

@implementation UMJsonWriter

@synthesize sortKeys;
@synthesize humanReadable;

@synthesize error;
@synthesize maxDepth;

@synthesize sortKeysSelector;
//@synthesize sortKeysComparator;

- (id)init
{
    self = [super init];
    if(self)
    {
        self.maxDepth = 32u;        
    }
    return self;
}


- (NSString*)stringWithObject:(id)value
{
	NSData *data = [self dataWithObject:value];
	if (data)
    {
		return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
	return nil;
}	

- (NSString*)stringWithObject:(id)value error:(NSError**)error_
{
    NSString *tmp = [self stringWithObject:value];
    if (tmp)
    {
        return tmp;
    }
    if (error_)
    {
		NSDictionary *ui = @{NSLocalizedDescriptionKey: error};
        *error_ = [NSError errorWithDomain:@"me.fink.umjson.parser" code:0 userInfo:ui];
	}
	
    return nil;
}

- (NSData*)dataWithObject:(id)object
{
    self.error = nil;

    UMJsonStreamWriterAccumulator *accumulator = [[UMJsonStreamWriterAccumulator alloc] init];    
	UMJsonStreamWriter *streamWriter = [[UMJsonStreamWriter alloc] init];
	streamWriter.sortKeys = self.sortKeys;
	streamWriter.maxDepth = self.maxDepth;
	streamWriter.sortKeysSelector = self.sortKeysSelector;
	streamWriter.humanReadable = self.humanReadable;
    streamWriter.delegate = accumulator;
    streamWriter.useJavaScriptKeyNames = self.useJavaScriptKeyNames;
	BOOL ok = NO;
    if ([object isKindOfClass:[NSString class]])
    {
        ok = [streamWriter writeString:object];
    }
	else if ([object isKindOfClass:[UMSynchronizedSortedDictionary class]])
    {
		ok = [streamWriter writeSortedDictionary:object];
	}
    else if ([object isKindOfClass:[UMSynchronizedDictionary class]])
    {
        ok = [streamWriter writeObject:[object mutableCopy]];
    }
    else if ([object isKindOfClass:[UMSynchronizedArray class]])
    {
        ok = [streamWriter writeObject:[object mutableCopy]];
    }
    else if ([object isKindOfClass:[NSDictionary class]])
    {
        ok = [streamWriter writeObject:object];
    }
	else if ([object isKindOfClass:[NSArray class]])
	{
        ok = [streamWriter writeArray:object];
    }
    else if ([object isKindOfClass:[NSNumber class]])
    {
        ok = [streamWriter writeNumber:object];
    }
	else if ([object respondsToSelector:@selector(proxyForJson)])
    {
		return [self dataWithObject:[object proxyForJson]];
	}
    else
    {
		self.error = @"Not valid type for JSON";
		return nil;
	}
	
	if (ok)
	{
        return accumulator.data;
	}
	self.error = streamWriter.error;
	return nil;	
}
	
	
@end
