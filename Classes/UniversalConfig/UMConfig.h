//
//  UMConfig.h
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright: © 2016 Andreas Fink (andreas@fink.org), Basel, Switzerland. All rights reserved.
//

#import "UMObject.h"
@class UMConfigParsedLine;

#ifndef UMCONFIG_H
#define UMCONFIG_H  1
//#import "UMObject.h"
//#import "UMConfigGroup.h"
//#import "UMConfigParsedLine.h"

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
@property(readwrite,strong)     NSMutableDictionary    *allowedSingleGroupNames;
@property(readwrite,strong)     NSMutableDictionary    *allowedMultiGroupNames;
@property(readwrite,strong)     NSMutableDictionary    *singleGroups;
@property(readwrite,strong)     NSString               *fileName;

- (UMConfig *)initWithFileName:(NSString *)file;

- (void)read;

- (void)allowSingleGroup:(NSString *)name;
- (void)disallowSingleGroup:(NSString *)name;
- (void)allowMultiGroup:(NSString *)name;
- (void)disallowMultiGroup:(NSString *)name;

- (NSDictionary *)getSingleGroup:(NSString *)name;
- (NSArray *)getMultiGroups:(NSString *)name;

- (UMConfigParsedLine *)parseSingeLine:(NSString *)lin file:(NSString *)fn line:(long)ln;
- (NSArray *)readFromFile;
/* private 
- (NSArray *)readFromFile:(NSString *)fn;
*/
@end
#endif
