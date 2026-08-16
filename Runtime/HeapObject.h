//===--- HeapObject.h -------------------------------------------*- C++ -*-===//
//
// This source file is copied from the Swift.org open source project.
//
// See originals for copyright and license.
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_RUNTIME_ALLOC_H
#define SWIFT_RUNTIME_ALLOC_H

#include "../uSwiftShims/RefCount.h"
#include "../uSwiftShims/SwiftStddef.h"
#include "../uSwiftShims/HeapObject.h"

#define SWIFT_EXPORT_ATTRIBUTE __attribute__((__visibility__("default")))
#define SWIFT_RUNTIME_EXPORT extern "C" SWIFT_EXPORT_ATTRIBUTE

// typedef struct HeapMetadata HeapMetadata;
// typedef struct HeapObject HeapObject;

// #define SWIFT_HEAPOBJECT_NON_OBJC_MEMBERS       \
//   InlineRefCounts refCounts

/// The Swift heap-object header.
/// This must match RefCountedStructTy in IRGen.

namespace swift {

struct InProcess;

template <typename Runtime> struct TargetMetadata;
using Metadata = TargetMetadata<InProcess>;

template <typename Target> struct TargetHeapMetadata;
using HeapMetadata = TargetHeapMetadata<InProcess>;

struct OpaqueValue;

  void swift_abortRetainUnowned(const void *object);
  void swift_abortRetainOverflow(const void *object);
  void swift_abortUnownedRetainOverflow();

/// Allocates a new heap object.  The returned memory is
/// uninitialized outside of the heap-object header.  The object
/// has an initial retain count of 1, and its metadata is set to
/// the given value.
///
/// At some point "soon after return", it will become an
/// invariant that metadata->getSize(returnValue) will equal
/// requiredSize.
///
/// Either aborts or throws a swift exception if the allocation fails.
///
/// \param requiredSize - the required size of the allocation,
///   including the header
/// \param requiredAlignmentMask - the required alignment of the allocation;
///   always one less than a power of 2 that's at least alignof(void*)
/// \return never null
///
/// POSSIBILITIES: The argument order is fair game.  It may be useful
/// to have a variant which guarantees zero-initialized memory.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_allocObject(HeapMetadata const *metadata,
                              size_t requiredSize,
                              size_t requiredAlignmentMask);

/// Initializes the object header of a stack allocated object.
///
/// \param metadata - the object's metadata which is stored in the header
/// \param object - the pointer to the object's memory on the stack
/// \returns the passed object pointer.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_initStackObject(HeapMetadata const *metadata,
                                  HeapObject *object);

/// Initializes the object header of a static object which is statically
/// allocated in the data section.
///
/// \param metadata - the object's metadata which is stored in the header
/// \param object - the address of the object in the data section. It is assumed
///        that at offset -1 there is a swift_once token allocated.
/// \returns the passed object pointer.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_initStaticObject(HeapMetadata const *metadata,
                                   HeapObject *object);

/// Performs verification that the lifetime of a stack allocated object has
/// ended. It aborts if the reference counts of the object indicate that the
/// object did escape to some other location.
SWIFT_RUNTIME_EXPORT
void swift_verifyEndOfLifetime(HeapObject *object);

struct BoxPair {
  HeapObject *object;
  OpaqueValue *buffer;
};

/// Allocates a heap object that can contain a value of the given type.
/// Returns a Box structure containing a HeapObject* pointer to the
/// allocated object, and a pointer to the value inside the heap object.
/// The value pointer points to an uninitialized buffer of size and alignment
/// appropriate to store a value of the given type.
/// The heap object has an initial retain count of 1, and its metadata is set
/// such that destroying the heap object destroys the contained value.
SWIFT_CC(swift) SWIFT_RUNTIME_EXPORT
BoxPair swift_allocBox(Metadata const *type);

/// Performs a uniqueness check on the pointer to a box structure. If the check
/// fails allocates a new box and stores the pointer in the buffer.
///
///  if (!isUnique(buffer[0]))
///    buffer[0] = swift_allocBox(type)
SWIFT_CC(swift) SWIFT_RUNTIME_EXPORT
BoxPair swift_makeBoxUnique(OpaqueValue *buffer, Metadata const *type,
                                    size_t alignMask);

