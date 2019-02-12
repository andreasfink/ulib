//
//  UMLogFile.m
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#import "UMLogFile.h"
#import "UMLogFeed.h"
#import "UMConfig.h"
#ifdef LINUX
#import "NSData+UMLog.h"
#endif
#include <unistd.h>
#import "UMUtil.h" /* for UMBacktrace */

@implementation UMLogFile

@synthesize fileName;
@synthesize fileHandler;
@synthesize lineDelimiter;
@synthesize chunkSize;
@synthesize filemgr;

- (UMLogFile *)initWithFileName:(NSString *)name
{
    BOOL ret;
    int eno =0;
    
    self = [super init];
    if (self)
    {
        self.fileName = name;
        self.filemgr = [NSFileManager defaultManager];
        
        ret = [filemgr fileExistsAtPath:name];
        if (ret == NO)
        {
            ret = [filemgr createFileAtPath:name contents:nil attributes:nil];
            if (ret == NO)
            {
                goto error;
            }
        }
        
        self.fileHandler =  [NSFileHandle fileHandleForUpdatingAtPath:name];
        if (!fileHandler)
        {
            goto error;
        }
    }
    return self;
    
error:
    
    eno = errno;
    NSLog(@"[UMLogfile initWithFileName]: Error was code: %d - message: %s", eno, strerror(eno));
    return nil;
}


- (void)closeLog
{
    [self lock];
    [fileHandler closeFile];
    [self unlock];
}

- (void)emptyLog
{
    [self lock];
    [fileHandler truncateFileAtOffset:0];
    [self unlock];
}

- (BOOL) removeLog
{
#ifdef GNUSTEP  /* gnustep doesnt have removeItemAtPath (yet) */
    [self lock];
    unlink([fileName UTF8String]);
    [self unlock];
    return YES;
#else
    BOOL ret;
   [self lock];
    NSError *err;
    ret = [filemgr removeItemAtPath:fileName error:&err];
    [self unlock];
    return ret;
#endif

}

- (void) logAnEntry:(UMLogEntry *)logEntry
{
	UMLogLevel	entryLevel;
	
	entryLevel = [logEntry level];
    
	if((entryLevel == UMLOG_DEBUG) && ([debugSections count]  > 0))
	{
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound )
		{
			[self lock];
			[self logNow: logEntry];
			[self unlock];
		}
	}
    
	else if( entryLevel >= level )
	{
		[self lock];
		[self logNow: logEntry];
		[self unlock];
	}
}

- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry
{
	UMLogLevel	entryLevel;
	
	entryLevel = [logEntry level];
    
	if((entryLevel == UMLOG_DEBUG) && ([debugSections count]  > 0))
	{
		if ([debugSections indexOfObject: [logEntry subsection]] != NSNotFound )
		{
			[self logNow: logEntry];
		}
	}
    
	else if( entryLevel >= level )
	{
		[self logNow: logEntry];
	}
}

- (void)logNow:(UMLogEntry *)logEntry
{
	NSString *s;
    NSData *data;
	
    [fileHandler seekToEndOfFile];
	s = [NSString stringWithFormat:@"%@\n",[logEntry description]];
    data = [s dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandler writeData:data];
}

- (void) flush
{
    [self lock];
    [fileHandler synchronizeFile];
    [self unlock];
}

- (void) flushUnlocked
{
    [fileHandler synchronizeFile];
}

- (ssize_t)cursor
{
    ssize_t pos;
    
    [self lock];
    pos = (ssize_t)[fileHandler offsetInFile];
    [self unlock];
    return pos;
}

- (ssize_t)cursorUnlocked
{
    ssize_t pos;
    
    pos = (ssize_t)[fileHandler offsetInFile];
    return pos;
}

- (ssize_t) cursorToEnd
{
    ssize_t size;
    
    [self lock];
    size = (ssize_t)[fileHandler seekToEndOfFile];
    [self unlock];
    return size;
}

