//
//  UMConfigGroup.h
//  ulib
//
//  Created by Andreas Fink on 16.12.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//

#import "UMObject.h"

/*!
@class UMConfigGroup
@brief  UMConfigGroup is an object to hold the data of a single config file group section.

*/

@interface UMConfigGroup : UMObject
{
    NSMutableDictionary *vars;
    NSString *configFile;
    NSString *name;
    long line;
}

@property(readwrite,strong) NSMutableDictionary *vars;
@property(readwrite,strong) NSString *configFile;
@property(readwrite,strong) NSString *name;
@property(readwrite,assign) long line;

- (UMConfigGroup *)init;
- (NSString *)getString:(NSString *)name;
- (NSInteger)getInteger:(NSString *)name;
- (BOOL)getBoolean:(NSString *)name;

@end