/// Returns the address of a heap object representing all empty box types.
SWIFT_RUNTIME_EXPORT
HeapObject* swift_allocEmptyBox();

// Allocate plain old memory. This is the generalized entry point
// Never returns nil. The returned memory is uninitialized. 
//
// An "alignment mask" is just the alignment (a power of 2) minus 1.

SWIFT_RUNTIME_EXPORT
void *swift_slowAlloc(size_t bytes, size_t alignMask);

// If the caller cannot promise to zero the object during destruction,
// then call these corresponding APIs:
SWIFT_RUNTIME_EXPORT
void swift_slowDealloc(void *ptr, size_t bytes, size_t alignMask);

/// Atomically increments the retain count of an object.
///
/// \param object - may be null, in which case this is a no-op
///
/// \return object - we return the object because this enables tail call
/// optimization and the argument register to be live through the call on
/// architectures whose argument and return register is the same register.
///
/// POSSIBILITIES: We may end up wanting a bunch of different variants:
///  - the general version which correctly handles null values, swift
///     objects, and ObjC objects
///    - a variant that assumes that its operand is a swift object
///      - a variant that can safely use non-atomic operations
///      - maybe a variant that can assume a non-null object
/// It may also prove worthwhile to have this use a custom CC
/// which preserves a larger set of registers.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_retain(HeapObject *object);

SWIFT_RUNTIME_EXPORT
HeapObject *swift_retain_n(HeapObject *object, uint32_t n);

SWIFT_RUNTIME_EXPORT
HeapObject *swift_nonatomic_retain(HeapObject *object);

SWIFT_RUNTIME_EXPORT
HeapObject* swift_nonatomic_retain_n(HeapObject *object, uint32_t n);

/// Atomically increments the reference count of an object, unless it has
/// already been destroyed. Returns nil if the object is dead.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_tryRetain(HeapObject *object);

/// Returns true if an object is in the process of being deallocated.
SWIFT_RUNTIME_EXPORT
bool swift_isDeallocating(HeapObject *object);

/// Atomically decrements the retain count of an object.  If the
/// retain count reaches zero, the object is destroyed as follows:
///
///   size_t allocSize = object->metadata->destroy(object);
///   if (allocSize) swift_deallocObject(object, allocSize);
///
/// \param object - may be null, in which case this is a no-op
///
/// POSSIBILITIES: We may end up wanting a bunch of different variants:
///  - the general version which correctly handles null values, swift
///     objects, and ObjC objects
///    - a variant that assumes that its operand is a swift object
///      - a variant that can safely use non-atomic operations
///      - maybe a variant that can assume a non-null object
/// It's unlikely that a custom CC would be beneficial here.
SWIFT_RUNTIME_EXPORT
void swift_release(HeapObject *object);

SWIFT_RUNTIME_EXPORT
void swift_nonatomic_release(HeapObject *object);

/// Atomically decrements the retain count of an object n times. If the retain
/// count reaches zero, the object is destroyed
SWIFT_RUNTIME_EXPORT
void swift_release_n(HeapObject *object, uint32_t n);

/// Sets the RC_DEALLOCATING_FLAG flag. This is done non-atomically.
/// The strong reference count of \p object must be 1 and no other thread may
/// retain the object during executing this function.
SWIFT_RUNTIME_EXPORT
void swift_setDeallocating(HeapObject *object);

SWIFT_RUNTIME_EXPORT
void swift_nonatomic_release_n(HeapObject *object, uint32_t n);

// Refcounting observation hooks for memory tools. Don't use these.
SWIFT_RUNTIME_EXPORT
size_t swift_retainCount(HeapObject *object);
SWIFT_RUNTIME_EXPORT
size_t swift_unownedRetainCount(HeapObject *object);
SWIFT_RUNTIME_EXPORT
size_t swift_weakRetainCount(HeapObject *object);

/// Is this pointer a non-null unique reference to an object
/// that uses Swift reference counting?
SWIFT_RUNTIME_EXPORT
bool swift_isUniquelyReferencedNonObjC(const void *);

/// Is this non-null pointer a unique reference to an object
/// that uses Swift reference counting?
SWIFT_RUNTIME_EXPORT
bool swift_isUniquelyReferencedNonObjC_nonNull(const void *);

