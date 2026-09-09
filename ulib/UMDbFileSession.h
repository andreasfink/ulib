//
//  UMDbFileSession.h
//  ulibdb
//
//  Created by Andreas Fink on 18.06.14.
//
//

#import <ulib/UMDbSession.h>

@interface UMDbFileSession : UMDbSession
{
    NSString            *rootPath;
    UMLogHandler        *loghandler;
}


@property(readwrite,strong)		NSString			*rootPath;
@property(readwrite,strong)		UMLogHandler		*loghandler;

+(NSString *)updateByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)updateByKeyLikeForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)insertByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)selectByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)selectByKeyLikeForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)deleteByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;
+(NSString *)deleteByKeyAndValueForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue;

@end
