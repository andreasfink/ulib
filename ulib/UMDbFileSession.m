//
//  UMDbFileSession.m
//  ulibdb
//
//  Created by Andreas Fink on 18.06.14.
//
//

#import "UMDbFileSession.h"
#import "UMDbQuery.h"
#import "UMDbResult.h"
#import <ulib/ulib_config.h>

@implementation UMDbFileSession

@synthesize rootPath;
@synthesize loghandler;

+(NSString *)paramsToJson:(NSArray *)params fields:(NSArray *)fields withQueryCommand:(NSString *)command
{
    if(params.count != fields.count)
    {
        @throw([NSException exceptionWithName:@"INVALID_FIELD_COUNT"
                                       reason:NULL
                                     userInfo:@{
                                                @"sysmsg" : @"fieldcount does not match paramter count",
                                                @"func": @(__func__),
                                                @"obj":self
                                                }
                ]);
    }
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    dict[@"query"] = command;
    
    NSUInteger i;
    NSUInteger n = params.count;
    NSMutableDictionary *valuesDict = [[NSMutableDictionary alloc]init];
    
    for(i=0;i<n;i++)
    {
        NSString *key = fields[i];
        valuesDict[key] = params[i];
        if(i==0)
        {
            dict[@"key"] = params[i];
        }
    }
    dict[@"values"] = valuesDict;
    UMJsonWriter *writer = [[UMJsonWriter alloc]init];
    NSString *string = [writer stringWithObject:dict];
    return string;
}

+(NSString *)updateByKeyLikeForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession paramsToJson:params fields:query.fields withQueryCommand:@"update-by-key-like"];
}


+(NSString *)updateByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession paramsToJson:params fields:query.fields withQueryCommand:@"update-by-key"];
}

+(NSString *)insertByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession paramsToJson:params fields:query.fields withQueryCommand:@"insert-by-key"];
}

+(NSString *)selectByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession paramsToJson:params fields:query.fields withQueryCommand:@"select-by-key"];
}

+(NSString *)selectByKeyLikeForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession paramsToJson:params fields:query.fields withQueryCommand:@"select-by-key-like"];
}

+(NSString *)deleteByKeyForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession paramsToJson:params fields:query.fields withQueryCommand:@"delete-by-key"];
}

+(NSString *)deleteByKeyAndValueForQuery:(UMDbQuery *)query params:(NSArray *)params primaryKeyValue:(id)primaryKeyValue
{
    return [UMDbFileSession paramsToJson:params fields:query.fields withQueryCommand:@"delete-by-key-and-value"];
}


- (UMDbFileSession *)initWithPool:(UMDbPool *)p
{
    if (!p)
    {
        return nil;
    }
    self = [super initWithPool:p];
    if(self)
    {
        self.rootPath = pool.dbName;        
    }
    return self;
}

- (void)dealloc
{
    [self.logFeed info:0 withText:[NSString stringWithFormat:@"UMDbFileSession '%@'is being deallocated\n",name]];
    
    name = nil;
}

- (void) setLogHandler:(UMLogHandler *)handler
{
	if( loghandler != handler)
	{
		self.logFeed = [[UMLogFeed alloc] initWithHandler:loghandler section:@"file" subsection:@"log"];
		[self.logFeed setCopyToConsole:1];
		[self.logFeed setName:name];
	}
}


- (BOOL) connect
{
    ummutex_lock(_sessionLock);
    @try
    {
        NSFileManager *fmgr = [NSFileManager  defaultManager];
        NSError *err = NULL;
        [fmgr createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:NULL error:&err];
        if(err)
        {
            @throw([NSException exceptionWithName:@"createDirectoryAtPath_error"
                                           reason:NULL
                                         userInfo:@{
                                                    @"sysmsg" : @"createDirectoryAtPath_error",
                                                    @"func": @(__func__),
                                                    @"obj":self,
                                                    @"error":err
                                                    }
                    ]);
        }
    }
    @finally
    {
        ummutex_unlock(_sessionLock);
    }
    return YES;
}

- (void) disconnect
{
}

- (NSString *)keyToPath:(NSString *)key
{
    return [NSString stringWithFormat:@"%@/",rootPath];
}

- (NSString *)keyToFile:(NSString *)key
{
    return [NSString stringWithFormat:@"%@/%@.data",rootPath,key];
}


- (BOOL)queryWithNoResult:(NSString *)sql allowFail:(BOOL)allowFail affectedRows:(unsigned long long *)count;
{
    BOOL success = YES;
    ummutex_lock(_sessionLock);

    @try
    {
        if(count)
        {
            *count = 0;
        }
        UMJsonParser *parser = [[UMJsonParser alloc]init];
        NSDictionary *dict = [parser objectWithString:sql];
        
        NSString *queryType     = dict[@"query"];
        NSString *queryKey      = dict[@"key"];
        NSDictionary *values    = dict[@"values"];
        
        if(([queryType isEqualToString:@"insert-by-key"]) || ([queryType isEqualToString:@"update-by-key"]))
        {
            NSFileManager *fmgr = [NSFileManager  defaultManager];
            NSError *err = NULL;
            NSString *keyPath = [self keyToPath:queryKey];
            NSString *keyFile = [self keyToFile:queryKey];
            [fmgr createDirectoryAtPath:keyPath withIntermediateDirectories:YES attributes:NULL error:&err];
            if(err)
            {
                @throw([NSException exceptionWithName:@"createDirectoryAtPath_err"
                                               reason:NULL
                                             userInfo:@{
                                                        @"sysmsg" : @"createDirectoryAtPath_error",
                                                        @"func": @(__func__),
                                                        @"obj":self,
                                                        @"error":err
                                                        }
                        ]);
            }
            UMJsonWriter *writer = [[UMJsonWriter alloc]init];
            NSData *data = [writer dataWithObject:values];
            if([fmgr createFileAtPath:keyFile contents:data attributes:nil]==NO)
            {
                
            }
            if(count)
            {
                *count = 1;
            }
        }
    }
    @finally
    {
        ummutex_unlock(_sessionLock);
    }
    return success;
}

- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql allowFail:(BOOL)failPermission
{
    return [self queryWithMultipleRowsResult:sql allowFail:failPermission file:NULL line:0];
}

- (UMDbResult *)queryWithMultipleRowsResult:(NSString *)sql
                                  allowFail:(BOOL)failPermission
                                       file:(const char *)file
                                       line:(long)line
{
    UMDbResult *res=NULL;
    ummutex_lock(_sessionLock);
    @try
    {
        UMJsonParser *parser = [[UMJsonParser alloc]init];
        NSDictionary *dict = [parser objectWithString:sql];
        
        NSString *queryType     = dict[@"query"];
        NSString *queryKey      = dict[@"key"];

        if([queryType isEqualToString:@"select-by-key"])
        {
            NSString *keyFile = [self keyToFile:queryKey];
            NSData *data = [NSData dataWithContentsOfFile:keyFile];
            dict = [parser objectWithData:data];
            if(file)
            {
                res = [[UMDbResult alloc]initForFile:file line:line];
            }
            else
            {
                res = [[UMDbResult alloc]init];
            }
            NSMutableArray *a = [[NSMutableArray alloc]init];

            long idx=0;
            for(NSString *key in dict)
            {
                NSString *val = dict[key];
                [res setColumName:key forIndex:idx++];
                [a addObject:val];
            }
            [res setRow:a forIndex:0];
        }
    }
    @finally
    {
        ummutex_unlock(_sessionLock);
    }
    return res;
}

- (BOOL) ping
{
    return YES;
}

@end