/// Is this non-null BridgeObject a unique reference to an object
/// that uses Swift reference counting?
SWIFT_RUNTIME_EXPORT
bool swift_isUniquelyReferencedNonObjC_nonNull_bridgeObject(
  uintptr_t bits);

/// Is this native Swift pointer a non-null unique reference to
/// an object?
SWIFT_RUNTIME_EXPORT
bool swift_isUniquelyReferenced_native(const struct HeapObject *);

/// Is this non-null native Swift pointer a unique reference to
/// an object?
SWIFT_RUNTIME_EXPORT
bool swift_isUniquelyReferenced_nonNull_native(const struct HeapObject *);

/// Is this native Swift pointer non-null and has a reference count greater than
/// one.
/// This runtime call will print an error message with file name and location if
/// the closure is escaping but it will not abort.
///
/// \p type: 0 - withoutActuallyEscaping verification
///              Was the closure passed to a withoutActuallyEscaping block
///              escaped in the block?
///          1 - @objc closure sentinel verfication
///              Was the closure passed to Objective-C escaped?
SWIFT_RUNTIME_EXPORT
bool swift_isEscapingClosureAtFileLocation(const struct HeapObject *object,
                                           const unsigned char *filename,
                                           int32_t filenameLength,
                                           int32_t line,
                                           int32_t column,
                                           unsigned type);

/// Deallocate the given memory.
///
/// It must have been returned by swift_allocObject and the strong reference
/// must have the RC_DEALLOCATING_FLAG flag set, but otherwise the object is
/// in an unknown state.
///
/// \param object - never null
/// \param allocatedSize - the allocated size of the object from the
///   program's perspective, i.e. the value
/// \param allocatedAlignMask - the alignment requirement that was passed
///   to allocObject
///
/// POSSIBILITIES: It may be useful to have a variant which
/// requires the object to have been fully zeroed from offsets
/// sizeof(SwiftHeapObject) to allocatedSize.
SWIFT_RUNTIME_EXPORT
void swift_deallocObject(HeapObject *object, size_t allocatedSize,
                         size_t allocatedAlignMask);

/// Deallocate an uninitialized object with a strong reference count of +1.
///
/// It must have been returned by swift_allocObject, but otherwise the object is
/// in an unknown state.
///
/// \param object - never null
/// \param allocatedSize - the allocated size of the object from the
///   program's perspective, i.e. the value
/// \param allocatedAlignMask - the alignment requirement that was passed
///   to allocObject
///
SWIFT_RUNTIME_EXPORT
void swift_deallocUninitializedObject(HeapObject *object, size_t allocatedSize,
                                      size_t allocatedAlignMask);

/// Deallocate the given memory.
///
/// It must have been returned by swift_allocObject, possibly used as an
/// Objective-C class instance, and the strong reference must have the
/// RC_DEALLOCATING_FLAG flag set, but otherwise the object is in an unknown
/// state.
///
/// \param object - never null
/// \param allocatedSize - the allocated size of the object from the
///   program's perspective, i.e. the value
/// \param allocatedAlignMask - the alignment requirement that was passed
///   to allocObject
///
/// POSSIBILITIES: It may be useful to have a variant which
/// requires the object to have been fully zeroed from offsets
/// sizeof(SwiftHeapObject) to allocatedSize.
SWIFT_RUNTIME_EXPORT
void swift_deallocClassInstance(HeapObject *object,
                                 size_t allocatedSize,
                                 size_t allocatedAlignMask);

/// Deallocate the given memory after destroying instance variables.
///
/// Destroys instance variables in classes more derived than the given metatype.
///
/// It must have been returned by swift_allocObject, possibly used as an
/// Objective-C class instance, and the strong reference must be equal to 1.
///
/// \param object - may be null
/// \param type - most derived class whose instance variables do not need to
///   be destroyed
/// \param allocatedSize - the allocated size of the object from the
///   program's perspective, i.e. the value
/// \param allocatedAlignMask - the alignment requirement that was passed
///   to allocObject
SWIFT_RUNTIME_EXPORT
void swift_deallocPartialClassInstance(HeapObject *object,
                                       const HeapMetadata *type,
                                       size_t allocatedSize,
                                       size_t allocatedAlignMask);

/// Deallocate the given memory allocated by swift_allocBox; it was returned
/// by swift_allocBox but is otherwise in an unknown state. The given Metadata
/// pointer must be the same metadata pointer that was passed to swift_allocBox
/// when the memory was allocated.
SWIFT_RUNTIME_EXPORT
void swift_deallocBox(HeapObject *object);

