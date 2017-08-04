//
//  UMObject.m
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#import "UMObject.h"
#import "UMHistoryLog.h"
#import "UMConfig.h"
#import "UMLogHandler.h"
#import "UMLogFeed.h"
#import "UMLogFile.h"
#import "NSString+UniversalObject.h"

/* Important: THIS FILE MUST BE COMPILED WITH -fno-objc-arc  !*/

static NSFileHandle *alloc_file = NULL;
static NSMutableDictionary *object_stat;
extern NSString *UMBacktrace(void **stack_frames, size_t size);

void umobject_enable_alloc_logging(const char *f)
{
    if(alloc_file==NULL)
    {
        mode_t creationMode = 0664;
        int fd = open(f,O_CREAT | O_WRONLY,creationMode);
        if(fd>=0)
        {
            alloc_file = [[NSFileHandle alloc ]initWithFileDescriptor:fd];
            NSString *s = @"Start\n";
            [alloc_file writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else
        {
            NSLog(@" couldnt open alloc log %s",f);
        }
    }
}

void umobject_disable_alloc_logging(void)
{
    NSFileHandle *toClose = alloc_file;
    alloc_file = NULL;
    [toClose closeFile];
}

@interface UMObjectThreadStarter : NSObject
{
    SEL         _selector;
    id          _obj;
    const char *_file;
    long        _line;
    const char *_func;
}

@property(readwrite,assign,atomic) SEL selector;
@property(readwrite,strong,atomic) id  obj;
@property(readwrite,assign,atomic) const char *file;
@property(readwrite,assign,atomic) long        line;
@property(readwrite,assign,atomic) const char *func;
@end

@implementation UMObjectThreadStarter

- (void)dealloc
{
    [_obj release];
    [super dealloc];
}
@end

#ifdef DEBUG_TRACK_ALLOCATION
static FILE *alloc_log;
#endif

/*!
 @class UMObject
 @brief The root object for ulib

 UMObject is a replacement for NSObject. It allows a log handler to be attached,
 getting instantiated from a config file and it has some debug variant UMObjectDebug
 which allow to trace where objects get allocated and deallocated and it
 has methods to run methods in background in another thread.
 */
@implementation UMObject

@synthesize logFeed;




- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
                        logdir:(NSString *)logdir
{
        [self addLogFromConfigGroup:grp toHandler:handler sectionName:[grp objectForKey:@"group"] subSectionName:NULL configOption:@"log-file" logdir:logdir];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
{
    [self addLogFromConfigGroup:grp toHandler:handler sectionName:[grp objectForKey:@"group"]];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp toHandler:(UMLogHandler *)handler sectionName:(NSString *)sec 
{
    [self addLogFromConfigGroup:grp toHandler:handler sectionName:sec subSectionName:NULL configOption:@"log-file"];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp toHandler:(UMLogHandler *)handler sectionName:(NSString *)sec subSectionName:(NSString *)ss
{
    [self addLogFromConfigGroup:grp toHandler:handler sectionName:sec subSectionName:ss configOption:@"log-file"];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp toHandler:(UMLogHandler *)handler sectionName:(NSString *)sec subSectionName:(NSString *)ss configOption:(NSString *)configOption
{
    [self addLogFromConfigGroup:grp toHandler:handler sectionName:sec subSectionName:ss configOption:configOption logdir:NULL];
}

- (void) addLogFromConfigGroup:(NSDictionary *)grp toHandler:(UMLogHandler *)handler sectionName:(NSString *)sec subSectionName:(NSString *)ss configOption:(NSString *)configOption logdir:(NSString *)logdir
{
    @autoreleasepool
    {

        NSString *logFileName;
        UMLogFile *dst;

        if (grp==NULL)
        {
            return;
        }
        logFileName = [grp objectForKey:configOption];
        if(logFileName==NULL)
        {
            return;
        }
        if(logdir.length > 0)
        {
            logFileName = [logFileName fileNameRelativeToPath:logdir];
        }
        dst = [[UMLogFile alloc] initWithFileName:logFileName andSeparator:@"\n" ];
        if(dst==NULL)
        {
            return;
        }
        [handler addLogDestination:dst];
        UMLogFeed *feed = [[UMLogFeed alloc]initWithHandler:handler section:sec];
        self.logFeed = feed;
        [feed release];
        [dst release];
        //    section = [type retain];
        //    subsection = [ss retain];
        //    name = [NSString stringwithFormat:section:subsection];
    }
}

- (id) init
{
    self=[super init];
    if(self)
    {
        @autoreleasepool
        {
            NSString *m = [[self class] description];

#ifdef UMOBJECT_USE_MAGIC
            size_t l = strlen(m.UTF8String);
            _magic = calloc(l+1,1);
            if(_magic)
            {
                strncpy(_magic,m.UTF8String,l);
                umobject_flags  |= UMOBJECT_FLAG_HAS_MAGIC;
            }
#endif
            if(alloc_file)
            {
                NSString *s = [NSString stringWithFormat:@"+%@\n",m];
                NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
                @synchronized(alloc_file)
                {
                    [alloc_file writeData:d];
                }
            }
            if(object_stat)
            {
                @synchronized(object_stat)
                {
                    NSMutableDictionary *entry = object_stat[m];
                    if(entry == NULL)
                    {
                        entry = [[NSMutableDictionary alloc]init];
                        entry[@"type"] = m;
                        entry[@"alloc"] = @(1);
                        entry[@"dealloc"]=@(0);
                        object_stat[m]=entry;
                        [entry release];
                    }
                    else
                    {
                        entry[@"alloc"] =  @([entry[@"alloc"] intValue]+1);
                        object_stat[m]=entry;
                    }
                }
            }
        }
    }
    return self;
}

- (void)dealloc
{
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Dealloc [%p] rc=%d",self,self.ulib_retain_counter);
    }
    if(alloc_file)
    {
        NSString *m = [[self class] description];
        NSString *s = [NSString stringWithFormat:@"-%@\n",m];
        NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
        @synchronized(alloc_file)
        {
            [alloc_file writeData:d];
        }
        
    }
    if(object_stat)
    {
        @synchronized(object_stat)
        {
            NSString *m;
            m = [[self class] description];
            NSMutableDictionary *entry = object_stat[m];
            if(entry)
            {
                entry[@"dealloc"] =  @([entry[@"dealloc"] intValue]+1);
                object_stat[m]=entry;
            }
        }
    }

    if(_magic)
    {
        *_magic = '~';
        free(_magic);
    }
    _magic = NULL;
    [logFeed release];
    [super dealloc];
}


- (void)threadStarter:(UMObjectThreadStarter *)ts
{
    SEL sel = ts.selector;
    id  obj = [ts.obj retain];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:sel withObject:obj];
#pragma clang diagnostic pop
    [obj release];
}

- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument
{
    @synchronized(self)
    {
        UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
        ts.selector = aSelector;
        ts.obj      = anArgument;
        [NSThread detachNewThreadSelector:@selector(threadStarter:)
                                 toTarget:self
                               withObject:ts];
    }
}

- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument
                           file:(const char *)fil
                           line:(long)lin
                       function:(const char *)fun
{
    @synchronized(self)
    {
        UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
        ts.selector = aSelector;
        ts.obj      = anArgument;
        ts.file     = fil;
        ts.line     = lin;
        ts.func     = fun;

        [NSThread detachNewThreadSelector:@selector(threadStarter:)
                                 toTarget:self
                               withObject:ts];
    }
}

- (void)runSelectorInBackground:(SEL)aSelector
{
    @synchronized(self)
    {
       UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
        ts.selector = aSelector;
        ts.obj      = nil;
        
        [NSThread detachNewThreadSelector:@selector(threadStarter:)
                                 toTarget:self
                               withObject:ts];
    }
}


- (NSString *) descriptionWithPrefix:(NSString *)prefix
{
    @synchronized(self)
    {
        return [[self description]prefixLines:prefix];
    }
}


void umobject_enable_object_stat(void)
{
    if(object_stat == NULL)
    {
        object_stat = [[NSMutableDictionary alloc]init];
    }
}


void umobject_disable_object_stat(void)
{
    object_stat = NULL;
}

NSArray *umobject_object_stat(BOOL sortByName)
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    @synchronized(object_stat)
    {
        NSArray *keys = [object_stat allKeys];
        for(NSString *key in keys)
        {
            [arr addObject: object_stat[key]];
        }
        NSArray *arr2 = [arr sortedArrayUsingComparator: ^(NSDictionary *a, NSDictionary *b)
                         {
                             if(sortByName)
                             {
                                 NSString *first = a[@"type"];
                                 NSString *second = b[@"type"];
                                 return [first compare:second];
                             }
                             else
                             {
                                 int a_alloc = [a[@"alloc"] intValue];
                                 int a_dealloc = [a[@"dealloc"] intValue];
                                 int a_inUse = a_alloc - a_dealloc;
                                 
                                 int b_alloc = [b[@"alloc"] intValue];
                                 int b_dealloc = [b[@"dealloc"] intValue];
                                 int b_inUse = b_alloc - b_dealloc;
                                 
                                 if(a_inUse == b_inUse)
                                 {
                                     return NSOrderedSame;
                                 }
                                 if(a_inUse < b_inUse)
                                 {
                                     return NSOrderedDescending;
                                 }
                                 return NSOrderedAscending;
                             }
                         }];
        return arr2;
    }
}

BOOL umobject_object_stat_is_enabled(void)
{
    if(object_stat==NULL)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


- (id)retain
{
    [super retain];
    self.ulib_retain_counter++;
    if(umobject_flags & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
            [self retainDebug];
    }
    return self;
}

- (oneway void)release
{
    self.ulib_retain_counter--;
    if(umobject_flags & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        [self releaseDebug];
    }
    [super release];
}

- (void)retainDebug
{
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Retain [%p] rc=%d",self,self.ulib_retain_counter);
        NSLog(@"Called from %@",UMBacktrace(NULL,0));
    }
}


- (void)releaseDebug
{
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Release [%p] rc=%d",self,self.ulib_retain_counter);
        NSLog(@"Called from %@",UMBacktrace(NULL,0));
    }
}


- (void)enableRetainReleaseLogging
{
    umobject_flags |= UMOBJECT_FLAG_LOG_RETAIN_RELEASE;
}
@end



