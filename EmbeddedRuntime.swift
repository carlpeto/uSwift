//===----------------------------------------------------------------------===//
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

import uSwiftShims

/// Class object and class metadata structures

public struct ClassMetadata {
  var superclassMetadata: UnsafeMutablePointer<ClassMetadata>?

  // There is no way to express the actual calling convention on the heap desroy
  // function (swiftcc with 'self') currently, so let's use UnsafeRawPointer
  // and a helper function in C (_swift_embedded_invoke_heap_object_destroy).
  var destroy: UnsafeRawPointer
}

public struct HeapObject {
  // There is no way to express the custom ptrauth signature on the metadata
  // field, so let's use UnsafeRawPointer and a helper function in C instead
  // (_swift_embedded_set_heap_object_metadata_pointer).
  var metadata: UnsafeRawPointer

  // TODO: This is just an initial support for strong refcounting only. We need
  // to think about supporting (or banning) weak and/or unowned references.
  var refcount: Int

#if _pointerBitWidth(_64)
  static let doNotFreeBit = Int(bitPattern: 0x8000_0000_0000_0000)
  static let refcountMask = Int(bitPattern: 0x7fff_ffff_ffff_ffff)
  static let immortalRefCount = Int(bitPattern: 0x7fff_ffff_ffff_ffff) // Make sure we don't have doNotFreeBit set
#elseif _pointerBitWidth(_32)
  static let doNotFreeBit = Int(bitPattern: 0x8000_0000)
  static let refcountMask = Int(bitPattern: 0x7fff_ffff)
  static let immortalRefCount = Int(bitPattern: 0x7fff_ffff) // Make sure we don't have doNotFreeBit set
#elseif _pointerBitWidth(_16)
  static let doNotFreeBit = Int(bitPattern: 0x8000)
  static let refcountMask = Int(bitPattern: 0x7fff)
  static let immortalRefCount = Int(bitPattern: 0x7fff) // Make sure we don't have doNotFreeBit set
#endif

  // static let immortalRefCount: Int = -1
}



/// Forward declarations of C functions


@_silgen_name("free")
func free(_ p: Builtin.RawPointer)



/// Allocations

#if _pointerBitWidth(_32)

@_silgen_name("posix_memalign")
func posix_memalign(_: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _: Int, _: Int) -> CInt

// we only have these stubs on our 32-bit platforms (ARM Cortex M, RISC-V and Xtensa)
func alignedAlloc(size: Int, alignment: Int) -> UnsafeMutableRawPointer? {
  let alignment = max(alignment, MemoryLayout<UnsafeRawPointer>.size)
  var r: UnsafeMutableRawPointer? = nil
  _ = posix_memalign(&r, alignment, size)
  return r
}

@c
public func swift_coroFrameAlloc(_ size: Int, _ type: UInt64) -> UnsafeMutableRawPointer? {
  return unsafe alignedAlloc(
    size: size,
    alignment: _swift_MinAllocationAlignment)
}

@_cdecl("swift_slowAlloc")
public func swift_slowAlloc(_ size: Int, _ alignMask: Int) -> UnsafeMutableRawPointer? {
  let alignment: Int
  if alignMask == -1 {
    alignment = _swift_MinAllocationAlignment
  } else {
    alignment = alignMask + 1
  }
  return alignedAlloc(size: size, alignment: alignment)
}

@_cdecl("swift_slowDealloc")
public func swift_slowDealloc(_ ptr: UnsafeMutableRawPointer, _ size: Int, _ alignMask: Int) {
  free(ptr._rawValue)
}
#endif

@_silgen_name("swift_allocObject")
public func swift_allocObject(metadata: UnsafeMutablePointer<ClassMetadata>, requiredSize: Int, requiredAlignmentMask: Int) -> UnsafeMutablePointer<HeapObject> {
  #if AVR_LIBC_DEFINED_SWIFT && compiler(<6.2)
  // one day I should work out why there's this discrepancy between the 16/32 bit versions of microswift, it's annoying...

  // update:
  // looks like it's probably because for 32 bit microswift we use the new Pure Swift Embedded version of swift_slowAlloc
  // (above), which internally calls posix_memAlign, which takes an Int (this actually isn't working on the ESP32 platform
  // yet but we are close)... whereas the old version of AVR/16 bit microswift calls the C function that's only included
  // for AVR and that takes size_t, which is a UInt on those platforms...
  let sz = UInt(requiredSize)
  #else
  let sz = requiredSize
  #endif

  if let p = swift_slowAlloc(sz, 0) {
    let object = p.assumingMemoryBound(to: HeapObject.self)
    _swift_embedded_set_heap_object_metadata_pointer(object, metadata)
    object.pointee.refcount = 1
    return object
  } else {
    _microswift_class_creation_attempt_oom(requiredSize)
    fatalError()
  }
}

