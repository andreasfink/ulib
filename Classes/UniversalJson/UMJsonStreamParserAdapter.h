//
//  UMJSonStreamParserAdapter.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "UMJsonStreamParser.h"
#import "UMObject.h"

typedef enum
{
	UMJsonStreamParserAdapterNone,
	UMJsonStreamParserAdapterArray,
	UMJsonStreamParserAdapterObject,
} UMJsonStreamParserAdapterType;


@protocol UMJsonStreamParserAdapterDelegate
- (void)parser:(UMJsonStreamParser*)parser foundArray:(NSArray*)array;
- (void)parser:(UMJsonStreamParser*)parser foundObject:(NSDictionary*)dict;
@end


@interface UMJsonStreamParserAdapter : UMObject <UMJsonStreamParserDelegate>
{
@private
	NSUInteger depth;
    NSMutableArray *array;
	NSMutableDictionary *dict;
	NSMutableArray *keyStack;
	NSMutableArray *stack;	
	UMJsonStreamParserAdapterType currentType;
    NSUInteger levelsToSkip;
    id<UMJsonStreamParserAdapterDelegate> __unsafe_unretained delegate;
}

@property (readwrite,assign) NSUInteger levelsToSkip;
@property (readwrite,unsafe_unretained) id<UMJsonStreamParserAdapterDelegate> delegate;

@end
