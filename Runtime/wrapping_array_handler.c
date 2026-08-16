#include "../uSwiftShims/uswiftRuntime.h"

void _microswift_array_out_of_bounds(int* index, int lowerBound, int upperBound) {
	if (*index<lowerBound || upperBound == 0) {
		*index = lowerBound;
	} else if (*index>=upperBound) {
		*index = upperBound-1;
	}
};
