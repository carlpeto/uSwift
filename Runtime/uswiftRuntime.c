#include "../uSwiftShims/uswiftRuntime.h"

_Bool _main_loop_running = 1;

_Bool main_loop_running() {
	return _main_loop_running;
}

// these are hooks that can be overridden and caught
void __attribute__((weak)) _microswift_array_out_of_bounds(int* index, int lowerBound, int upperBound) {};
void __attribute__((weak)) _microswift_class_creation_attempt_oom(int size) {}
