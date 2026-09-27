//
//  UMDbQueryType.m
//  ulibdb.framework
//
//  Created by Andreas Fink on 25.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/UMObject.h>
#import <ulib/UMDbQueryType.h>
#import <ulib/ulib_config.h>

NSString *StringFromQueryType(UMDbQueryType d)
{
    switch(d)
    {
        case UMDBQUERYTYPE_SELECT:
            return @"SELECT";
            break;
        case UMDBQUERYTYPE_SELECT_BY_KEY:
            return @"SELECT_BY_KEY";
            break;
        case UMDBQUERYTYPE_INSERT:
            return @"INSERT";
            break;
        case UMDBQUERYTYPE_INSERT_BY_KEY:
            return @"INSERT_BY_KEY";
            break;
        case UMDBQUERYTYPE_INSERT_BY_KEY_TO_LIST:
            return @"INSERT_BY_KEY";
            break;
        case UMDBQUERYTYPE_UPDATE:
            return @"UPDATE";
            break;
        case UMDBQUERYTYPE_UPDATE_BY_KEY:
            return @"UPDATE_BY_KEY";
            break;
        case UMDBQUERYTYPE_SHOW:
            return @"SHOW";
            break;
        case UMDBQUERYTYPE_DELETE:
            return @"DELETE";
            break;
        case UMDBQUERYTYPE_DELETE_BY_KEY:
            return @"DELETE_BY_KEY";
            break;
        case UMDBQUERYTYPE_EXPIRE_KEY:
            return @"EXPIRE_KEY";
            break;
        case UMREDISTYPE_GET:
            return @"GET";
            break;
        case UMREDISTYPE_SET:
            return @"SET";
            break;
        case UMREDISTYPE_UPDATE:
            return @"REDIS";
            break;
        case UMREDISTYPE_DEL:
            return @"DEL";
            break;
        default:
            return @"UNKNOWN";
            break;
    }
}

UMDbQueryType   UMQueryTypeFromString(NSString *sql)
{
    if([[sql substringToIndex:6] caseInsensitiveCompare:@"SELECT"]==0)
        return UMDBQUERYTYPE_SELECT;
    else if([[sql substringToIndex:6] caseInsensitiveCompare:@"UPDATE"]==0)
        return UMDBQUERYTYPE_UPDATE;
    else if([[sql substringToIndex:6] caseInsensitiveCompare:@"INSERT"]==0)
        return UMDBQUERYTYPE_INSERT;
    else if([[sql substringToIndex:4] caseInsensitiveCompare:@"SHOW"]==0)
        return UMDBQUERYTYPE_SHOW;
    else if([[sql substringToIndex:4] caseInsensitiveCompare:@"DELETE"]==0)
        return UMDBQUERYTYPE_DELETE;
    return UMDBQUERYTYPE_UNKNOWN;
}