@_silgen_name("swift_deallocObject")
public func swift_deallocObject(object: UnsafeMutablePointer<HeapObject>, allocatedSize: Int, allocatedAlignMask: Int) {
  free(object._rawValue)
}

@_silgen_name("swift_deallocClassInstance")
public func swift_deallocClassInstance(object: UnsafeMutablePointer<HeapObject>, allocatedSize: Int, allocatedAlignMask: Int) {
  if (object.pointee.refcount & HeapObject.doNotFreeBit) != 0 {
    return
  }

  free(object._rawValue)
}

@_silgen_name("swift_initStaticObject")
public func swift_initStaticObject(metadata: UnsafeMutablePointer<ClassMetadata>, object: UnsafeMutablePointer<HeapObject>) -> UnsafeMutablePointer<HeapObject> {
  _swift_embedded_set_heap_object_metadata_pointer(object, metadata)
  object.pointee.refcount = HeapObject.immortalRefCount
  return object
}

@_silgen_name("swift_initStackObject")
public func swift_initStackObject(metadata: UnsafeMutablePointer<ClassMetadata>, object: UnsafeMutablePointer<HeapObject>) -> UnsafeMutablePointer<HeapObject> {
  _swift_embedded_set_heap_object_metadata_pointer(object, metadata)
  object.pointee.refcount = 1 | HeapObject.doNotFreeBit
  return object
}



/// Refcounting

@_silgen_name("swift_setDeallocating")
public func swift_setDeallocating(object: UnsafeMutablePointer<HeapObject>) {
}

@_silgen_name("swift_isUniquelyReferenced_nonNull_native")
public func swift_isUniquelyReferenced_nonNull_native(object: UnsafeMutablePointer<HeapObject>) -> Bool {
  let refcount = refcountPointer(for: object)
  return loadAcquire(refcount) == 1
}

@_silgen_name("swift_retain")
public func swift_retain(object: Builtin.RawPointer) -> Builtin.RawPointer {
  if Int(Builtin.ptrtoint_Word(object)) == 0 { return object }
  let o = UnsafeMutablePointer<HeapObject>(knownNotNilRawPointer: object)
  return swift_retain_n_(object: o, n: 1)._rawValue
}

// Cannot use UnsafeMutablePointer<HeapObject>? directly in the function argument or return value as it causes IRGen crashes
@_silgen_name("swift_retain_n")
public func swift_retain_n(object: Builtin.RawPointer, n: UInt32) -> Builtin.RawPointer {
  if Int(Builtin.ptrtoint_Word(object)) == 0 { return object }
  let o = UnsafeMutablePointer<HeapObject>(knownNotNilRawPointer: object)
  return swift_retain_n_(object: o, n: n)._rawValue
}

func swift_retain_n_(object: UnsafeMutablePointer<HeapObject>, n: UInt32) -> UnsafeMutablePointer<HeapObject> {
  let refcount = refcountPointer(for: object)
  if loadRelaxed(refcount) == HeapObject.immortalRefCount {
    return object
  }

  addRelaxed(refcount, n: Int(n))

  return object
}

@_silgen_name("swift_release")
public func swift_release(object: Builtin.RawPointer) {
  if Int(Builtin.ptrtoint_Word(object)) == 0 { return }
  let o = UnsafeMutablePointer<HeapObject>(object)
  swift_release_n_(object: o, n: 1)
}

@_silgen_name("swift_release_n")
public func swift_release_n(object: Builtin.RawPointer, n: UInt32) {
  if Int(Builtin.ptrtoint_Word(object)) == 0 { return }
  let o = UnsafeMutablePointer<HeapObject>(object)
  swift_release_n_(object: o, n: n)
}

