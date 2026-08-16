#include "missing_runtime_stub.h"
#include <stdlib.h>

void _avr_shutdown();

static _Bool (* _handler)(const char * fnName) = 0;

void missing_runtime_function(const char * fnName) {
	if (_handler) {
		if (!(*_handler)(fnName)) {
			_avr_shutdown();
		}
	} else {
		_avr_shutdown();
	}
}

void failing_runtime_function() {
	if (_handler) {
		if (!(*_handler)("failing runtime")) {
			_avr_shutdown();
		}
	} else {
		_avr_shutdown();
	}
}

void runtime_abort_function() {
	if (_handler) {
		if (!(*_handler)("runtime abort")) {
			_avr_shutdown();
		}
	} else {
		abort();
	}
}

// void __sync_lock_test_and_set_8() {
// 	// these are catastrophically wrong, only included to make fake programs link
// 	missing_runtime_function("__sync_lock_test_and_set_8");
// }

// void __sync_val_compare_and_swap_8() {
// 	// these are catastrophically wrong, only included to make fake programs link
// 	missing_runtime_function("__sync_val_compare_and_swap_8");
// }

void set_runtime_handler_callback(_Bool (* handler)(const char * fnName)) {
	_handler = handler;
}

void clear_runtime_handler_callback() {
	_handler = 0;
}