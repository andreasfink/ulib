//
//  UMObject.h
//  ulib
//
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ulib/UMMutex.h>

@class UMHistoryLog, UMConfig, UMLogFeed, UMLogHandler;


int umobject_enable_alloc_logging(const char *f);
void umobject_disable_alloc_logging(void);

int umobject_enable_object_stat(void);
void umobject_disable_object_stat(void);
NSArray *umobject_object_stat(BOOL sortByName);
BOOL umobject_object_stat_is_enabled(void);

#define UMOBJECT_FLAG_HAS_MAGIC				0x01
#define UMOBJECT_FLAG_LOG_RETAIN_RELEASE    0x02
#define UMOBJECT_FLAG_IS_COPIED             0x04
#define UMOBJECT_FLAG_COUNTED_IN_STAT		0x08
#define UMOBJECT_FLAG_IS_INITIALIZED        0xCC00
#define UMOBJECT_FLAG_IS_RELEASED           0x3300

typedef  void (*UMThreadStarterFunction)(NSObject *param);

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
    const char	*_magic;        			/*!< c pointer to the class name which has instantiated this object . Optional set*/
	const char  *_objectStatisticsName;		/*!< c pointer to the name which is used in object statistics. defaults to _magic */
	UMLogFeed   *_logFeed;                  /*!< The log feed this object can use to log anything related to this UMObject */
    uint32_t    _umobject_flags; 			/*!< internal flags to remember which options this object has */
}

@property (readwrite,strong,atomic) UMLogFeed   *logFeed;
@property (readwrite,assign,atomic) NSString    *objectStatisticsName;
@property (readonly,assign,atomic)  uint32_t    umobject_flags;

- (UMObject *) init;
- (void)setupMagic; /* !< populates the magic c pointer */

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
+ (NSCharacterSet *)whitespaceAndNewlineCharacterSet; /* this differs from NSCharacterSet version by having LINE SEPARATOR' (U+2028)
                                                       in it as well (UTF8 E280AD) */
+ (NSCharacterSet *)whitespaceAndNewlineAndCommaCharacterSet; /* used for separating list of items in strings */

+ (NSCharacterSet *)newlineCharacterSet; /* this differs from NSCharacterSet version by having LINE SEPARATOR' (U+2028)
                                                       in it as well (UTF8 E280AD) */
+ (NSCharacterSet *)bracketsAndWhitespaceCharacterSet;  /* includes [ and ]  and whitespace */
- (NSString *) descriptionWithPrefix:(NSString *)prefix;
- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument;
- (void)runSelectorInBackground:(SEL)aSelector
                     withObject:(id)anArgument
                           file:(const char *)fil
                           line:(long)lin
                       function:(const char *)fun;
- (void)runSelectorInBackground:(SEL)aSelector;

+ (void)runFunctionInBackground:(UMThreadStarterFunction)func withObject:(id)param;
+ (void)runFunctionInBackground:(UMThreadStarterFunction)func withPointer:(void *)ptr;

@end


void umobject_stat_verify_ascii_name(const char *asciiName);
void umobject_stat_external_increase_name(const char *asciiName);
void umobject_stat_external_decrease_name(const char *asciiName);
const char *umobject_get_constant_name_pointer(const char *file, const long line, const char *func);
