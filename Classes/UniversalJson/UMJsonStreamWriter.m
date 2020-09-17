//
//  UMJSonStreamWriter.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//
//


#import "UMJsonStreamWriter.h"
#import "UMJsonStreamWriterState.h"
#import "NSDate+stringFunctions.h"
#import "NSData+UniversalObject.h"
#import "UMSynchronizedSortedDictionary.h"
#import "UMSynchronizedDictionary.h"
#import "UMSynchronizedArray.h"

static NSNumber *kNotANumber;
static NSNumber *kTrue;
static NSNumber *kFalse;
static NSNumber *kPositiveInfinity;
static NSNumber *kNegativeInfinity;


@implementation UMJsonStreamWriter

@synthesize error;
@synthesize maxDepth;
@synthesize state;
@synthesize stateStack;
@synthesize humanReadable;
@synthesize sortKeys;
@synthesize sortKeysSelector;

+ (void)initialize
{
	kNotANumber = [NSDecimalNumber notANumber];
    kPositiveInfinity = @(+HUGE_VAL);
    kNegativeInfinity = @(-HUGE_VAL);
    kTrue = @YES;
    kFalse = @NO;
}

@synthesize delegate;

- (id)init
{
    self = [super init];
    if(self)
	{
		maxDepth = 32u;
        stateStack = [[NSMutableArray alloc] initWithCapacity:maxDepth];
        state = [UMJsonStreamWriterStateStart sharedInstance];
        cache = [[NSMutableDictionary alloc] initWithCapacity:32];
    }
	return self;
}

- (void)appendBytes:(const void *)bytes length:(NSUInteger)length
{
    [delegate writer:self appendBytes:bytes length:length];
}

- (BOOL)writeObject:(NSDictionary *)dict
{
	if (![self writeObjectOpen])
    {
		return NO;
    }
	NSArray *keys = [dict allKeys];
	
	if (sortKeys)
    {
		if (sortKeysSelector)
        {
            keys = [keys sortedArrayUsingSelector:sortKeysSelector];
		}
		else
        {
			keys = [keys sortedArrayUsingSelector:@selector(compare:)];
		}
	}

	for (id k in keys)
    {
		if (![k isKindOfClass:[NSString class]])
        {
			self.error = [NSString stringWithFormat:@"JSON object key must be string: %@", k];
			return NO;
		}

        if(_useJavaScriptKeyNames)
        {
            if (![self writeKeyName:k])
            {
                return NO;
            }
        }
        else
        {
            if (![self writeString:k])
            {
                return NO;
            }
        }
		if (![self writeValue:[dict objectForKey:k]])
        {
			return NO;
        }
	}
	return [self writeObjectClose];
}

- (BOOL)writeArray:(NSArray*)array
{
	if (![self writeArrayOpen])
    {
		return NO;
    }
    for (id v in array)
    {
        if (![self writeValue:v])
        {
			return NO;
        }
    }
	return [self writeArrayClose];
}

- (BOOL)writeSynchronizedArray:(UMSynchronizedArray *)array
{
    return [self writeArray:[array mutableCopy]];
}

- (BOOL)writeSortedDictionary:(UMSynchronizedSortedDictionary *)dict
{
    if (![self writeObjectOpen])
    {
        return NO;
    }

    NSArray *keys = [dict sortedKeys];
    
    for (id k in keys)
    {
        if (![k isKindOfClass:[NSString class]])
        {
            self.error = [NSString stringWithFormat:@"JSON object key must be string: %@", k];
            return NO;
        }
        
        if (![self writeString:k])
        {
            return NO;
        }
        if (![self writeValue:dict[k]])
        {
            return NO;
        }
    }
    
    return [self writeObjectClose];
}

- (BOOL)writeSynchronizedDictionary:(UMSynchronizedDictionary *)dict
{
    return [self writeObject:[dict mutableCopy]];
}

- (BOOL)writeObjectOpen
{
	if ([state isInvalidState:self])
    {
        return NO;
    }
	if ([state expectingKey:self])
    {
        return NO;
    }
	[state appendSeparator:self];
	if (humanReadable && stateStack.count)
    {
        [state appendWhitespace:self];
    }
    [stateStack addObject:state];
    self.state = [UMJsonStreamWriterStateObjectStart sharedInstance];
	if (maxDepth && stateStack.count > maxDepth)
    {
		self.error = @"Nested too deep";
		return NO;
	}

	[delegate writer:self appendBytes:"{" length:1];
	return YES;
}

- (BOOL)writeObjectClose
{
	if ([state isInvalidState:self])
    {
        return NO;
    }
    UMJsonStreamWriterState *prev = state;

    self.state = [stateStack lastObject];
    [stateStack removeLastObject];

	if (humanReadable)
    {
        [prev appendWhitespace:self];
    }
	[delegate writer:self appendBytes:"}" length:1];

	[state transitionState:self];
	return YES;
}

