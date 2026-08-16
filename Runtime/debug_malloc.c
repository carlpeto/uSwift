#include "../uSwiftShims/debug_malloc.h"
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>

#define MALLOC_DEBUG_BUFFER_SIZE 31
static char _malloc_debug_buffer[MALLOC_DEBUG_BUFFER_SIZE];
static void (* __nullable _malloc_debug_handler)(void * __nonnull buffer) = 0;

void _setMallocDebugHandler(void (* __nullable handler)(void * __nonnull buffer)) {
    _malloc_debug_handler = handler;
}

void *swift_slowAlloc(size_t size, size_t alignMask) {
	void *buffer = malloc(size);

    if (_malloc_debug_handler) {
        snprintf(_malloc_debug_buffer, MALLOC_DEBUG_BUFFER_SIZE, "malloc: %d - %p", size, buffer);
        _malloc_debug_handler(_malloc_debug_buffer);
    }

    return buffer;
}

// ignores alignment
void swift_slowDealloc(void *ptr, size_t bytes, size_t alignMask) {

    if (_malloc_debug_handler) {
        snprintf(_malloc_debug_buffer, MALLOC_DEBUG_BUFFER_SIZE, "free: %p", ptr);
        _malloc_debug_handler(_malloc_debug_buffer);
    }

    free(ptr);
}