- (ssize_t) cursorToEndUnlocked
{
    ssize_t size;
    
    size = (ssize_t)[fileHandler seekToEndOfFile];
    return size;
}

- (ssize_t) size
{
    ssize_t size;
    NSDictionary *fileAttributes;
    NSString *fileSize;
    NSError *error;
    
    size = -1;
    [self lock];
    fileAttributes = [filemgr attributesOfItemAtPath:fileName error:&error];
    [self unlock];
    if(fileAttributes)
	{
		fileSize = [fileAttributes objectForKey:@"NSFileSize"];
		size = (ssize_t)[fileSize longLongValue];
	}
    return size;
}

- (ssize_t) sizeUnlocked
{
    ssize_t size;
    NSDictionary *fileAttributes;
    NSString *fileSize;
    NSError *error;
    
    size = -1;
    fileAttributes = [filemgr attributesOfItemAtPath:fileName error:&error];
    if(fileAttributes)
	{
		fileSize = [fileAttributes objectForKey:@"NSFileSize"];
		size = [fileSize integerValue];
	}
    return size;
}

- (NSString *)description
{
    NSMutableString *desc;

    desc = [NSMutableString stringWithString:@"file log dump starts\n"];
    if (fileName)
    {
        [desc appendFormat:@"uses %@\n", fileName];
    }
    else
    {
        [desc appendString:@"has no log file attached\n"];
    }
    if (fileHandler)
    {
        [desc appendString:@"has file handler defined\n"];
    }
    else
    {
        [desc appendString:@"has no file handler defined\n"];
    }
    [desc appendString:@"file log dump ends\n"];
    return desc;
}

- (UMLogFile *) initWithFileName:(NSString *)aPath andSeparator:(NSString *)sep;
{
    if (!sep || [sep length] == 0)
    {
        return nil;
    }
    if ((self = [self initWithFileName:aPath]))
    {
        lineDelimiter = [[NSString alloc] initWithString:sep];
        currentOffset = 0ULL;
        chunkSize = 10;
        [fileHandler seekToEndOfFile];
        totalFileLength = (ssize_t)[fileHandler offsetInFile];
        //we don't need to seek back, since readLine will do that.
    }
    return self;
}


- (ssize_t)updateFileSize
{
    totalFileLength = [self sizeUnlocked];
    return totalFileLength;
}

/* Set ret -1 when error, 0 when end-of-file and 1 otherwise*/
- (NSString *) readLine:(int *)ret 
{
    NSMutableData *currentData;
    
    if (currentOffset >= totalFileLength)
    { 
        *ret = -1;
        return nil; 
    }
    
    NSData * newLineData = [lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
    [self lock];
    @try
    {
        [fileHandler seekToFileOffset:currentOffset];
        currentData = [[NSMutableData alloc] init];
        BOOL shouldReadMore = YES;
    
        @autoreleasepool
        {
            while (shouldReadMore)
            {
                if (currentOffset >= totalFileLength)
                {
                    break;
                }
            
                NSData *chunkToBeAdded;
#if defined(LINUX) || defined(FREEBSD)
                NSMutableData *chunk = [[fileHandler readDataOfLength:(unsigned int)chunkSize] mutableCopy];
#else
                NSMutableData *chunk = [[fileHandler readDataOfLength:chunkSize] mutableCopy];
#endif
                if (!chunk || [chunk length] == 0)
                {
                    break;
                }
                /* Heurestic: if the last byte of the chunk was one of separator bytes, read
                 * separator length minus one bytes more. This quarantees that the chunk contains
                 * the whole separator.*/
                if([self splittedSepatorInChunk:chunk])
                {
#if defined(LINUX) || defined(FREEBSD)
                    NSData *newChunk = [fileHandler readDataOfLength:(unsigned int)([newLineData length] - 1)];
#else
                    NSData *newChunk = [fileHandler readDataOfLength:([newLineData length] - 1)];
#endif
                    if (!newChunk)
                    {
                        [self unlock];
                        *ret = 0;
                        return nil;
                    }
                    [chunk appendData:newChunk];
                }
            
                NSRange newLineRange = [(NSData *)chunk rangeOfData:newLineData options:0 range:NSMakeRange(0, [chunk length])];
                //include the length so we can include the delimiter in the string
                NSRange subData = NSMakeRange(0, newLineRange.location+[newLineData length]);
                if (newLineRange.location != NSNotFound)
                {
                    chunkToBeAdded = [chunk subdataWithRange:subData];
                    shouldReadMore = NO;
                }
                else
                {
                    chunkToBeAdded = chunk;
                }
                [currentData appendData:chunkToBeAdded];
                currentOffset += [chunkToBeAdded length];
            }
        }
    }
    @finally
    {
        [self unlock];
    }
    NSString * line = [[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding];
    *ret = 1;
    return line;
}

- (NSString *) readTrimmedLine:(int *)ret 
{
    return [[self readLine:ret] stringByTrimmingCharactersInSet:[UMObject whitespaceAndNewlineCharacterSet]];
}

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL*))block withResult:(int *)ret
{
    NSString * line = nil;
    BOOL stop = NO;
    while (stop == NO && (line = [self readLine:ret]))
    {
        block(line, &stop);
    }
}
#endif

