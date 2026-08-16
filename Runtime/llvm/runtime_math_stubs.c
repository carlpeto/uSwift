#include <math.h>
#include <stdint.h>

int16_t float_to_int16(float f) {
  float ft = trunc(f);
  return (int16_t)ft;
}

int32_t float_to_int32(float f) {
  float ft = trunc(f);
  return (int32_t)ft;
}

int64_t float_to_int64(float f) {
  float ft = trunc(f);
  return (int64_t)ft;
}

// classic gcc runtime library shift routines translated to int types
// as if 'int' was 32 bit, because this seems to match what llvm expects


// disabled...
// __ashldi3
// __ashrdi3
// __lshrdi3
// __divdi3
// __moddi3
// __mulsi3
// __muldi3
// ...AGAIN because not working again... and
// cause an infinite loop again... sigh... rough transitions
// it would be good to finally eliminte llvm deps on gcc's libc and libgcc
// they cause a lot of trouble


int32_t __ashlsi3 (int32_t a, int b) {
	return a << b;
}

// int64_t __ashldi3 (int64_t a, int b) {
// 	return a << (int64_t)b;
// }

// int128_t __ashlti3 (int128_t a, int32_t b) {
// 	return a << (int128_t)b;
// }
// These functions return the result of shifting a left by b bits. 0s are shifted in on the right.

int32_t __ashrsi3 (int32_t a, int b) {
	return a >> (int32_t)b;
}

// int64_t __ashrdi3 (int64_t a, int b) {
// 	return a >> (int64_t)b;
// }

// int128_t __ashrti3 (int128_t a, int32_t b) {
// 	return a >> (int128_t)b;
// }
// These functions return the result of arithmetically shifting a right by b bits. The result is sign extended on the left
// by b bits.

int32_t __lshrsi3 (int32_t a, int b) {
	return (int32_t)((uint32_t)a >> (uint32_t)b);
}

// int64_t __lshrdi3 (int64_t a, int b) {
// 	return (int64_t)((uint64_t)a >> (uint64_t)b);
// }

// int128_t __lshrti3 (int128_t a, int32_t b) {
// 	return (int128_t)((uint128_t)a >> (uint128_t)b);
// }
// These functions return the result of logically shifting a right by b bits. Meaning 0s are shifted in on the left hand side.



// Divisions and multiplications

int32_t __divsi3 (int32_t a, int32_t b) {
	return a / b;
}

// int64_t __divdi3 (int64_t a, int64_t b) {
// 	return a / b;
// }

// int128_t __divti3 (int128_t a, int128_t b) {
// 	return a / b;
// }

int32_t __modsi3 (int32_t a, int32_t b) {
	return a % b;
}

// int64_t __moddi3 (int64_t a, int64_t b) {
// 	return a % b;
// }

// int128_t __modti3 (int128_t a, int128_t b) {
// 	return a % b;
// }

// int32_t __mulsi3 (int32_t a, int32_t b) {
// 	return a * b;
// }

// int64_t __muldi3 (int64_t a, int64_t b) {
// 	return a * b;
// }

// int128_t __multi3 (int128_t a, int128_t b) {
// 	return a * b;
// }

uint32_t __udivsi3 (uint32_t a, uint32_t b) {
	return a / b;
}

// unsigned long __udivdi3 (unsigned long a, unsigned long b) {
// 	return a / b;
// }

// uint128_t __udivti3 (uint128_t a, uint128_t b) {
// 	return a / b;
// }

// double __truncxfdf2 (long double a) {
// 	return (double)a;
// }

// double __trunctfdf2 (long double a)

// float __truncxfsf2 (long double a)

// float __trunctfsf2 (long double a)

float __truncdfsf2 (double a) {
	return (float)a;
}

// fix for weirdness in avr gcc
// #undef ceilf
// #undef floorf
// #undef fmaf
// #undef fmodf
// #undef remainderf
// #undef rintf
// #undef roundf
// #undef truncf

// float ceilf(float x) {
// 	return ceil(x);
// }

// float floorf(float x) {
// 	return floor(x);
// }

// float fmaf(float x, float y, float z) {
// 	return fmaf(x, y, z);
// }

// float fmodf(float x, float y) {
// 	return fmod(x, y);
// }

// float remainderf(float x, float y) {
// 	// this has the wrong rounding but will do for now
// 	return fmod(x, y);
// }

// float rintf(float x) {
// 	// this has the wrong rounding but will do for now
// 	return round(x);
// }

// float roundf(float x) {
// 	return round(x);
// }

// float truncf(float x) {
// 	return trunc(x);
// }