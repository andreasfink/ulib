//
//  UMRpcMacros.h
//  ulibasn1
//
//  Created by Andreas Fink on 22.08.2026.
//


#define APPEND_STRING(tag,string,array)    \
if(string) \
{   \
    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithString:string]; \
    u.asn1_tag.tagNumber = tag; \
    u.asn1_tag.tagClass = UMASN1Class_ContextSpecific;  \
    [array addObject:u]; \
}

#define APPEND_OBJECT(tag,object,array)    \
if(object) \
{   \
    object.asn1_tag.tagNumber = tag; \
    object.asn1_tag.tagClass = UMASN1Class_ContextSpecific;  \
    [array addObject:object]; \
}


#define APPEND_NUMBER(tag,integer,array)    \
if(integer) \
{   \
    UMASN1Integer *i = [[UMASN1Integer alloc]initWithNumber:integer]; \
    i.asn1_tag.tagNumber = tag; \
    i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;  \
    [array addObject:i]; \
}

#define APPEND_REAL(tag,r,array)    \
if(r) \
{   \
    UMASN1Real *i = [[UMASN1Real alloc]initWithNumber:r]; \
    i.asn1_tag.tagNumber = tag; \
    i.asn1_tag.tagClass = UMASN1Class_ContextSpecific;  \
    [array addObject:i]; \
}


#define CHECK_OBJECT(tag,var,obj,TYPE) \
if((obj.asn1_tag.tagClass==UMASN1Class_ContextSpecific) && (o.asn1_tag.tagNumber==tag)) \
{ \
    TYPE *u = [[TYPE alloc]initWithASN1Object:obj context:context]; \
    var  = u; \
}

#define CHECK_STRING(tag,string,obj) \
if((obj.asn1_tag.tagClass==UMASN1Class_ContextSpecific) && (o.asn1_tag.tagNumber==tag)) \
{ \
    UMASN1UTF8String *u = [[UMASN1UTF8String alloc]initWithASN1Object:obj context:context]; \
    string = u.stringValue; \
}

#define CHECK_NUMBER(tag,integer,obj) \
if((obj.asn1_tag.tagClass==UMASN1Class_ContextSpecific) && (o.asn1_tag.tagNumber==tag)) \
{ \
    UMASN1Integer *i = [[UMASN1Integer alloc]initWithASN1Object:obj context:context]; \
    integer = i.number; \
}

#define CHECK_REAL(tag,r,obj) \
if((obj.asn1_tag.tagClass==UMASN1Class_ContextSpecific) && (o.asn1_tag.tagNumber==tag)) \
{ \
    UMASN1Real *ro = [[UMASN1Real alloc]initWithASN1Object:obj context:context]; \
    r = ro.number; \
}


#define DAPPEND_STRING(name,string,d)   if(string)  { d[name] = string; }
#define DAPPEND_NUMBER(name,integer,d)  if(integer) { d[name] = integer; }
#define DAPPEND_REAL(name,r,d)          if(r)       { d[name] = r; }
#define DAPPEND_OBJECT(name,r,d)        if(r)       { d[name] = r.objectValue; }