/// Project the value out of a box. `object` must have been allocated
/// using `swift_allocBox`, or by the compiler using a statically-emitted
/// box metadata object.
SWIFT_RUNTIME_EXPORT
OpaqueValue *swift_projectBox(HeapObject *object);





/// RAII object that wraps a Swift heap object and releases it upon
/// destruction.
class SwiftRAII {
  HeapObject *object;

public:
  SwiftRAII(HeapObject *obj, bool AlreadyRetained) : object(obj) {
    if (!AlreadyRetained)
      swift_retain(obj);
  }

  ~SwiftRAII() {
    if (object)
      swift_release(object);
  }

  SwiftRAII(const SwiftRAII &other) {
    swift_retain(*other);
    object = *other;
    ;
  }
  SwiftRAII(SwiftRAII &&other) : object(*other) {
    other.object = nullptr;
  }
  SwiftRAII &operator=(const SwiftRAII &other) {
    if (object)
      swift_release(object);
    swift_retain(*other);
    object = *other;
    return *this;
  }
  SwiftRAII &operator=(SwiftRAII &&other) {
    if (object)
      swift_release(object);
    object = *other;
    other.object = nullptr;
    return *this;
  }

  HeapObject *operator *() const { return object; }
};

/*****************************************************************************/
/**************************** UNOWNED REFERENCES *****************************/
/*****************************************************************************/

/// An unowned reference in memory.  This is ABI.
struct UnownedReference {
  HeapObject *Value;
};

/// Increment the unowned retain count.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_unownedRetain(HeapObject *value);

/// Decrement the unowned retain count.
SWIFT_RUNTIME_EXPORT
void swift_unownedRelease(HeapObject *value);

/// Increment the unowned retain count.
SWIFT_RUNTIME_EXPORT
void *swift_nonatomic_unownedRetain(HeapObject *value);

/// Decrement the unowned retain count.
SWIFT_RUNTIME_EXPORT
void swift_nonatomic_unownedRelease(HeapObject *value);

/// Increment the unowned retain count by n.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_unownedRetain_n(HeapObject *value, int n);

/// Decrement the unowned retain count by n.
SWIFT_RUNTIME_EXPORT
void swift_unownedRelease_n(HeapObject *value, int n);

/// Increment the unowned retain count by n.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_nonatomic_unownedRetain_n(HeapObject *value, int n);

/// Decrement the unowned retain count by n.
SWIFT_RUNTIME_EXPORT
void swift_nonatomic_unownedRelease_n(HeapObject *value, int n);

/// Increment the strong retain count of an object, aborting if it has
/// been deallocated.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_unownedRetainStrong(HeapObject *value);

/// Increment the strong retain count of an object, aborting if it has
/// been deallocated.
SWIFT_RUNTIME_EXPORT
HeapObject *swift_nonatomic_unownedRetainStrong(HeapObject *value);

/// Increment the strong retain count of an object which may have been
/// deallocated, aborting if it has been deallocated, and decrement its
/// unowned reference count.
SWIFT_RUNTIME_EXPORT
void swift_unownedRetainStrongAndRelease(HeapObject *value);

/// Increment the strong retain count of an object which may have been
/// deallocated, aborting if it has been deallocated, and decrement its
/// unowned reference count.
SWIFT_RUNTIME_EXPORT
void swift_nonatomic_unownedRetainStrongAndRelease(HeapObject *value);

/// Aborts if the object has been deallocated.
SWIFT_RUNTIME_EXPORT
void swift_unownedCheck(HeapObject *value);

static inline void swift_unownedInit(UnownedReference *ref, HeapObject *value) {
  ref->Value = value;
  swift_unownedRetain(value);
}

static inline void swift_unownedAssign(UnownedReference *ref,
                                       HeapObject *value) {
  auto oldValue = ref->Value;
  if (value != oldValue) {
    swift_unownedRetain(value);
    ref->Value = value;
    swift_unownedRelease(oldValue);
  }
}

static inline HeapObject *swift_unownedLoadStrong(UnownedReference *ref) {
  auto value = ref->Value;
  swift_unownedRetainStrong(value);
  return value;
}

