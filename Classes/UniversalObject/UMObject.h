//
//  UMObject.h
//  ulib
//
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAGIC_SIZE  64

@class UMHistoryLog, UMConfig, UMLogFeed, UMLogHandler;

void umobject_enable_alloc_logging(const char *f);
void umobject_disable_alloc_logging(void);

void umobject_enable_object_stat(void);
void umobject_disable_object_stat(void);
NSArray *umobject_object_stat(BOOL sortByName);
BOOL umobject_object_stat_is_enabled(void);


/*  if UMOBJECT_USE_MAGIC is set, then the object has a field
    named _magic which is a cpointer to the object type string.
    this is useful for debugging under linux but it takes memory
    for every object */

/*  if UMOBJECT_FLAG_LOG_RETAIN_RELEASE is set then the object
    is logging all retains/releases. This is useful for figuring out
    where your object is relased where it shouldnt be yet or is still
    to use this you need to inherit from UMObjectDebug instead of UMObject
    however.
 */

#define UMOBJECT_USE_MAGIC                  0
#define UMOBJECT_FLAG_HAS_MAGIC             0x01
#define UMOBJECT_FLAG_LOG_RETAIN_RELEASE    0x02

@interface UMObject : NSObject 
{
    uint32_t    umobject_flags;
    char        *_magic;
    UMLogFeed   *logFeed;
}

@property (readwrite,strong) UMLogFeed *logFeed;

//@property (readonly,retain) NSString *name;


- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
                        logdir:(NSString *)logdir;

- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler;

- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
                   sectionName:(NSString *)sec;

- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
                   sectionName:(NSString *)sec
                subSectionName:(NSString *)ss;

- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
                   sectionName:(NSString *)sec
                subSectionName:(NSString *)ss
                  configOption:(NSString *)configOption;

- (void) addLogFromConfigGroup:(NSDictionary *)grp
                     toHandler:(UMLogHandler *)handler
                   sectionName:(NSString *)sec
                subSectionName:(NSString *)ss
                  configOption:(NSString *)configOption
                        logdir:(NSString *)logdir;

- (id) init;

- (NSString *) descriptionWithPrefix:(NSString *)prefix;

- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument;

- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument
                           file:(const char *)fil
                           line:(long)lin
                       function:(const char *)fun;

- (void)runSelectorInBackground:(SEL)aSelector;

@end