- (BOOL)writeArrayOpen
{
    if ([state isInvalidState:self])
    {
        return NO;
    }
	if ([state expectingKey:self])
    {
        return NO;
    };
	[state appendSeparator:self];
	if (humanReadable && stateStack.count) [state appendWhitespace:self];

    [stateStack addObject:state];
	self.state = [UMJsonStreamWriterStateArrayStart sharedInstance];

	if (maxDepth && stateStack.count > maxDepth)
    {
		self.error = @"Nested too deep";
		return NO;
	}

	[delegate writer:self appendBytes:"[" length:1];
	return YES;
}

- (BOOL)writeArrayClose
{
	if ([state isInvalidState:self])
    {
        return NO;
    }
	if ([state expectingKey:self])
    {
        return NO;
    }

    UMJsonStreamWriterState *prev = state;

    self.state = [stateStack lastObject];
    [stateStack removeLastObject];

	if (humanReadable) [prev appendWhitespace:self];
	[delegate writer:self appendBytes:"]" length:1];

	[state transitionState:self];
	return YES;
}

- (BOOL)writeNull
{
	if ([state isInvalidState:self])
    {
        return NO;
    }
    if ([state expectingKey:self])
    {
        return NO;
    }
	[state appendSeparator:self];
	if (humanReadable) [state appendWhitespace:self];

	[delegate writer:self appendBytes:"null" length:4];
	[state transitionState:self];
	return YES;
}

- (BOOL)writeBool:(BOOL)x {
    if ([state isInvalidState:self])
    {
        return NO;
    }
    if ([state expectingKey:self])
    {
        return NO;
    }
	[state appendSeparator:self];
	if (humanReadable) [state appendWhitespace:self];

	if (x)
		[delegate writer:self appendBytes:"true" length:4];
	else
		[delegate writer:self appendBytes:"false" length:5];
	[state transitionState:self];
	return YES;
}


- (BOOL)writeValue:(id)o
{
    if(o==NULL)
    {
        self.error = [NSString stringWithFormat:@"JSON serialisation not supported. can not write NULL"];
        return NO;
    }
    else if ([o isKindOfClass:[UMSynchronizedSortedDictionary class]])
    {
        return [self writeSortedDictionary:o];
    }
    else if ([o isKindOfClass:[UMSynchronizedDictionary class]])
    {
        return [self writeObject:[o mutableCopy]];
    }
	else if ([o isKindOfClass:[NSDictionary class]])
    {
		return [self writeObject:o];
	}
    else if ([o isKindOfClass:[UMSynchronizedArray class]])
    {
        return [self writeArray:[o mutableCopy]];
    }
    else if ([o isKindOfClass:[NSArray class]])
    {
		return [self writeArray:o];
	}
    else if ([o isKindOfClass:[NSString class]])
    {
		[self writeString:o];
		return YES;
	}
    else if ([o isKindOfClass:[NSData class]])
    {
        NSData *d = (NSData *)o;
        [self writeString:[d hexString]];
        return YES;
    }
    else if ([o isKindOfClass:[NSNumber class]])
    {
		return [self writeNumber:o];
    }
    else if ([o isKindOfClass:[NSDate class]])
    {
        return [self writeDate:o];
    }
    else if ([o isKindOfClass:[NSNull class]])
    {
		return [self writeNull];
	}
    else if ([o respondsToSelector:@selector(proxyForJson)])
    {
		return [self writeValue:[o proxyForJson]];
	}
	self.error = [NSString stringWithFormat:@"JSON serialisation not supported for class '%@'. implement proxyForJson class", [o className]];
	return NO;
}

static const char *strForChar(int c)
{
	switch (c)
    {
		case 0: return "\\u0000";
            break;
		case 1: return "\\u0001";
            break;
		case 2: return "\\u0002";
            break;
		case 3: return "\\u0003";
            break;
		case 4: return "\\u0004";
            break;
		case 5: return "\\u0005";
            break;
		case 6: return "\\u0006";
            break;
		case 7: return "\\u0007";
            break;
		case 8: return "\\b";
            break;
		case 9: return "\\t";
            break;
		case 10: return "\\n";
            break;
		case 11: return "\\u000b";
            break;
		case 12: return "\\f";
            break;
		case 13: return "\\r";
            break;
		case 14: return "\\u000e";
            break;
		case 15: return "\\u000f";
            break;
		case 16: return "\\u0010";
            break;
		case 17: return "\\u0011";
            break;
		case 18: return "\\u0012";
            break;
		case 19: return "\\u0013";
            break;
		case 20: return "\\u0014";
            break;
		case 21: return "\\u0015";
            break;
		case 22: return "\\u0016";
            break;
		case 23: return "\\u0017";
            break;
		case 24: return "\\u0018";
            break;
		case 25: return "\\u0019";
            break;
		case 26: return "\\u001a";
            break;
		case 27: return "\\u001b";
            break;
		case 28: return "\\u001c";
            break;
		case 29: return "\\u001d";
            break;
		case 30: return "\\u001e";
            break;
		case 31: return "\\u001f";
            break;
		case 34: return "\\\"";
            break;
		case 92: return "\\\\";
            break;
	}
	NSLog(@"TUTTUTTUT: -->'%c'<---", c);
	return "TUTTUTTUT";
}