static inline void *swift_unownedTakeStrong(UnownedReference *ref) {
  auto value = ref->Value;
  swift_unownedRetainStrongAndRelease(value);
  return value;
}

static inline void swift_unownedDestroy(UnownedReference *ref) {
  swift_unownedRelease(ref->Value);
}

static inline void swift_unownedCopyInit(UnownedReference *dest,
                                         UnownedReference *src) {
  dest->Value = src->Value;
  swift_unownedRetain(dest->Value);
}

static inline void swift_unownedTakeInit(UnownedReference *dest,
                                         UnownedReference *src) {
  dest->Value = src->Value;
}

static inline void swift_unownedCopyAssign(UnownedReference *dest,
                                           UnownedReference *src) {
  auto newValue = src->Value;
  auto oldValue = dest->Value;
  if (newValue != oldValue) {
    dest->Value = newValue;
    swift_unownedRetain(newValue);
    swift_unownedRelease(oldValue);
  }
}

static inline void swift_unownedTakeAssign(UnownedReference *dest,
                                           UnownedReference *src) {
  auto newValue = src->Value;
  auto oldValue = dest->Value;
  dest->Value = newValue;
  swift_unownedRelease(oldValue);
}

static inline bool swift_unownedIsEqual(UnownedReference *ref,
                                        HeapObject *value) {
  bool isEqual = ref->Value == value;
  if (isEqual)
    swift_unownedCheck(value);
  return isEqual;
}

/*****************************************************************************/
/****************************** WEAK REFERENCES ******************************/
/*****************************************************************************/

// Defined in Runtime/WeakReference.h
class WeakReference;

/// Initialize a weak reference.
///
/// \param ref - never null
/// \param value - can be null
/// \return ref
SWIFT_RUNTIME_EXPORT
WeakReference *swift_weakInit(WeakReference *ref, HeapObject *value);

/// Assign a new value to a weak reference.
///
/// \param ref - never null
/// \param value - can be null
/// \return ref
SWIFT_RUNTIME_EXPORT
WeakReference *swift_weakAssign(WeakReference *ref, HeapObject *value);

/// Load a value from a weak reference.  If the current value is a
/// non-null object that has begun deallocation, returns null;
/// otherwise, retains the object before returning.
///
/// \param ref - never null
/// \return can be null
SWIFT_RUNTIME_EXPORT
HeapObject *swift_weakLoadStrong(WeakReference *ref);

/// Load a value from a weak reference as if by swift_weakLoadStrong,
/// but leaving the reference in an uninitialized state.
///
/// \param ref - never null
/// \return can be null
SWIFT_RUNTIME_EXPORT
HeapObject *swift_weakTakeStrong(WeakReference *ref);

/// Destroy a weak reference.
///
/// \param ref - never null, but can refer to a null object
SWIFT_RUNTIME_EXPORT
void swift_weakDestroy(WeakReference *ref);

/// Copy initialize a weak reference.
///
/// \param dest - never null, but can refer to a null object
/// \param src - never null, but can refer to a null object
/// \return dest
SWIFT_RUNTIME_EXPORT
WeakReference *swift_weakCopyInit(WeakReference *dest, WeakReference *src);

/// Take initialize a weak reference.
///
/// \param dest - never null, but can refer to a null object
/// \param src - never null, but can refer to a null object
/// \return dest
SWIFT_RUNTIME_EXPORT
WeakReference *swift_weakTakeInit(WeakReference *dest, WeakReference *src);

/// Copy assign a weak reference.
///
/// \param dest - never null, but can refer to a null object
/// \param src - never null, but can refer to a null object
/// \return dest
SWIFT_RUNTIME_EXPORT
WeakReference *swift_weakCopyAssign(WeakReference *dest, WeakReference *src);

/// Take assign a weak reference.
///
/// \param dest - never null, but can refer to a null object
/// \param src - never null, but can refer to a null object
/// \return dest
SWIFT_RUNTIME_EXPORT
WeakReference *swift_weakTakeAssign(WeakReference *dest, WeakReference *src);

/*****************************************************************************/
/************************* OTHER REFERENCE-COUNTING **************************/
/*****************************************************************************/

SWIFT_RUNTIME_EXPORT
void *swift_bridgeObjectRetain(void *value);