public func swift_release_n_(object: UnsafeMutablePointer<HeapObject>?, n: UInt32) {
  guard let object else {
    return
  }

  let refcount = refcountPointer(for: object)
  if loadRelaxed(refcount) == HeapObject.immortalRefCount {
    return
  }

  let resultingRefcount = subFetchAcquireRelease(refcount, n: Int(n)) & HeapObject.refcountMask
  if resultingRefcount == 0 {
    _swift_embedded_invoke_heap_object_destroy(object)
  } else if resultingRefcount < 0 {
    fatalError()
  }
}



/// Refcount helpers

fileprivate func refcountPointer(for object: UnsafeMutablePointer<HeapObject>) -> UnsafeMutablePointer<Int> {
  // TODO: This should use MemoryLayout<HeapObject>.offset(to: \.refcount) but we don't have KeyPaths yet
  return UnsafeMutablePointer<Int>(knownNotNilRawPointer: UnsafeRawPointer(object)
    .advanced(by: MemoryLayout<Int>.size)._rawValue)
}

fileprivate func loadRelaxed(_ atomic: UnsafeMutablePointer<Int>) -> Int {
  Int(Builtin.atomicload_monotonic_Word(atomic._rawValue))
}

fileprivate func loadAcquire(_ atomic: UnsafeMutablePointer<Int>) -> Int {
  Int(Builtin.atomicload_acquire_Word(atomic._rawValue))
}

fileprivate func subFetchAcquireRelease(_ atomic: UnsafeMutablePointer<Int>, n: Int) -> Int {
  let oldValue = Int(Builtin.atomicrmw_sub_acqrel_Word(atomic._rawValue, n._builtinWordValue))
  return oldValue - n
}

fileprivate func addRelaxed(_ atomic: UnsafeMutablePointer<Int>, n: Int) {
  _ = Builtin.atomicrmw_add_monotonic_Word(atomic._rawValue, n._builtinWordValue)
}

fileprivate func compareExchangeRelaxed(_ atomic: UnsafeMutablePointer<Int>, expectedOldValue: Int, desiredNewValue: Int) -> Bool {
  let (_, won) = Builtin.cmpxchg_monotonic_monotonic_Word(atomic._rawValue, expectedOldValue._builtinWordValue, desiredNewValue._builtinWordValue)
  return Bool(won)
}

fileprivate func storeRelease(_ atomic: UnsafeMutablePointer<Int>, newValue: Int) {
  Builtin.atomicstore_release_Word(atomic._rawValue, newValue._builtinWordValue)
}


/// Exclusivity checking

@_silgen_name("swift_beginAccess")
public func swift_beginAccess(pointer: UnsafeMutableRawPointer, buffer: UnsafeMutableRawPointer, flags: UInt, pc: UnsafeMutableRawPointer) {
  // TODO: Add actual exclusivity checking.
}

@_silgen_name("swift_endAccess")
public func swift_endAccess(buffer: UnsafeMutableRawPointer) {
  // TODO: Add actual exclusivity checking.
}



// Once

// @_silgen_name("swift_once")
// public func swift_once(predicate: UnsafeMutablePointer<Int>, fn: (@convention(c) (UnsafeMutableRawPointer)->()), context: UnsafeMutableRawPointer) {
//   let checkedLoadAcquire = { predicate in
//     let value = loadAcquire(predicate)
//     assert(value == -1 || value == 0 || value == 1)
//     return value
//   }

//   if checkedLoadAcquire(predicate) < 0 { return }

//   let won = compareExchangeRelaxed(predicate, expectedOldValue: 0, desiredNewValue: 1)
//   if won {
//     fn(context)
//     storeRelease(predicate, newValue: -1)
//     return
//   }

//   // TODO: This should really use an OS provided lock
//   while checkedLoadAcquire(predicate) >= 0 {
//     // spin
//   }
// }



// Misc

@_silgen_name("swift_deletedMethodError")
public func swift_deletedMethodError() -> Never {
  Builtin.int_trap()
}

@_silgen_name("swift_willThrow")
public func swift_willThrow() throws {
}

@_silgen_name("swift_willThrowTyped")
public func _willThrowTyped<E: Error>(_ error: E) {
}

// @_extern(c, "arc4random_buf")
// func arc4random_buf(buf: UnsafeMutableRawPointer, nbytes: Int)

// public func swift_stdlib_random(_ buf: UnsafeMutableRawPointer, _ nbytes: Int) {
//   arc4random_buf(buf: buf, nbytes: nbytes)
// }