- (BOOL) splittedSepatorInChunk:(NSData *)chunk
{
    NSRange last;
    long len;
    long i = 0;
    unsigned char lastByte[1];
    unsigned char byte;
    
    if (!chunk || [chunk length] == 0)
        return NO;
    
    if (!lineDelimiter || [lineDelimiter length] == 0)
        return NO;
    
    last = NSMakeRange([chunk length] - 1, 1);
    [chunk getBytes:lastByte range:last];
    len = [lineDelimiter length];
    
    while(i < len)
    {
        byte = [lineDelimiter characterAtIndex:i];
        if (lastByte[0] == byte)
            return YES;
        ++i;
    }
    
    return NO;
}

+ (UMLogFeed *) setLogHandler:(UMLogHandler *)handler
					 withName:(NSString *)name
				  withSection:(NSString *)type
			   withSubsection:(NSString *)sub
			   andWithLogFile:(UMLogFile *)dst
{
    UMLogFeed *xlogFeed;
    xlogFeed = [[UMLogFeed alloc] initWithHandler:handler section:type subsection:sub];
    [xlogFeed setCopyToConsole:0];
    [xlogFeed setName:name];
    [handler addLogDestination:dst];
    return xlogFeed;
}


- (ssize_t)logNowAndGiveSize:(UMLogEntry *)logEntry
{
	NSString *s;
    NSData *data;
	
    [fileHandler seekToEndOfFile];
	s = [logEntry description];
    data = [s dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandler writeData:data];
    
    return [data length];
}


- (NSString *)oneLineDescription
{
    NSMutableString *s = [[NSMutableString alloc]init];
    [s appendFormat:@" output FILE %@ level %d %@",
     fileName,
     level,
     [UMLogEntry levelName:level]];
    
    if(debugSections)
    {
        BOOL first = YES;
        [s appendFormat:@"debugSection = { "];
        for(NSString *section in debugSections)
        {
            if(first)
            {
                [s appendFormat:@"{ %@",section];
                first = NO;
            }
            else
            {
                [s appendFormat:@", %@",section];
            }
        }
        [s appendFormat:@"} "];
            
    }
    
    
    if(onlyLogSubsections)
    {
        BOOL first = YES;
        [s appendFormat:@"onlyLogSubsections = { "];
        for(NSString *section in onlyLogSubsections)
        {
            if(first)
            {
                [s appendFormat:@"{ %@",section];
                first = NO;
            }
            else
            {
                [s appendFormat:@", %@",section];
            }
        }
        [s appendFormat:@"} "];
    }
    return s;
}

@end