/// Increment the strong retain count of a bridged object by n.
SWIFT_RUNTIME_EXPORT
void *swift_bridgeObjectRetain_n(void *value, int n);


SWIFT_RUNTIME_EXPORT
void *swift_nonatomic_bridgeObjectRetain(void *value);


/// Increment the strong retain count of a bridged object by n.
SWIFT_RUNTIME_EXPORT
void *swift_nonatomic_bridgeObjectRetain_n(void *value, int n);


/*****************************************************************************/
/************************ UNKNOWN REFERENCE-COUNTING *************************/
/*****************************************************************************/



static inline void *swift_unknownObjectRetain(void *value) {
  return swift_retain(static_cast<HeapObject *>(value));
}

static inline void *swift_unknownObjectRetain_n(void *value, int n) {
  return swift_retain_n(static_cast<HeapObject *>(value), n);
}

static inline void *swift_nonatomic_unknownObjectRetain(void *value) {
  return swift_nonatomic_retain(static_cast<HeapObject *>(value));
}

static inline void *swift_nonatomic_unknownObjectRetain_n(void *value, int n) {
  return swift_nonatomic_retain_n(static_cast<HeapObject *>(value), n);
}


SWIFT_RUNTIME_EXPORT
void swift_bridgeObjectRelease(void *value);

/// Decrement the strong retain count of a bridged object by n.
SWIFT_RUNTIME_EXPORT
void swift_bridgeObjectRelease_n(void *value, int n);

SWIFT_RUNTIME_EXPORT
void swift_nonatomic_bridgeObjectRelease(void *value);

/// Decrement the strong retain count of a bridged object by n.
SWIFT_RUNTIME_EXPORT
void swift_nonatomic_bridgeObjectRelease_n(void *value, int n);








/*****************************************************************************/
/************************** UNKNOWN WEAK REFERENCES **************************/
/*****************************************************************************/

static inline WeakReference *swift_unknownObjectWeakInit(WeakReference *ref,
                                                         void *value) {
  return swift_weakInit(ref, static_cast<HeapObject *>(value));
}

static inline WeakReference *swift_unknownObjectWeakAssign(WeakReference *ref,
                                                           void *value) {
  return swift_weakAssign(ref, static_cast<HeapObject *>(value));
}

static inline void *swift_unknownObjectWeakLoadStrong(WeakReference *ref) {
  return static_cast<void *>(swift_weakLoadStrong(ref));
}

static inline void *swift_unknownObjectWeakTakeStrong(WeakReference *ref) {
  return static_cast<void *>(swift_weakTakeStrong(ref));
}

static inline void swift_unknownObjectWeakDestroy(WeakReference *object) {
  swift_weakDestroy(object);
}

static inline WeakReference *
swift_unknownObjectWeakCopyInit(WeakReference *dest, WeakReference *src) {
  return swift_weakCopyInit(dest, src);
}

static inline WeakReference *
swift_unknownObjectWeakTakeInit(WeakReference *dest, WeakReference *src) {
  return swift_weakTakeInit(dest, src);
}

static inline WeakReference *
swift_unknownObjectWeakCopyAssign(WeakReference *dest, WeakReference *src) {
  return swift_weakCopyAssign(dest, src);
}

static inline WeakReference *
swift_unknownObjectWeakTakeAssign(WeakReference *dest, WeakReference *src) {
  return swift_weakTakeAssign(dest, src);
}

/*****************************************************************************/
/************************ UNKNOWN UNOWNED REFERENCES *************************/
/*****************************************************************************/

static inline UnownedReference *
swift_unknownObjectUnownedInit(UnownedReference *ref, void *value) {
  swift_unownedInit(ref, static_cast<HeapObject*>(value));
  return ref;
}

static inline UnownedReference *
swift_unknownObjectUnownedAssign(UnownedReference *ref, void *value) {
  swift_unownedAssign(ref, static_cast<HeapObject*>(value));
  return ref;
}

static inline void *
swift_unknownObjectUnownedLoadStrong(UnownedReference *ref) {
  return swift_unownedLoadStrong(ref);
}

static inline void *
swift_unknownObjectUnownedTakeStrong(UnownedReference *ref) {
  return swift_unownedTakeStrong(ref);
}

static inline void swift_unknownObjectUnownedDestroy(UnownedReference *ref) {
  swift_unownedDestroy(ref);
}

