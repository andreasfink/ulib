//
//  UMConfigDatabasePool.h
//  ulib
//
//  Created by Andreas Fink on 26.11.2026.
//

#import <ulib/UMConfigObject.h>


@interface UMConfigDatabasePool : UMConfigObject
{
    NSString *_host;
    NSString *_databaseName;
    NSString *_driver;
    NSString *_user;
    NSString *_pass;
    NSNumber *_port;
    NSNumber *_minSessions;
    NSNumber *_maxSessions;
    NSString *_socket;
    NSNumber *_pingIntervall;
    NSString *_storageType;
    NSString *_version;
    NSString *_encryptionKey;
}

@property(readwrite,strong,atomic)  NSString *host;
@property(readwrite,strong,atomic)  NSString *databaseName;
@property(readwrite,strong,atomic)  NSString *driver;
@property(readwrite,strong,atomic)  NSString *user;
@property(readwrite,strong,atomic)  NSString *pass;
@property(readwrite,strong,atomic)  NSNumber *port;
@property(readwrite,strong,atomic)  NSNumber *minSessions;
@property(readwrite,strong,atomic)  NSNumber *maxSessions;
@property(readwrite,strong,atomic)  NSString *socket;
@property(readwrite,strong,atomic)  NSNumber *pingIntervall;
@property(readwrite,strong,atomic)  NSString *storageType;
@property(readwrite,strong,atomic)  NSString *version;
@property(readwrite,strong,atomic)  NSString *encryptionKey;

+ (NSString *)groupName;
- (NSString *)groupName;

- (UMConfigDatabasePool *)initWithConfig:(NSDictionary *)dict;

@end
