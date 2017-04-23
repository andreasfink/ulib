//
//  UMObject.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
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

/*!
 @class UMObject
 @brief The root object for ulib

 UMObject is a replacement for NSObject. It allows a log handler to be attached,
 getting instantiated from a config file and it has some debug variant UMObjectDebug
 which allow to trace where objects get allocated and deallocated and it
 has methods to run methods in background in another thread.
 */

@interface UMObject : NSObject 
{
    uint32_t    umobject_flags; /*!< internal flags to remember which options this object has */
    char        *_magic;        /*!< c pointer to the class name which has instantiated this object. Only populated if UMOBJECT_USE_MAGIC is set to 1. Useful for debugging with a limited verison of lldb */
    UMLogFeed   *logFeed;       /*!< The log feed this object can use to log anything related to this UMObject */
}

@property (readwrite,strong,atomic) UMLogFeed *logFeed;

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