/* writeKeyName differs from writeString in the sense that it does not put quotes around it.
   this is to write a JavaScript object instead of a json object.

 */
- (BOOL)writeKeyName:(NSString*)string
{
    if ([state isInvalidState:self])
    {
        return NO;
    }
    [state appendSeparator:self];
    if (humanReadable)
    {
        [state appendWhitespace:self];
    }
    NSMutableData *buf = [cache objectForKey:string];
    if (!buf)
    {
        NSUInteger len = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        const char *utf8 = [string UTF8String];
        NSUInteger written = 0, i = 0;

        buf = [NSMutableData dataWithCapacity:(NSUInteger)(len * 1.1f)];
        for (i = 0; i < len; i++)
        {
            int c = utf8[i];
            BOOL isControlChar = c >= 0 && c < 32;
            if (isControlChar || c == '"' || c == '\\')
            {
                if (i - written)
                {
                    [buf appendBytes:utf8 + written length:i - written];
                }
                written = i + 1;

                const char *t = strForChar(c);
                [buf appendBytes:t length:strlen(t)];
            }
        }
        if (i - written)
        {
            [buf appendBytes:utf8 + written length:i - written];
        }
        [cache setObject:buf forKey:string];
    }

    [delegate writer:self appendBytes:[buf bytes] length:[buf length]];
    [state transitionState:self];
    return YES;
}

- (BOOL)writeString:(NSString*)string
{
	if ([state isInvalidState:self])
    {
        return NO;
    }
	[state appendSeparator:self];
	if (humanReadable)
    {
        [state appendWhitespace:self];
    }
	NSMutableData *buf = [cache objectForKey:string];
	if (!buf)
    {
        NSUInteger len = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
        const char *utf8 = [string UTF8String];
        NSUInteger written = 0, i = 0;

        buf = [NSMutableData dataWithCapacity:(NSUInteger)(len * 1.1f)];
        [buf appendBytes:"\"" length:1];

        for (i = 0; i < len; i++)
        {
            int c = utf8[i];
            BOOL isControlChar = c >= 0 && c < 32;
            if (isControlChar || c == '"' || c == '\\')
            {
                if (i - written)
                {
                    [buf appendBytes:utf8 + written length:i - written];
                }
                written = i + 1;

                const char *t = strForChar(c);
                [buf appendBytes:t length:strlen(t)];
            }
        }

        if (i - written)
        {
            [buf appendBytes:utf8 + written length:i - written];
        }
        [buf appendBytes:"\"" length:1];
        [cache setObject:buf forKey:string];
    }

	[delegate writer:self appendBytes:[buf bytes] length:[buf length]];
	[state transitionState:self];
	return YES;
}

- (BOOL)writeDate:(NSDate*)date
{
    return [self writeString:[date stringValue]];
}

- (BOOL)writeNumber:(NSNumber *)number
{
	if (number == kTrue || number == kFalse)
    {
		return [self writeBool:[number boolValue]];
    }
	if ([state isInvalidState:self]) return NO;
	if ([state expectingKey:self]) return NO;
	[state appendSeparator:self];
	if (humanReadable) [state appendWhitespace:self];

	if ([kPositiveInfinity isEqualToNumber:number])
    {
		self.error = @"+Infinity is not a valid number in JSON";
		return NO;

	}
    else if ([kNegativeInfinity isEqualToNumber:number])
    {
		self.error = @"-Infinity is not a valid number in JSON";
		return NO;

	}
    else if ([kNotANumber isEqualToNumber:number])
    {
		self.error = @"NaN is not a valid number in JSON";
		return NO;
	}

	const char *objcType = [number objCType];
	char num[128];
	size_t len;

	switch (objcType[0])
    {
		case 'c': case 'i': case 's': case 'l': case 'q':
			len = snprintf(num, sizeof num, "%lld", [number longLongValue]);
			break;
		case 'C': case 'I': case 'S': case 'L': case 'Q':
			len = snprintf(num, sizeof num, "%llu", [number unsignedLongLongValue]);
			break;
		case 'f': case 'd': default:
			if ([number isKindOfClass:[NSDecimalNumber class]])
            {
				char const *utf8 = [[number stringValue] UTF8String];
				[delegate writer:self appendBytes:utf8 length: strlen(utf8)];
				[state transitionState:self];
				return YES;
			}
			len = snprintf(num, sizeof num, "%.17g", [number doubleValue]);
			break;
	}
	[delegate writer:self appendBytes:num length: len];
	[state transitionState:self];
	return YES;
}

@end
