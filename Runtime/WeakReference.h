//===--- WeakReference.h - Swift weak references ----------------*- C++ -*-===//
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
// Swift weak reference implementation.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_RUNTIME_WEAKREFERENCE_H
#define SWIFT_RUNTIME_WEAKREFERENCE_H

#include "Config.h"
#include "HeapObject.h"
#include "Metadata.h"
#include "../uSwiftShims/Target.h"

#include "stdint.h"

// #include "Private.h"

// #include <cstdint>

namespace swift {

// Note: This implementation of unknown weak makes several assumptions
// about ObjC's weak variables implementation:
// * Nil is stored verbatim.
// * Tagged pointer objects are stored verbatim with no side table entry.
// * Ordinary objects are stored with the LSB two bits (64-bit) or
//   one bit (32-bit) all clear. The stored value otherwise need not be
//   the pointed-to object.
//
// The Swift 3 implementation of unknown weak makes the following
// additional assumptions:
// * Ordinary objects are stored *verbatim* with the LSB *three* bits (64-bit)
//   or *two* bits (32-bit) all clear.

// Thread-safety:
// 
// Reading a weak reference must be thread-safe with respect to:
//  * concurrent readers
//  * concurrent weak reference zeroing due to deallocation of the
//    pointed-to object
//  * concurrent ObjC readers or zeroing (for non-native weak storage)
// 
// Reading a weak reference is NOT thread-safe with respect to:
//  * concurrent writes to the weak variable other than zeroing
//  * concurrent destruction of the weak variable
//
// Writing a weak reference must be thread-safe with respect to:
//  * concurrent weak reference zeroing due to deallocation of the
//    pointed-to object
//  * concurrent ObjC zeroing (for non-native weak storage)
//
// Writing a weak reference is NOT thread-safe with respect to:
//  * concurrent reads
//  * concurrent writes other than zeroing

class WeakReferenceBits {
  // On ObjC platforms, a weak variable may be controlled by the ObjC
  // runtime or by the Swift runtime. NativeMarkerMask and NativeMarkerValue
  // are used to distinguish them.
  //   if ((ptr & NativeMarkerMask) == NativeMarkerValue) it's Swift
  //   else it's ObjC
  // NativeMarkerMask incorporates the ObjC tagged pointer bits
  // plus one more bit that is set in Swift-controlled weak pointer values.
  // Non-ObjC platforms don't use any markers.
  enum : uintptr_t {
#if !SWIFT_OBJC_INTEROP
    NativeMarkerMask  = 0,
    NativeMarkerValue = 0
#elif defined(__x86_64__) && SWIFT_TARGET_OS_SIMULATOR
    NativeMarkerMask  = SWIFT_ABI_X86_64_SIMULATOR_OBJC_WEAK_REFERENCE_MARKER_MASK,
    NativeMarkerValue = SWIFT_ABI_X86_64_SIMULATOR_OBJC_WEAK_REFERENCE_MARKER_VALUE
#elif defined(__x86_64__)
    NativeMarkerMask  = SWIFT_ABI_X86_64_OBJC_WEAK_REFERENCE_MARKER_MASK,
    NativeMarkerValue = SWIFT_ABI_X86_64_OBJC_WEAK_REFERENCE_MARKER_VALUE
#elif defined(__i386__)
    NativeMarkerMask  = SWIFT_ABI_I386_OBJC_WEAK_REFERENCE_MARKER_MASK,
    NativeMarkerValue = SWIFT_ABI_I386_OBJC_WEAK_REFERENCE_MARKER_VALUE
#elif defined(__arm__) || defined(_M_ARM)
    NativeMarkerMask  = SWIFT_ABI_ARM_OBJC_WEAK_REFERENCE_MARKER_MASK,
    NativeMarkerValue = SWIFT_ABI_ARM_OBJC_WEAK_REFERENCE_MARKER_VALUE
#elif defined(__s390x__)
    NativeMarkerMask  = SWIFT_ABI_S390X_OBJC_WEAK_REFERENCE_MARKER_MASK,
    NativeMarkerValue = SWIFT_ABI_S390X_OBJC_WEAK_REFERENCE_MARKER_VALUE
#elif defined(__arm64__) || defined(__aarch64__) || defined(_M_ARM64)
    NativeMarkerMask  = SWIFT_ABI_ARM64_OBJC_WEAK_REFERENCE_MARKER_MASK,
    NativeMarkerValue = SWIFT_ABI_ARM64_OBJC_WEAK_REFERENCE_MARKER_VALUE
#else
    #error unknown architecture
#endif
  };

  static_assert((NativeMarkerMask & NativeMarkerValue) == NativeMarkerValue,
                "native marker value must fall within native marker mask");
  static_assert((NativeMarkerMask & heap_object_abi::SwiftSpareBitsMask)
                == NativeMarkerMask,
                "native marker mask must fall within Swift spare bits");

