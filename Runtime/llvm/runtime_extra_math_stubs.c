#include <math.h>
#include <stdint.h>

#undef ceilf
#undef floorf
#undef fmaf
#undef fmodf
#undef remainderf
#undef rintf
#undef roundf
#undef truncf

float __attribute__((weak)) ceilf(float x) {
	return ceil(x);
}

float __attribute__((weak)) floorf(float x) {
	return floor(x);
}

float __attribute__((weak)) fmaf(float x, float y, float z) {
	return fmaf(x, y, z);
}

float __attribute__((weak)) fmodf(float x, float y) {
	return fmod(x, y);
}

float __attribute__((weak)) remainderf(float x, float y) {
	// this has the wrong rounding but will do for now
	return fmod(x, y);
}

float __attribute__((weak)) rintf(float x) {
	// this has the wrong rounding but will do for now
	return round(x);
}

float __attribute__((weak)) roundf(float x) {
	return round(x);
}

float __attribute__((weak)) truncf(float x) {
	return trunc(x);
}