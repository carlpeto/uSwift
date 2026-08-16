// copyright (c) Carl Peto 2017-2019
// all rights reserved

#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>

// this is just for the malloc debug flag
#include "../uSwiftShims/debug_malloc.h"

// our version is degraded, it has no thread safety
// but that should be ok for an arduino uno
// only an interrupt handler could throw us off
void swift_once(size_t *predicate, void (*function)(void *), void * context) {
// note: changed the type to be the same as SizeTy... in codegen it uses OnceTy
// but that's defined as the same with a union in IRGenModule.h around line 598 or so

	if (*predicate == 0) {
    *predicate = -1;

    function(context);
  }
}

/*****
* Swift 3.1 compatible runtime
******/
// ignores alignment
static void *__swift_slowAlloc(size_t size, size_t alignMask) {
	return malloc(size);
}

void *(*_swift_slowAlloc)(size_t size, size_t alignMask) = __swift_slowAlloc;

// ignores alignment
static void __swift_slowDealloc(void *ptr, size_t bytes, size_t alignMask) {
    free(ptr);
}

void (*_swift_slowDealloc)(void *ptr, size_t bytes, size_t alignMask) = __swift_slowDealloc;


/*****
* Swift 5.1 compatible runtime
******/

// debug versions with strong symbols are in debug_malloc.c
void __attribute__((weak)) *swift_slowAlloc(size_t size, size_t alignMask) {
    return malloc(size);
}

void __attribute__((weak)) *swift_coroFrameAlloc(size_t size, unsigned long long typeId) {
    return malloc(size);
}

// ignores alignment
void __attribute__((weak)) swift_slowDealloc(void *ptr, size_t bytes, size_t alignMask) {
    free(ptr);
}

// enum class ExclusivityFlags : uintptr_t;
// template <typename Runtime> struct TargetValueBuffer;
// struct InProcess;
// using ValueBuffer = TargetValueBuffer<InProcess>;

// // exclusivity checks disabled
// void swift_beginAccess(void *pointer, ValueBuffer *buffer,
//                               ExclusivityFlags flags, void *pc) {
// 	if (pointer) {
// 	  // If exclusivity checking is disabled, record in the access buffer that we
// 	  // didn't track anything. pc is currently undefined in this case.
// 	  Access *access = reinterpret_cast<Access*>(buffer);
// 	  access->Pointer = nullptr;
// 	}
// }

// /// End tracking a dynamic access.
// void swift_endAccess(ValueBuffer *buffer) {
// }
