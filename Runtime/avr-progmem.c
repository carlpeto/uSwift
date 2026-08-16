#include <avr/pgmspace.h>

const unsigned char _byteFromProgmem(const unsigned char * address) {
	return pgm_read_byte(address);
}

const unsigned int _intFromProgmem(const unsigned char * address) {
	return pgm_read_word(address);
}

// const unsigned long _dwordFromProgmem(const unsigned char * address) {
// 	return pgm_read_dword(address);
// }

// const float _floatFromProgmem(const unsigned char * address) {
// 	return pgm_read_float(address);
// }