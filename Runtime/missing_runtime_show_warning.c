#include <util/delay_basic.h>
#include <avr/io.h>
#include "missing_runtime_stub.h"

inline static void waitOneQuarterSecond() {
	for (int i = 0; i < 16; i++) {
		_delay_loop_2(0);
	}
}

inline static void waitOneSecond() {
	for (int i = 0; i < 64; i++) {
		_delay_loop_2(0);
	}
}

void missing_runtime_function(const char * fnName) {
	// enable LED on pin 13 then flash out an S.O.S. message
	DDRB |= 1<<5;
	for (;;) {
		for (int i = 0; i < 3; i++) {
			PORTB |= 1<<5;
			waitOneQuarterSecond();
			PORTB &= ~(1<<5);
			waitOneQuarterSecond();
		}

		for (int i = 0; i < 3; i++) {
			PORTB |= 1<<5;
			waitOneSecond();
			PORTB &= ~(1<<5);
			waitOneSecond();
		}
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


void failing_runtime_function() {
	// enable LED on pin 13 then flash out an S.O.S. message with an extra delay
	DDRB |= 1<<5;
	for (;;) {
		for (int i = 0; i < 3; i++) {
			PORTB |= 1<<5;
			waitOneQuarterSecond();
			PORTB &= ~(1<<5);
			waitOneQuarterSecond();
		}

		for (int i = 0; i < 3; i++) {
			PORTB |= 1<<5;
			waitOneSecond();
			PORTB &= ~(1<<5);
			waitOneSecond();
		}

		waitOneSecond();
		waitOneSecond();
	}
}

void runtime_abort_function() {
	// enable LED on pin 13 then flash out an alternating long/short telltale
	DDRB |= 1<<5;
	for (;;) {
		PORTB |= 1<<5;
		waitOneQuarterSecond();
		PORTB &= ~(1<<5);
		waitOneQuarterSecond();

		PORTB |= 1<<5;
		waitOneSecond();
		PORTB &= ~(1<<5);
		waitOneSecond();

		waitOneSecond();
		waitOneSecond();
	}
}

void set_runtime_handler_callback(_Bool (* handler)(const char * fnName)) {
	// noop
}

void clear_runtime_handler_callback() {
	// noop
}
