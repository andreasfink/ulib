//
//  UMMemoryHeader.m
//  ulib
//
//  Created by Andreas Fink on 10.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//

/*
   UMMemoryHeader is a structure in memory which can be prepended to any buffer allocated
   from C. This one allows these memory blocks to be accounted for in UMObjectStat.
   Instead of calling malloc() you simply call ummalloc() and you get a pointer to your data.
   you must call umfree() to free such a block.
   the pointer is actually offset by the header so pointer - header size is the header
*/

#import <ctype.h>
#import <sys/types.h>
#import <stdio.h>
#import <stdint.h>

#define UMMEMORY_HEADER_MAGIC				0xBACABACA
#define UMMEMORY_HEADER_STATUS_VALID		0xAA00AA00
#define UMMEMORY_HEADER_STATUS_DESTROYED	0xAAFFAAFF
#define UMMEMORY_HEADER_STATUS_RESIZED		0xAA11AA11


typedef struct  ummemory_header
{
	const char	*magicName; /* usually 64bit pointer */
	size_t      size;		/* usually 64bit counter */
	size_t		relativeOffset;	/* relative position of magicName cstring relative to the beginning of the header */
	uint32_t    status;		/* valid , resized, destroyed */
	uint32_t    magic;
} ummemory_header;



void *ummemory_header_to_data(ummemory_header *h);
ummemory_header *ummemory_data_to_header(void *ptr);

void umpointer_check_real(void *ptr,const char *file,const long line, const char *function);
void *umcalloc_real(size_t count,size_t size,const char *file,const long line, const char *function);
void *ummalloc_real(size_t size,const char *file,const long line, const char *function);
void *umrealloc_real(void *ptr, size_t size,const char *file,const long line, const char *function);
void umfree_real(void *ptr,const char *file,const long line, const char *function);
char *umstrdup_real(const char *str,const char *file,const long line, const char *function);

#define	umcalloc(count,size)		umcalloc_real(count,size,__FILE__,__LINE__,__func__)
#define	ummalloc(count)				ummalloc_real(count,__FILE__,__LINE__,__func__)
#define	umrealloc(ptr,size)			umrealloc_real(ptr,size,__FILE__,__LINE__,__func__)
#define	umfree(ptr)					umfree_real(ptr,__FILE__,__LINE__,__func__)
#define	umpointer_check(ptr)		umpointer_check_real(ptr,__FILE__,__LINE__,__func__)
#define	umstrdup(str)				umstrdup_real(str,__FILE__,__LINE__,__func__)


/* these are actually implemented in UMObject.m  but these C functions might be used from people
 directly importing only UMMemoryHeader.h in pure C programms */

extern void umobject_stat_verify_ascii_name(const char *asciiName);
extern void umobject_stat_external_increase_name(const char *asciiName);
extern void umobject_stat_external_decrease_name(const char *asciiName);
extern const char *umobject_get_constant_name_pointer(const char *file, const long line, const char *func);
