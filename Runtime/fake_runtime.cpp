extern "C" {
	#include "missing_runtime_stub.h"

// Symbols referenced from uSwift module...

// ld.lld: error: undefined symbol: _swift_isClassOrObjCExistentialType
// ld.lld: error: undefined symbol: _swift_stdlib_getDefaultErrorCode
// ld.lld: error: undefined symbol: swift_getErrorValue
// ld.lld: error: undefined symbol: swift_isUniquelyReferenced_nonNull_native
// ld.lld: error: undefined symbol: swift_isOptionalType
// ld.lld: error: undefined symbol: swift_arrayAssignWithTake
// ld.lld: error: undefined symbol: swift_arrayDestroy
// ld.lld: error: undefined symbol: swift_getEnumCaseMultiPayload
// ld.lld: error: undefined symbol: swift_initEnumMetadataMultiPayload
// ld.lld: error: undefined symbol: swift_storeEnumTagMultiPayload
// ld.lld: error: undefined symbol: _swift_makeAnyHashableUpcastingToHashableBaseType


// if annotated with FAKE_RUNTIME a stub will be emitted that is either a noop
// or a trap/hang which flashes a telltale on pin 13 to flash the LED on a standard *duino uno
// note, it's weak linked so can exist at the same time as a genuine runtime implementation
// this will allow a modular approach such as libSwift.a containing a stubbed runtime
// and libSwiftExperimentalRuntime.a containing the experimental uSwiftRuntime that can be
// linked if and only if desired

#define FAKE_RUNTIME(fn) void __attribute__((weak)) fn() { missing_runtime_function(#fn); }
#define RUNTIME(fn) // implemented in uSwift runtime
#include "fake_runtime.def"
#undef FAKE_RUNTIME
#undef RUNTIME

// ld.lld: error: undefined symbol: $syycWV
// ld.lld: error: undefined symbol: $sytN
// ld.lld: error: undefined symbol: __heap_end

	// typedef struct ValueWitnessTable {
	// 	int dummy1;
	// 	unsigned int dummy2;
	// } ValueWitnessTable;

	// these are all garbage symbols for the linker
	// using them is probably catastrophic
	// extern const ValueWitnessTable $sBi16_WV = {0, 0};
	// extern const ValueWitnessTable $sBi32_WV = {0, 0};
	// extern const ValueWitnessTable $sBi64_WV = {0, 0};
	// extern const ValueWitnessTable $sBi8_WV = {0, 0};
	// extern const ValueWitnessTable $sBoWV = {0, 0};
	// extern const ValueWitnessTable $sypN = {0, 0};
	// extern const ValueWitnessTable $sytWV = {0, 0};
	// extern const ValueWitnessTable $syycWV = {0, 0};

	// // this should be type metadata, no idea what should really be making it
	// extern const ValueWitnessTable $sytN = {0, 0};

	// $sBi32_WV
	// $sBi64_WV
	// $sBi8_WV
	// $sypN
	// $sytWV

}