static inline UnownedReference *
swift_unknownObjectUnownedCopyInit(UnownedReference *dest,
                                   UnownedReference *src) {
  swift_unownedCopyInit(dest, src);
  return dest;
}

static inline UnownedReference *
swift_unknownObjectUnownedTakeInit(UnownedReference *dest,
                                   UnownedReference *src) {
  swift_unownedTakeInit(dest, src);
  return dest;
}

static inline UnownedReference *
swift_unknownObjectUnownedCopyAssign(UnownedReference *dest,
                                     UnownedReference *src) {
  swift_unownedCopyAssign(dest, src);
  return dest;
}

static inline UnownedReference *
swift_unknownObjectUnownedTakeAssign(UnownedReference *dest,
                                     UnownedReference *src) {
  swift_unownedTakeAssign(dest, src);
  return dest;
}


static inline bool swift_unknownObjectUnownedIsEqual(UnownedReference *ref,
                                                     void *value) {
  return swift_unownedIsEqual(ref, static_cast<HeapObject *>(value));
}

struct TypeNamePair {
  const char *data;
  uintptr_t length;
};

/// Return the name of a Swift type represented by a metadata object.
/// func _getTypeName(_ type: Any.Type, qualified: Bool)
///   -> (UnsafePointer<UInt8>, Int)
SWIFT_CC(swift) SWIFT_RUNTIME_STDLIB_API
TypeNamePair
swift_getTypeName(const Metadata *type, bool qualified);

/// Return the mangled name of a Swift type represented by a metadata object.
/// func _getMangledTypeName(_ type: Any.Type)
///   -> (UnsafePointer<UInt8>, Int)
SWIFT_CC(swift) SWIFT_RUNTIME_STDLIB_API
TypeNamePair
swift_getMangledTypeName(const Metadata *type);


}

// SWIFT_RUNTIME_STDLIB_API
// void _swift_instantiateInertHeapObject(void *address,
//                                        const HeapMetadata *metadata);

// SWIFT_RUNTIME_STDLIB_API
// __swift_size_t swift_retainCount(HeapObject *obj);

// SWIFT_RUNTIME_STDLIB_API
// __swift_size_t swift_unownedRetainCount(HeapObject *obj);

// SWIFT_RUNTIME_STDLIB_API
// __swift_size_t swift_weakRetainCount(HeapObject *obj);


/*

#if defined(__x86_64__)

#ifdef __APPLE__
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DARWIN_X86_64_LEAST_VALID_POINTER
#else
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#endif
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_X86_64_SWIFT_SPARE_BITS_MASK
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_X86_64_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_X86_64_OBJC_NUM_RESERVED_LOW_BITS

#elif defined(__arm64__)

#ifdef __APPLE__
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DARWIN_ARM64_LEAST_VALID_POINTER
#else
#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#endif
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_ARM64_SWIFT_SPARE_BITS_MASK
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_ARM64_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_ARM64_OBJC_NUM_RESERVED_LOW_BITS

#elif defined(__powerpc64__)

#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_POWERPC64_SWIFT_SPARE_BITS_MASK
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_DEFAULT_OBJC_NUM_RESERVED_LOW_BITS

#elif defined(__s390x__)

#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_S390X_SWIFT_SPARE_BITS_MASK
#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_DEFAULT_OBJC_NUM_RESERVED_LOW_BITS

#else

#define _swift_abi_LeastValidPointerValue                                      \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_LEAST_VALID_POINTER

#if __i386__
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_I386_SWIFT_SPARE_BITS_MASK
#elif __arm__
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_ARM_SWIFT_SPARE_BITS_MASK
#else
#define _swift_abi_SwiftSpareBitsMask                                          \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_SWIFT_SPARE_BITS_MASK
#endif

#define _swift_abi_ObjCReservedBitsMask                                        \
  (__swift_uintptr_t) SWIFT_ABI_DEFAULT_OBJC_RESERVED_BITS_MASK
#define _swift_abi_ObjCReservedLowBits                                         \
  (unsigned) SWIFT_ABI_DEFAULT_OBJC_NUM_RESERVED_LOW_BITS
#endif
*/

// #define _swift_BridgeObject_TaggedPointerBits _swift_abi_ObjCReservedBitsMask

#endif // SWIFT_RUNTIME_ALLOC_H
