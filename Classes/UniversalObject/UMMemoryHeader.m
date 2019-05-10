//
//  UMMemoryHeader.m
//  ulib
//
//  Created by Andreas Fink on 10.05.19.
//  Copyright © 2019 Andreas Fink (andreas@fink.org). All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UMMemoryHeader.h"
#import "UMConstantStringsDict.h"
#include <assert.h>

extern void umobject_stat_external_increase_name(const char *cname);
extern void umobject_stat_external_decrease_name(const char *cname);

extern const char *umobject_get_constant_name_pointer(const char *file, const long line, const char *func);
static void ummemory_header_init(ummemory_header *h, const char *file, long line, const char *function,size_t size);
static void ummemory_header_destroy(ummemory_header *h);
extern const char *umobject_get_constant_name_pointer(const char *file, const long line, const char *func);
static void ummemory_header_init(ummemory_header *h, const char *file, long line, const char *function,size_t size);
static void ummemory_header_destroy(ummemory_header *h);
static ssize_t ummemory_header_size_increase(ssize_t in);

static void ummemory_header_init(ummemory_header *h, const char *file, long line, const char *function,size_t size)
{
	if(h)
	{
		memset((void *)h,0x00,sizeof(ummemory_header));
		h->magicName = umobject_get_constant_name_pointer(file,line,function);
		h->size = size;
		h->relativeOffset = h->magicName - (char *)h;
		h->status = UMMEMORY_HEADER_STATUS_VALID;
		h->magic  = UMMEMORY_HEADER_MAGIC;
		umobject_stat_external_increase_name(h->magicName);
	}
}

static void ummemory_header_destroy(ummemory_header *h)
{
	if(h)
	{
		assert(h->magic == UMMEMORY_HEADER_MAGIC);
		assert( (h->status == UMMEMORY_HEADER_STATUS_VALID) ||
			   (h->status == UMMEMORY_HEADER_STATUS_RESIZED));
		umobject_stat_external_decrease_name(h->magicName);
		h->status = UMMEMORY_HEADER_STATUS_DESTROYED;
	}
}


static ssize_t ummemory_header_size_increase(ssize_t in)
{
	return in + sizeof(ummemory_header);
}

void *ummemory_header_to_data(ummemory_header *h)
{
	if(h==NULL)
	{
		return NULL;
	}

	assert(h->magic == UMMEMORY_HEADER_MAGIC);
	assert( (h->status == UMMEMORY_HEADER_STATUS_VALID) ||
		   (h->status == UMMEMORY_HEADER_STATUS_RESIZED));
	uint8_t *ptr = (uint8_t *)h;
	ptr += sizeof(ummemory_header);
	return ptr;
}

ummemory_header *ummemory_data_to_header(void *ptr)
{
	if(ptr==NULL)
	{
		return NULL;
	}

	uint8_t *p = ptr;
	p -= sizeof(ummemory_header);
	ummemory_header *h = (ummemory_header *)p;
	assert(h->magic == UMMEMORY_HEADER_MAGIC);
	assert( (h->status == UMMEMORY_HEADER_STATUS_VALID) ||
		   (h->status == UMMEMORY_HEADER_STATUS_RESIZED));
	return h;
}


void umpointer_check_real(void *ptr,const char *file,const long line, const char *function)
{
	if(ptr==NULL)
	{
		return;
	}
	ummemory_header *h = ummemory_data_to_header(ptr);
	assert(h->magic == UMMEMORY_HEADER_MAGIC);
	assert( (h->status == UMMEMORY_HEADER_STATUS_VALID) ||
		   (h->status == UMMEMORY_HEADER_STATUS_RESIZED));
}



void *umcalloc_real(size_t count,size_t size,const char *file,const long line, const char *function)
{
	void *ptr=NULL;
	if(size == 0)
	{
		size = 1;
	}
	/* ANSI C89 says malloc(0) is implementation-defined.  Avoid it. */
	assert(size > 0);
	if(size<1)
	{
		return NULL;
	}
	assert(count > 0);
	if(count<1)
	{
		return NULL;
	}
	size_t total_size = ummemory_header_size_increase(count * size);
	ptr = malloc(total_size);
	memset(ptr,0x00,total_size);
	ummemory_header_init((ummemory_header *)ptr, file,line,function,count*size);
	ptr = ummemory_header_to_data(ptr);

	if (ptr == NULL)
	{
		NSLog(@"Memory allocation failed for %ld x %ld bytes, Called from %s:%ld:%s() %d %s",
			  (long)count,(long)size,file,line,function,errno, strerror(errno));
		assert(ptr != NULL);
	}
	return ptr;
}

void *ummalloc_real(size_t size,const char *file,const long line, const char *function)
{
	void *ptr = NULL;

	/* ANSI C89 says malloc(0) is implementation-defined.  Avoid it. */
	if(size == 0)
	{
		size = 1;
	}
	assert(size > 0);


	size_t total_size = ummemory_header_size_increase(size);
	void *ptr1 = malloc(total_size);
	ummemory_header_init((ummemory_header *)ptr1, file,line,function,size);
	ptr = ummemory_header_to_data(ptr1);
	if (ptr == NULL)
	{
		NSLog(@"Memory allocation failed for %ld bytes, Called from %s:%ld:%s() %d %s",
			  (long)size,file,line,function,errno, strerror(errno));
		assert(ptr != NULL);
	}
	return ptr;
}


void *umrealloc_real(void *ptr, size_t size, const char *file,const long line, const char *function)
{
	void *new_ptr = NULL;

	if(size == 0)
	{
		size = 8;
	}
	assert(size > 0);
	if(ptr==0)
	{
		return ummalloc_real(size,file,line,function);
	}

	umpointer_check(ptr);
	ummemory_header *hdr = ummemory_data_to_header(ptr);
	ptr = hdr;
	size_t newsize = ummemory_header_size_increase(size);
	new_ptr = realloc(ptr,newsize);
	if(new_ptr)
	{
		ummemory_header *new_header = (ummemory_header *)new_ptr;
		new_header->size  = size; /* size without header */
		new_header->status = UMMEMORY_HEADER_STATUS_RESIZED;
		new_header->relativeOffset = new_header->magicName - (const char *)new_header;
		new_ptr = ummemory_header_to_data(new_ptr);
	}
	else
	{
		NSLog(@"Memory reallocation failed for %ld bytes, Called from %s:%ld:%s() %d %s",
			  (long)size,file,line,function,errno, strerror(errno));
		assert(ptr != NULL);
	}
	umpointer_check(new_ptr);
	return new_ptr;
}


void umfree_real(void *ptr,const char *file,const long line, const char *function)
{
	if(ptr==NULL)
	{
		return;
	}

	umpointer_check_real(ptr,file,line,function);
	ummemory_header *hdr = ummemory_data_to_header(ptr);
	ummemory_header_destroy(hdr);
	free(hdr);
}

char *umstrdup_real(const char *str,const char *file,const long line, const char *function)
{
	char *copy = NULL;

	assert(str != NULL);
	if(str==NULL)
	{
		return NULL;
	}
	size_t len = strlen(str) + 1;
	copy = ummalloc_real((len+1),file,line,function);
	if(copy)
	{
		strcpy(copy, str);
	}
	return copy;
}



