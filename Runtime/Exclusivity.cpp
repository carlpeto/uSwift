//===--- Exclusivity.cpp - Exclusivity tracking ---------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// This implements the runtime support for dynamically tracking exclusivity.
//
//===----------------------------------------------------------------------===//


#include "Config.h"
#include "Exclusivity.h"

// Pick a return-address strategy
#if __GNUC__
#define get_return_address() __builtin_return_address(0)
#else
#error missing implementation for get_return_address
#define get_return_address() ((void*) 0)
#endif

using namespace swift;

namespace swift {
enum class ExclusivityFlags : uintptr_t {
  Read             = 0x0,
  Modify           = 0x1,
  // ActionMask can grow without breaking the ABI because the runtime controls
  // how these flags are encoded in the "value buffer". However, any additional
  // actions must be compatible with the original behavior for the old, smaller
  // ActionMask (older runtimes will continue to treat them as either a simple
  // Read or Modify).
  ActionMask       = 0x1,

  // The runtime should track this access to check against subsequent accesses.
  Tracking         = 0x20
};
}

namespace {

/// A single access that we're tracking.
///
/// The following inputs are accepted by the begin_access runtime entry
/// point. This table show the action performed by the current runtime to
/// convert those inputs into stored fields in the Access scratch buffer.
///
/// Pointer | Runtime     | Access | PC    | Reported| Access
/// Argument| Behavior    | Pointer| Arg   | PC      | PC
/// -------- ------------- -------- ------- --------- ----------
/// null    | [trap or missing enforcement]
/// nonnull | [nontracked]| null   | null  | caller  | [discard]
/// nonnull | [nontracked]| null   | valid | <same>  | [discard]
/// nonnull | [tracked]   | <same> | null  | caller  | caller
/// nonnull | [tracked]   | <same> | valid | <same>  | <same>
///
/// [nontracked] means that the Access scratch buffer will not be added to the
/// runtime's list of tracked accesses. However, it may be passed to a
/// subsequent call to end_unpaired_access. The null Pointer field then
/// identifies the Access record as nontracked.
///
/// The runtime owns the contents of the scratch buffer, which is allocated by
/// the compiler but otherwise opaque. The runtime may later reuse the Pointer
/// or PC fields or any spare bits for additional flags, and/or a pointer to
/// out-of-line storage.
struct Access {
  void *Pointer;
  void *PC;
  uintptr_t NextAndAction;

  enum : uintptr_t {
    ActionMask = (uintptr_t)ExclusivityFlags::ActionMask,
    NextMask = ~ActionMask
  };

  Access *getNext() const {
    return reinterpret_cast<Access*>(NextAndAction & NextMask);
  }

  void setNext(Access *next) {
    NextAndAction =
      reinterpret_cast<uintptr_t>(next) | (NextAndAction & ActionMask);
  }

  ExclusivityFlags getAccessAction() const {
    return ExclusivityFlags(NextAndAction & ActionMask);
  }

  void initialize(void *pc, void *pointer, Access *next,
                  ExclusivityFlags action) {
    Pointer = pointer;
    PC = pc;
    NextAndAction = reinterpret_cast<uintptr_t>(next) | uintptr_t(action);
  }
};

} // end anonymous namespace

/// Begin tracking a dynamic access.
///
/// This may cause a runtime failure if an incompatible access is
/// already underway.
void swift::swift_beginAccess(void *pointer, ValueBuffer *buffer,
                              ExclusivityFlags flags, void *pc) {
  if (pointer) {
    Access *access = reinterpret_cast<Access*>(buffer);

    // exclusivity checking is disabled.
    access->Pointer = nullptr;
  }
}

/// End tracking a dynamic access.
void swift::swift_endAccess(ValueBuffer *buffer) {
}
