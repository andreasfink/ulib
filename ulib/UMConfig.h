//
//  UMConfig.h
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import <ulib/UMObject.h>
@class UMConfigParsedLine;

//#import <ulib/UMObject.h>
//#import <ulib/UMConfigGroup.h>
//#import <ulib/UMConfigParsedLine.h>

/*!
 @class UMConfig
 @brief  UMConfig is an object to hold the data of config files.
 
 config files are having the following syntax:
 
 # commented out lines are starting with a hash
 # a group starts with a group statement and ends with a empty line
 
 include "some-other-config-file"

 group = group1
 param = value
 param2 = value2

 group = group2
 param = value
 param2 = value2

 alternative syntax (windows.ini file style)
 
 include "some-other-config-file"
 
[group1]
 param = value
 param2 = value2
 
[group2]
 param = value
 param2 = value2

 
 Which groups are valid and read is defined while reading.
 The individal parameters then end up in a dictionary.
 
 You define also if a group can be defined only once or multiple times.

 Typical usage sequence:
 
  UMConfig *config = [[UMConfig alloc]initWithFileName:@"myconfig.conf"];
  [config allowSingleGroup:@"main"];
  [config allowSingleGroup:@"subsection"];
  [config disallowSingleGroup:@"no-longer-supported-subsection"];
  [config allowMultiGroup:@"multisection"];
  [config read];
 
   groups which are in the config file but not defined are simply skipped
   if they are in the disallowed definition it throws an exception instead.
 
 */

@interface UMConfig : UMObject
{
    NSString               *_fileName;
    NSMutableDictionary    *_singleGroups;
    NSMutableDictionary    *_multiGroups;
    int                    _verbose;
    NSMutableDictionary    *_allowedSingleGroupNames;
    NSMutableDictionary    *_allowedMultiGroupNames;
    NSString                *_configAppend;
    NSString                *_systemIncludePath;
}

@property(readwrite,assign) int                    verbose;
@property(readwrite,strong) NSMutableDictionary    *allowedSingleGroupNames;
@property(readwrite,strong) NSMutableDictionary    *allowedMultiGroupNames;
@property(readwrite,strong) NSMutableDictionary    *singleGroups;
@property(readwrite,strong) NSString               *fileName;
@property(readwrite,strong) NSString               *configAppend;
@property(readwrite,strong) NSString               *systemIncludePath;


- (UMConfig *)initWithFileName:(NSString *)file;

- (void)read;

- (void)allowSingleGroup:(NSString *)name;
- (void)disallowSingleGroup:(NSString *)name;
- (void)allowMultiGroup:(NSString *)name;
- (void)disallowMultiGroup:(NSString *)name;

- (NSDictionary *)getSingleGroup:(NSString *)name; /*!< return a NSDictionary of a group of the config section  group */
- (NSArray *)getMultiGroups:(NSString *)name; /*!< return an NSArray of NSDictionary's of a group of the config section  group which can occur multiple times */


- (UMConfigParsedLine *)parseSingeLine:(NSString *)lin file:(NSString *)fn line:(long)ln;
- (NSArray *)readFromFile;
/* private 
- (NSArray *)readFromFile:(NSString *)fn;
*/
@end
