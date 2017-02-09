//
//  UMConfig.h
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"
@class UMConfigParsedLine;

#ifndef UMCONFIG_H
#define UMCONFIG_H  1
//#import "UMObject.h"
//#import "UMConfigGroup.h"
//#import "UMConfigParsedLine.h"

/*!
 @class UMConfig
 @brief  UMConfig is an object to hold the data of config files.
 
 config files are having the following syntax:
 
 # commented out lines are starting with a hash
 # a group starts with a group statement and ends with a empty line
 
 include "some-other-config-file"

 group = config-group name
 param = value
 param2 = value2

 group = group2
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
    NSString               *fileName;
    NSMutableDictionary    *singleGroups;
    NSMutableDictionary    *multiGroups;
    int                    verbose;
    NSMutableDictionary    *allowedSingleGroupNames;
    NSMutableDictionary    *allowedMultiGroupNames;
}

@property(readwrite,assign) int verbose;
@property(readwrite,strong) NSMutableDictionary    *allowedSingleGroupNames;
@property(readwrite,strong) NSMutableDictionary    *allowedMultiGroupNames;
@property(readwrite,strong) NSMutableDictionary    *singleGroups;
@property(readwrite,strong) NSString               *fileName;

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
#endif
