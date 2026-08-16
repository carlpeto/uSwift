#ifndef SWIFT_STDLIB_SHIMS_GLOBALOBJECTS_H_
#define SWIFT_STDLIB_SHIMS_GLOBALOBJECTS_H_

// #include "../uSwiftShims/SwiftStdint.h"
// #include "../uSwiftShims/SwiftStdbool.h"
// #include "../uSwiftShims/Visibility.h"

#include <stdint.h>

#ifdef __cplusplus
namespace swift { extern "C" {
#endif

#if __clang__
# define SWIFT_ALLOWED_RUNTIME_GLOBAL_CTOR_BEGIN \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wglobal-constructors\"")
# define SWIFT_ALLOWED_RUNTIME_GLOBAL_CTOR_END \
    _Pragma("clang diagnostic pop")
#else
# define SWIFT_ALLOWED_RUNTIME_GLOBAL_CTOR_BEGIN
# define SWIFT_ALLOWED_RUNTIME_GLOBAL_CTOR_END
#endif

typedef uint64_t __swift_uint64_t;
typedef bool __swift_bool;

#  define SWIFT_EXPORT_ATTRIBUTE __attribute__((__visibility__("default")))

#if defined(__cplusplus)
#define SWIFT_RUNTIME_EXPORT extern "C" SWIFT_EXPORT_ATTRIBUTE
#else
#define SWIFT_RUNTIME_EXPORT SWIFT_EXPORT_ATTRIBUTE
#endif

#define SWIFT_RUNTIME_STDLIB_API       SWIFT_RUNTIME_EXPORT
#define SWIFT_RUNTIME_STDLIB_SPI       SWIFT_RUNTIME_EXPORT

struct _SwiftHashingParameters {
  __swift_uint64_t seed0;
  __swift_uint64_t seed1;
  __swift_bool deterministic;
};
  
SWIFT_RUNTIME_STDLIB_API
struct _SwiftHashingParameters _swift_stdlib_Hashing_parameters;

#ifdef __cplusplus

}} // extern "C", namespace swift
#endif

#endif