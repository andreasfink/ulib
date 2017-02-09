//
//  UMLogFile.h
//  ulib.framework
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMLogDestination.h"

@class UMLogFeed, UMLogHandler;

@interface UMLogFile : UMLogDestination
{
    NSString *fileName;
    NSFileHandle *fileHandler;
    NSFileManager *filemgr;
    ssize_t currentOffset;
    ssize_t totalFileLength;
    
    NSString * lineDelimiter;
    NSUInteger chunkSize;
}

@property (readwrite,strong) NSString *fileName;
@property (readwrite,strong) NSFileHandle *fileHandler;
@property (nonatomic, copy) NSString * lineDelimiter;
@property (nonatomic, assign) NSUInteger chunkSize;
@property (readwrite, strong) NSFileManager *filemgr;

- (UMLogFile *) initWithFileName:(NSString *)name;
- (BOOL) removeLog;
- (void) emptyLog;
- (void) closeLog;
- (void) logAnEntry:(UMLogEntry *)logEntry;
- (void) unlockedLogAnEntry:(UMLogEntry *)logEntry;
- (void) logNow:(UMLogEntry *)logEntry;
- (void) flush;
- (void) flushUnlocked;
- (ssize_t) cursor;
- (ssize_t) cursorUnlocked;
- (ssize_t) cursorToEnd;
- (ssize_t) cursorToEndUnlocked;
- (ssize_t) size;
- (ssize_t) sizeUnlocked;
- (NSString *) description;

- (UMLogFile *) initWithFileName:(NSString *)aPath andSeparator:(NSString *)sep;
- (ssize_t)updateFileSize;
- (NSString *) readLine:(int *)ret;
- (NSString *) readTrimmedLine:(int *)ret;
- (BOOL) splittedSepatorInChunk:(NSData *)chunk;
+ (UMLogFeed *) setLogHandler:(UMLogHandler *)handler  withName:(NSString *)name withSection:(NSString *)type withSubsection:(NSString *)sub andWithLogFile:(UMLogFile *)dst;
- (ssize_t)logNowAndGiveSize:(UMLogEntry *)logEntry;

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString*, BOOL *))block withResult:(int *)ret;
#endif

@end
