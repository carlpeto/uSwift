#include "GlobalHashingObjectsOnly.h"

static swift::_SwiftHashingParameters initializeHashingParameters() {
  return { 0, 0, true }; // we don't care about deterministic hashing

  // // Setting the environment variable SWIFT_DETERMINISTIC_HASHING to "1"
  // // disables randomized hash seeding. This is useful in cases we need to ensure
  // // results are repeatable, e.g., in certain test environments.  (Note that
  // // even if the seed override is enabled, hash values aren't guaranteed to
  // // remain stable across even minor stdlib releases.)
  // auto determinism = getenv("SWIFT_DETERMINISTIC_HASHING");
  // if (determinism && 0 == strcmp(determinism, "1")) {
  //   return { 0, 0, true };
  // }
  // __swift_uint64_t seed0 = 0, seed1 = 0;
  // swift::swift_stdlib_random(&seed0, sizeof(seed0));
  // swift::swift_stdlib_random(&seed1, sizeof(seed1));
  // return { seed0, seed1, false };
}

SWIFT_ALLOWED_RUNTIME_GLOBAL_CTOR_BEGIN
swift::_SwiftHashingParameters swift::_swift_stdlib_Hashing_parameters =
  initializeHashingParameters();
SWIFT_ALLOWED_RUNTIME_GLOBAL_CTOR_END