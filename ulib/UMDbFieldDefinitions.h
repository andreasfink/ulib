//
//  UMDbFieldDefinitions.h
//  smsclient
//
//  Created by Andreas Fink on 03.12.12.
//  Copyright © 2017 Andreas Fink (andreas@fink.org). All rights reserved.
//


#ifndef UMDbFieldDefinitions_H
#define UMDbFieldDefinitions_H  1
/* The use of dbFieldDef structure is DEPRECIATED. Use the new UMDbFieldDefinition / UMDbTableDefinition instead */

typedef enum db_fieldIndex
{
    DB_NOT_INDEXED = 0,
    DB_INDEXED = 1,
    DB_PRIMARY_INDEX = 2,
    DB_INDEXED_BUT_NOT_FOR_ARCHIVE = 3,

} dbFieldIndex;

typedef enum db_fieldType
{
    DB_FIELD_TYPE_STRING,
    DB_FIELD_TYPE_SMALL_INTEGER,
    DB_FIELD_TYPE_INTEGER,
    DB_FIELD_TYPE_BIG_INTEGER,
    DB_FIELD_TYPE_TEXT,
    DB_FIELD_TYPE_TIMESTAMP_AS_STRING,
    DB_FIELD_TYPE_NUMERIC,
    DB_FIELD_TYPE_BLOB,
    DB_FIELD_TYPE_VARCHAR,
    DB_FIELD_TYPE_END,
} dbFieldType;

typedef struct dbFieldDef
{
	const char      *name;
    const char      *defaultValue;
    BOOL            canBeNull;
	dbFieldIndex	indexed; /* 0 = no, 1 = yes, 2 = primary key */
    dbFieldType     fieldType;
    int             fieldSize;
    int             fieldDecimals;
    SEL             setter;
    SEL             getter;
    int             tagId;
} dbFieldDef;



#endif
