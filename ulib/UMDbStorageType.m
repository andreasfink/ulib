//
//  UMStorageType.m
//  ulibdb
//
//  Created by Andreas Fink 17.02.14.
//
//

#import "UMDbStorageType.h"

const char *dbstoragetype_to_string(UMDbStorageType s)
{
	switch(s)
	{
        case UMDBSTORAGE_JSON:
            return "json";
        case UMDBSTORAGE_HASH:
            return "hash";
        default:
            return "null";
	}
}

UMDbStorageType  UMStorageTypeFromString(NSString *str)
{
    if([str caseInsensitiveCompare:@"json"]==0)
    {
        return UMDBSTORAGE_JSON;
    }
    else if([str caseInsensitiveCompare:@"hash"]==0)
    {
        return UMDBSTORAGE_HASH;
    }
    return UMDBSTORAGE_NULL;
}

