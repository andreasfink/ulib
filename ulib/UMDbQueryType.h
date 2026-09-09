//
//  UMDbQueryType.h
//  ulibdb.framework
//
//  Created by Andreas Fink on 25.10.11.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.

#import <ulib/ulib.h>


typedef enum UMDbQueryType
{
    UMDBQUERYTYPE_UNKNOWN,
    UMDBQUERYTYPE_SELECT,
    UMDBQUERYTYPE_INSERT,
    UMDBQUERYTYPE_UPDATE,
    UMDBQUERYTYPE_INCREASE,
    UMDBQUERYTYPE_INCREASE_BY_KEY,
    UMDBQUERYTYPE_SHOW,
    UMDBQUERYTYPE_DELETE,
    UMDBQUERYTYPE_INSERT_BY_KEY, /* this is a simple insert with the first field being the key */
    UMDBQUERYTYPE_INSERT_BY_KEY_TO_LIST,
    UMDBQUERYTYPE_UPDATE_BY_KEY, /* this is a simple update with the primarykey field matching */
    UMDBQUERYTYPE_SELECT_BY_KEY, /* this is a simple select with the first field being the key */
    UMDBQUERYTYPE_SELECT_BY_KEY_LIKE, /* this is a simple select with the first field being the key */
    UMDBQUERYTYPE_SELECT_BY_KEY_FROM_LIST,
    UMDBQUERYTYPE_SELECT_LIST_BY_KEY_LIKE,
    UMDBQUERYTYPE_DELETE_BY_KEY, /* this is a simple delete with the first field being the key */
    UMDBQUERYTYPE_DELETE_IN_LIST_BY_KEY_AND_VALUE,
    UMDBQUERYTYPE_EXPIRE_KEY,
    UMREDISTYPE_GET,
    UMREDISTYPE_SET,
    UMREDISTYPE_DEL,
    UMREDISTYPE_UPDATE,
    UMREDISTYPE_HGET,
    UMREDISTYPE_HSET,

} UMDbQueryType;

NSString *StringFromQueryType(UMDbQueryType d);
UMDbQueryType   UMQueryTypeFromString(NSString *sql);
