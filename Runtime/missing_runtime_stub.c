#include "missing_runtime_stub.h"
#include <stdlib.h>

void missing_runtime_function(const char * fnName) {
	// noop
}

void failing_runtime_function() {
	// noop
}

void runtime_abort_function() {
	abort();
}

void set_runtime_handler_callback(_Bool (* handler)(const char * fnName)) {
	// noop
}

void clear_runtime_handler_callback() {
	// noop
}

// void __sync_lock_test_and_set_8() {
// 	// these are catastrophically wrong, only included to make fake programs link
// 	missing_runtime_function("__sync_lock_test_and_set_8");
// }

// void __sync_val_compare_and_swap_8() {
// 	// these are catastrophically wrong, only included to make fake programs link
// 	missing_runtime_function("__sync_val_compare_and_swap_8");
// }