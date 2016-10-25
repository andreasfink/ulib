//
//  UMGroup.h
//  ulib
//
//  Created by Aarno Syvänen on 08.05.12.
//  Copyright (c) 2012 Andreas Fink
//

#import <Foundation/Foundation.h>
#import "UMObject.h"

#define HAVE_PGSQL 1

@class UMDbSession, UMDbPool;

@interface UMGroup : UMObject
{
    NSLock *globalGroupLock;
    NSMutableArray *globalGroupList;
    signed long	updCnt;                  /**< number of credit decrements*/
    signed long maxCnt;                  /**< user credit */
    signed long	curCnt;                  /**< credit used by the user */
    signed long	updMax;                  /**< maximum number of credit decrements (if reached, 
                                          * group will be stored to the database)*/
    unsigned long gid;	                 /**< groupid of message owner */
    NSString *tableName;   
    UMDbPool *pool;
    UMDbSession *session;
    NSString *groupFieldNames2;
    NSString *groupName;
    NSString *groupPass;
}

@property(readwrite,retain)	NSString *groupName;
@property(readwrite,retain)	NSString *groupPass;

- (UMGroup *)init;
- (UMGroup *)initWithConfigFile:(NSString *)file;
- (void)dealloc;
- (void)flushGoingDown:(BOOL)end;
- (UMGroup *)authenticateWithUser:(NSString *)userName andPassword:(NSString *)password;

@end