  uintptr_t bits;

 public:
  LLVM_ATTRIBUTE_ALWAYS_INLINE
  WeakReferenceBits() { }

  LLVM_ATTRIBUTE_ALWAYS_INLINE
  WeakReferenceBits(HeapObjectSideTableEntry *newValue) {
    setNativeOrNull(newValue);
  }

  LLVM_ATTRIBUTE_ALWAYS_INLINE
  bool isNativeOrNull() const {
    return bits == 0  ||  (bits & NativeMarkerMask) == NativeMarkerValue;
  }
    
  LLVM_ATTRIBUTE_ALWAYS_INLINE
  HeapObjectSideTableEntry *getNativeOrNull() const {
    assert(isNativeOrNull());
    if (bits == 0)
      return nullptr;
    else
      return
        reinterpret_cast<HeapObjectSideTableEntry *>(bits & ~NativeMarkerMask);
  }
  
  LLVM_ATTRIBUTE_ALWAYS_INLINE
  void setNativeOrNull(HeapObjectSideTableEntry *newValue) {
    assert((uintptr_t(newValue) & NativeMarkerMask) == 0);
    if (newValue)
      bits = uintptr_t(newValue) | NativeMarkerValue;
    else
      bits = 0;
  }
};


class WeakReference {
  union {
    WeakReferenceBits nativeValue;
  };

  void destroyOldNativeBits(WeakReferenceBits oldBits) {
    auto oldSide = oldBits.getNativeOrNull();
    if (oldSide)
      oldSide->decrementWeak();
  }
  
  HeapObject *nativeLoadStrongFromBits(WeakReferenceBits bits) {
    auto side = bits.getNativeOrNull();
    return side ? side->tryRetain() : nullptr;
  }
  
  HeapObject *nativeTakeStrongFromBits(WeakReferenceBits bits) {
    auto side = bits.getNativeOrNull();
    if (side) {
      side->decrementWeak();
      return side->tryRetain();
    } else {
      return nullptr;
    }
  }
  
  void nativeCopyInitFromBits(WeakReferenceBits srcBits) {
    auto side = srcBits.getNativeOrNull();
    if (side)
      side = side->incrementWeak();

    nativeValue = WeakReferenceBits(side);
  }

 public:
  
  WeakReference() : nativeValue() {}

  // WeakReference(std::nullptr_t)
  //   : nativeValue(WeakReferenceBits(nullptr)) { }

  WeakReference(const WeakReference& rhs) = delete;


  void nativeInit(HeapObject *object) {
    auto side = object ? object->refCounts.formWeakReference() : nullptr;
    nativeValue = WeakReferenceBits(side);
  }
  
  void nativeDestroy() {
    auto oldBits = nativeValue;
    nativeValue = nullptr;
    destroyOldNativeBits(oldBits);
  }

  void nativeAssign(HeapObject *newObject) {
    if (newObject) {
      assert(objectUsesNativeSwiftReferenceCounting(newObject) &&
             "weak assign native with non-native new object");
    }
    
    auto newSide =
      newObject ? newObject->refCounts.formWeakReference() : nullptr;
    auto newBits = WeakReferenceBits(newSide);

    auto oldBits = nativeValue;
    nativeValue = newBits;

    assert(oldBits.isNativeOrNull() &&
           "weak assign native with non-native old object");
    destroyOldNativeBits(oldBits);
  }

  HeapObject *nativeLoadStrong() {
    auto bits = nativeValue;
    return nativeLoadStrongFromBits(bits);
  }

  HeapObject *nativeTakeStrong() {
    auto bits = nativeValue;
    nativeValue = nullptr;
    return nativeTakeStrongFromBits(bits);
  }

  void nativeCopyInit(WeakReference *src) {
    auto srcBits = src->nativeValue;
    return nativeCopyInitFromBits(srcBits);
  }

  void nativeTakeInit(WeakReference *src) {
    auto srcBits = src->nativeValue;
    assert(srcBits.isNativeOrNull());
    src->nativeValue = nullptr;
    nativeValue = srcBits;
  }

  void nativeCopyAssign(WeakReference *src) {
    if (this == src) return;
    nativeDestroy();
    nativeCopyInit(src);
  }

  void nativeTakeAssign(WeakReference *src) {
    if (this == src) return;
    nativeDestroy();
    nativeTakeInit(src);
  }
};

static_assert(sizeof(WeakReference) == sizeof(void*),
              "incorrect WeakReference size");
static_assert(alignof(WeakReference) == alignof(void*),
              "incorrect WeakReference alignment");

// namespace swift
}

#endif
