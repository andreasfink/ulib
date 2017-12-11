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

/* Important:  if alloc/dealloc logging is needed, this file must be compiled with -fno-objc-arc !*/

static NSFileHandle *alloc_file = NULL;
static NSMutableDictionary *object_stat = NULL;
static pthread_mutex_t *object_stat_mutex = NULL;
 
extern NSString *UMBacktrace(void **stack_frames, size_t size);

#if __has_feature(objc_arc)

#define USING_ARC   1
#undef  RETAIN_RELEASE_DEBUG

#endif


int umobject_enable_alloc_logging(const char *f)
{
#ifdef RETAIN_RELEASE_DEBUG
    if(alloc_file==NULL)
    {
        mode_t creationMode = 0664;
        int fd = open(f,O_CREAT | O_WRONLY,creationMode);
        if(fd>=0)
        {
            alloc_file = [[NSFileHandle alloc ]initWithFileDescriptor:fd];
            NSString *s = @"Start\n";
            [alloc_file writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
            return 0;
        }
        else
        {
            NSLog(@" couldnt open alloc log %s",f);
            return -2;
        }
    }
    return 0;
#else
    return -1;
#endif //RETAIN_RELEASE_DEBUG
    
}

void umobject_disable_alloc_logging(void)
{
#ifdef RETAIN_RELEASE_DEBUG
    NSFileHandle *toClose = alloc_file;
    alloc_file = NULL;
    [toClose closeFile];
#endif //RETAIN_RELEASE_DEBUG
}

@implementation UMObjectStat
- (UMObjectStat *)copyWithZone:(NSZone *)zone;
{
    UMObjectStat *r = [[UMObjectStat allocWithZone:zone]init];
    r.name = _name;
    r.alloc_count = _alloc_count;
    r.dealloc_count = _dealloc_count;
    r.inUse_count = _inUse_count;
    return r;
}
@end

@interface UMObjectThreadStarter : NSObject
{
    SEL         _selector;
    id          _obj;
    const char *_file;
    long        _line;
    const char *_func;
}

@property(readwrite,assign,atomic) SEL         selector;
@property(readwrite,strong,atomic) id          obj;
@property(readwrite,assign,atomic) const char  *file;
@property(readwrite,assign,atomic) long        line;
@property(readwrite,assign,atomic) const char  *func;
@end

@implementation UMObjectThreadStarter

#if RETAIN_RELEASE_DEBUG
- (void)dealloc
{
    [_obj release];
    [super dealloc];
}
#endif

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
        [self addLogFromConfigGroup:grp
                          toHandler:handler
                        sectionName:grp[@"group"]
                     subSectionName:NULL
                       configOption:@"log-file"
                             logdir:logdir];
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

- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
                   sectionName:(NSString *)sec
                subSectionName:(NSString *)ss
                  configOption:(NSString *)configOption
                        logdir:(NSString *)logdir
{
#if !defined(USING_ARC)
    @autoreleasepool
    {
#endif
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
        UMLogLevel logLevel = UMLOG_MAJOR;
        if(grp[@"log-level"])
        {
            logLevel = (UMLogLevel)[grp[@"log-level"]intValue];
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
        dst.level = logLevel;
        [handler addLogDestination:dst];
        UMLogFeed *feed = [[UMLogFeed alloc]initWithHandler:handler section:sec];
        self.logFeed = feed;
#if !defined(USING_ARC)
        [feed release];
        [dst release];
#endif
        //    section = [type retain];
        //    subsection = [ss retain];
        //    name = [NSString stringwithFormat:section:subsection];
#if !defined(USING_ARC)
    }
#endif
}

- (id) init
{
    self=[super init];
    if(self)
    {
#ifdef UMOBJECT_USE_MAGIC
        
#if !defined(USING_ARC)
        @autoreleasepool
#endif
        {
            NSString *m = [[self class] description];
            size_t l = strlen(m.UTF8String);
            _magic = calloc(l+1,1);
            if(_magic)
            {
                strncpy(_magic,m.UTF8String,l);
                umobject_flags  |= UMOBJECT_FLAG_HAS_MAGIC;
            }
        }
    
#endif
        if(alloc_file)
        {
#if !defined(USING_ARC)
            @autoreleasepool
#endif
            {
                NSString *s = [NSString stringWithFormat:@"+%@\n",[[self class] description]];
                NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
                @synchronized(alloc_file)
                {
                    [alloc_file writeData:d];
                }
            }
        }
        if(object_stat)
        {
#if !defined(USING_ARC)
            @autoreleasepool
#endif
            {
                NSString *m = [[self class] description];
                pthread_mutex_lock(object_stat_mutex);
                UMObjectStat *entry = object_stat[m];
                if(entry == NULL)
                {
                    entry = [[UMObjectStat alloc]init];
                    entry.name = m;
                    entry.alloc_count = 1;
                    entry.inUse_count = 1;
                    object_stat[m]=entry;
#if !defined(USING_ARC)
                    [entry release];
#endif
                }
                else
                {
                    entry.alloc_count++;
                    entry.inUse_count++;
                    object_stat[m]=entry;
                }
                pthread_mutex_unlock(object_stat_mutex);
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
#if !defined(USING_ARC)
        @autoreleasepool
#endif
        {
            NSString *m = [[self class] description];
            NSString *s = [NSString stringWithFormat:@"-%@\n",m];
            NSData *d = [s dataUsingEncoding:NSUTF8StringEncoding];
            @synchronized(alloc_file)
            {
                [alloc_file writeData:d];
            }
        }
    }
    if(object_stat)
    {
        NSString *m;
        m = [[self class] description];

        pthread_mutex_lock(object_stat_mutex);
        UMObjectStat *entry = object_stat[m];
        if(entry)
        {
            entry.dealloc_count++;
            entry.inUse_count--;
            object_stat[m]=entry;
        }
        pthread_mutex_unlock(object_stat_mutex);
    }

    if(_magic)
    {
        *_magic = '~';
        free(_magic);
    }
    _magic = NULL;
#if !defined(USING_ARC)
    [logFeed release];
    [super dealloc];
#endif
}

- (void)threadStarter:(UMObjectThreadStarter *)ts
{
    SEL sel = ts.selector;
#if !defined(USING_ARC)
    id  obj = [ts.obj retain];
#else
    id obj = ts;
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self performSelector:sel withObject:obj];
#pragma clang diagnostic pop
#if !defined(USING_ARC)
    [obj release];
#endif
}

- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument
{
    UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
    ts.selector = aSelector;
    ts.obj      = anArgument;
    [NSThread detachNewThreadSelector:@selector(threadStarter:)
                             toTarget:self
                           withObject:ts];
}

- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument
                           file:(const char *)fil
                           line:(long)lin
                       function:(const char *)fun
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

- (void)runSelectorInBackground:(SEL)aSelector
{
   UMObjectThreadStarter *ts = [[UMObjectThreadStarter alloc]init];
    ts.selector = aSelector;
    ts.obj      = nil;

    [NSThread detachNewThreadSelector:@selector(threadStarter:)
                             toTarget:self
                           withObject:ts];
}

- (NSString *) descriptionWithPrefix:(NSString *)prefix
{
    return [[self description]prefixLines:prefix];
}

int umobject_enable_object_stat(void)
{
    if(object_stat == NULL)
    {
        object_stat_mutex = (pthread_mutex_t *)malloc(sizeof(pthread_mutex_t));
        if(object_stat_mutex)
        {
            pthread_mutex_init(object_stat_mutex, NULL);
            object_stat = [[NSMutableDictionary alloc]init];
            return 0;
        }
    }
    return 1;
}

void umobject_disable_object_stat(void)
{
    object_stat = NULL;
    pthread_mutex_destroy(object_stat_mutex);
    free(object_stat_mutex);
    object_stat_mutex = NULL;
}

NSArray *umobject_object_stat(BOOL sortByName)
{
    NSMutableArray *arr = [[NSMutableArray alloc]init];
    if(object_stat==NULL)
    {
        return arr;
    }
    pthread_mutex_lock(object_stat_mutex);
    NSArray *keys = [object_stat allKeys];
    for(NSString *key in keys)
    {
        [arr addObject: [object_stat[key] copy] ];
    }
    NSArray *arr2 = [arr sortedArrayUsingComparator: ^(UMObjectStat *a, UMObjectStat *b)
                     {
                         if(sortByName)
                         {
                             return [a.name compare:b.name];
                         }
                         else
                         {
                             if(a.inUse_count == b.inUse_count)
                             {
                                 return NSOrderedSame;
                             }
                             if(a.inUse_count < b.inUse_count)
                             {
                                 return NSOrderedDescending;
                             }
                             return NSOrderedAscending;
                         }
                     }];
    pthread_mutex_unlock(object_stat_mutex);
    return arr2;
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


#if !defined(USING_ARC)
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
#endif

#if !defined(USING_ARC)
- (oneway void)release
{
    self.ulib_retain_counter--;
    if(umobject_flags & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        [self releaseDebug];
    }
    [super release];
}
#endif

- (void)retainDebug
{
#if !defined(USING_ARC)
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Retain [%p] rc=%d",self,self.ulib_retain_counter);
        NSLog(@"Called from %@",UMBacktrace(NULL,0));
    }
#endif
}


- (void)releaseDebug
{
#if !defined(USING_ARC)
    if(umobject_flags  & UMOBJECT_FLAG_LOG_RETAIN_RELEASE)
    {
        NSLog(@"Release [%p] rc=%d",self,self.ulib_retain_counter);
        NSLog(@"Called from %@",UMBacktrace(NULL,0));
    }
#endif
}

- (void)enableRetainReleaseLogging
{
#if !defined(USING_ARC)
    umobject_flags |= UMOBJECT_FLAG_LOG_RETAIN_RELEASE;
#endif
}


@end



