#include "../uSwiftShims/interrupt_helper.h"

// https://www.theguardian.com/environment/2019/dec/20/family-finds-owl-christmas-tree-hugging-trunk
// for no reason, because it's cute

// this set of seemingly pointless functions serve only to short circuit
// optimisations on accessing global variables in swift, for the purpose of
// sharing them between ISRs and the main loop.
// not very efficient, in the long run we want to find a more elegant solution
// by rooting around in the optimiser but it will do for now.
_Bool _readSharedGlobalBool(_Bool test) {
	return test;
}

unsigned char _readSharedGlobalUInt8(unsigned char test) {
	return test;
}

char _readSharedGlobalInt8(char test) {
	return test;
}

unsigned short _readSharedGlobalUInt16(unsigned short test) {
	return test;
}

short _readSharedGlobalInt16(short test) {
	return test;
}

uint32_t _readSharedGlobalUInt32(uint32_t test) {
	return test;
}

int32_t _readSharedGlobalInt32(int32_t test) {
	return test;
}

unsigned long long _readSharedGlobalUInt64(unsigned long long test) {
	return test;
}

long long _readSharedGlobalInt64(long long test) {
	return test;
}

float _readSharedGlobalFloat(float test) {
	return test;
}