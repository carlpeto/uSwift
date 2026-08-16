//===--- Metadata.h - Swift Language ABI Metadata Support -------*- C++ -*-===//
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
// Swift runtime support for generating and uniquing metadata.
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_RUNTIME_METADATA_H
#define SWIFT_RUNTIME_METADATA_H


#define SWIFT_RT_TRACK_INVOCATION(a,b) 


/// Is the given value a valid alignment mask?
static inline bool isAlignmentMask(size_t mask) {
  // mask          == xyz01111...
  // mask+1        == xyz10000...
  // mask&(mask+1) == xyz00000...
  // So this is nonzero if and only if there any bits set
  // other than an arbitrarily long sequence of low bits.
  return (mask & (mask + 1)) == 0;
}

// No ptrauth on AVR
#define SWIFT_PTRAUTH 0
#define __ptrauth_swift_function_pointer(__typekey)
#define __ptrauth_swift_class_method_pointer(__declkey)
#define __ptrauth_swift_protocol_witness_function_pointer(__declkey)
#define __ptrauth_swift_value_witness_function_pointer(__key)
#define __ptrauth_swift_type_metadata_instantiation_function
#define __ptrauth_swift_runtime_function_entry
#define __ptrauth_swift_runtime_function_entry_with_key(__key)
#define __ptrauth_swift_runtime_function_entry_strip(__fn) (__fn)
#define __ptrauth_swift_heap_object_destructor
#define __ptrauth_swift_type_descriptor
#define __ptrauth_swift_dynamic_replacement_key
#define swift_ptrauth_sign_opaque_read_resume_function(__fn, __buffer) (__fn)
#define swift_ptrauth_sign_opaque_modify_resume_function(__fn, __buffer) (__fn)

// STUBBED Metadata
// Add stuff back as needed, as little as possible.


#include "RelativePointer.h"
// #include "libstdc/functional"
#include "Casting_minimum.h"

// #include "swift/ABI/Metadata.h"
// #include "swift/Reflection/Records.h"

#include "ManglingMacros.h"
#include "limits.h"
#include "MetadataValues_minimum.h"
#include "TrailingObjects.h"

namespace swift {

// class MetadataAllocator : public llvm::AllocatorBase<MetadataAllocator> {
// public:
//   void Reset() {}

//   LLVM_ATTRIBUTE_RETURNS_NONNULL void *Allocate(size_t size, size_t alignment);
//   using AllocatorBase<MetadataAllocator>::Allocate;

//   void Deallocate(const void *Ptr, size_t size);
//   using AllocatorBase<MetadataAllocator>::Deallocate;

//   void PrintStats() const {}
// };

// /// A typedef for simple global caches.
// template <class EntryTy>
// using SimpleGlobalCache =
//   ConcurrentMap<EntryTy, /*destructor*/ false, MetadataAllocator>;

enum {
  /// The number of words (pointers) in a value buffer.
  NumWords_ValueBuffer = 3,

  /// The number of words in a metadata completion context.
  NumWords_MetadataCompletionContext = 4,

  /// The number of words in a yield-once coroutine buffer.
  NumWords_YieldOnceBuffer = 4,

  /// The number of words in a yield-many coroutine buffer.
  NumWords_YieldManyBuffer = 8,
};

struct InProcess;
template <typename Runtime> struct TargetMetadata;
using Metadata = TargetMetadata<InProcess>;

// /// Non-type metadata kinds have this bit set.
// const unsigned MetadataKindIsNonType = 0x400;

// /// Non-heap metadata kinds have this bit set.
// const unsigned MetadataKindIsNonHeap = 0x200;

// // The above two flags are negative because the "class" kind has to be zero,
// // and class metadata is both type and heap metadata.

// /// Runtime-private metadata has this bit set. The compiler must not statically
// /// generate metadata objects with these kinds, and external tools should not
// /// rely on the stability of these values or the precise binary layout of
// /// their associated data structures.
// const unsigned MetadataKindIsRuntimePrivate = 0x100;

// /// Kinds of Swift metadata records.  Some of these are types, some
// /// aren't.
// enum class MetadataKind : uint32_t {
// #define METADATAKIND(name, value) name = value,
// #define ABSTRACTMETADATAKIND(name, start, end)                                 \
//   name##_Start = start, name##_End = end,
// #include "MetadataKind.def"
  
//   /// The largest possible non-isa-pointer metadata kind value.
//   ///
//   /// This is included in the enumeration to prevent against attempts to
//   /// exhaustively match metadata kinds. Future Swift runtimes or compilers
//   /// may introduce new metadata kinds, so for forward compatibility, the
//   /// runtime must tolerate metadata with unknown kinds.
//   /// This specific value is not mapped to a valid metadata kind at this time,
//   /// however.
//   LastEnumerated = 0x7FF,
// };

// const unsigned LastEnumeratedMetadataKind =
//   (unsigned)MetadataKind::LastEnumerated;

// inline bool isHeapMetadataKind(MetadataKind k) {
//   return !((uint32_t)k & MetadataKindIsNonHeap);
// }
// inline bool isTypeMetadataKind(MetadataKind k) {
//   return !((uint32_t)k & MetadataKindIsNonType);
// }
// inline bool isRuntimePrivateMetadataKind(MetadataKind k) {
//   return (uint32_t)k & MetadataKindIsRuntimePrivate;
// }

// /// Try to translate the 'isa' value of a type/heap metadata into a value
// /// of the MetadataKind enum.
// inline MetadataKind getEnumeratedMetadataKind(uint64_t kind) {
//   if (kind > LastEnumeratedMetadataKind)
//     return MetadataKind::Class;
//   return MetadataKind(kind);
// }

// need to include a bunch of llvm headers to get this to work
// StringRef getStringForMetadataKind(MetadataKind kind);

/// Kinds of Swift nominal type descriptor records.
// enum class NominalTypeKind : uint32_t {
// #define NOMINALTYPEMETADATAKIND(name, value) name = value,
// #include "MetadataKind.def"
// };

// /// The maximum supported type alignment.
// const size_t MaximumAlignment = 16;

/// Flags stored in the value-witness table.
template <typename int_type>
class TargetValueWitnessFlags {
public:
  // The polarity of these bits is chosen so that, when doing struct layout, the
  // flags of the field types can be mostly bitwise-or'ed together to derive the
  // flags for the struct. (The "non-inline" and "has-extra-inhabitants" bits
  // still require additional fixup.)
  enum : uint32_t {
    AlignmentMask =       0x000000FF,
    // unused             0x0000FF00,
    IsNonPOD =            0x00010000,
    IsNonInline =         0x00020000,
    // unused             0x00040000,
    HasSpareBits =        0x00080000,
    IsNonBitwiseTakable = 0x00100000,
    HasEnumWitnesses =    0x00200000,
    Incomplete =          0x00400000,
    // unused             0xFF800000,
  };

  static constexpr const uint32_t MaxNumExtraInhabitants = 0x7FFFFFFF;

private:
  uint32_t Data;

  explicit constexpr TargetValueWitnessFlags(uint32_t data) : Data(data) {}

public:
  constexpr TargetValueWitnessFlags() : Data(0) {}

  /// The required alignment of the first byte of an object of this
  /// type, expressed as a mask of the low bits that must not be set
  /// in the pointer.
  ///
  /// This representation can be easily converted to the 'alignof'
  /// result by merely adding 1, but it is more directly useful for
  /// performing dynamic structure layouts, and it grants an
  /// additional bit of precision in a compact field without needing
  /// to switch to an exponent representation.
  ///
  /// For example, if the type needs to be 8-byte aligned, the
  /// appropriate alignment mask should be 0x7.
  size_t getAlignmentMask() const {
    return (Data & AlignmentMask);
  }
  constexpr TargetValueWitnessFlags withAlignmentMask(size_t alignMask) const {
    return TargetValueWitnessFlags((Data & ~AlignmentMask) | alignMask);
  }

  size_t getAlignment() const { return getAlignmentMask() + 1; }
  constexpr TargetValueWitnessFlags withAlignment(size_t alignment) const {
    return withAlignmentMask(alignment - 1);
  }

  /// True if the type requires out-of-line allocation of its storage.
  /// This can be the case because the value requires more storage or if it is
  /// not bitwise takable.
  bool isInlineStorage() const { return !(Data & IsNonInline); }
  constexpr TargetValueWitnessFlags withInlineStorage(bool isInline) const {
    return TargetValueWitnessFlags((Data & ~IsNonInline) |
                                   (isInline ? 0 : IsNonInline));
  }

  /// True if values of this type can be copied with memcpy and
  /// destroyed with a no-op.
  bool isPOD() const { return !(Data & IsNonPOD); }
  constexpr TargetValueWitnessFlags withPOD(bool isPOD) const {
    return TargetValueWitnessFlags((Data & ~IsNonPOD) |
                                   (isPOD ? 0 : IsNonPOD));
  }

  /// True if values of this type can be taken with memcpy. Unlike C++ 'move',
  /// 'take' is a destructive operation that invalidates the source object, so
  /// most types can be taken with a simple bitwise copy. Only types with side
  /// table references, like @weak references, or types with opaque value
  /// semantics, like imported C++ types, are not bitwise-takable.
  bool isBitwiseTakable() const { return !(Data & IsNonBitwiseTakable); }
  constexpr TargetValueWitnessFlags withBitwiseTakable(bool isBT) const {
    return TargetValueWitnessFlags((Data & ~IsNonBitwiseTakable) |
                                   (isBT ? 0 : IsNonBitwiseTakable));
  }

  /// True if this type's binary representation is that of an enum, and the
  /// enum value witness table entries are available in this type's value
  /// witness table.
  bool hasEnumWitnesses() const { return Data & HasEnumWitnesses; }
  constexpr TargetValueWitnessFlags
  withEnumWitnesses(bool hasEnumWitnesses) const {
    return TargetValueWitnessFlags((Data & ~HasEnumWitnesses) |
                                   (hasEnumWitnesses ? HasEnumWitnesses : 0));
  }

  /// True if the type with this value-witness table is incomplete,
  /// meaning that its external layout (size, etc.) is meaningless
  /// pending completion of the metadata layout.
  bool isIncomplete() const { return Data & Incomplete; }
  constexpr TargetValueWitnessFlags
  withIncomplete(bool isIncomplete) const {
    return TargetValueWitnessFlags((Data & ~Incomplete) |
                                   (isIncomplete ? Incomplete : 0));
  }

  constexpr uint32_t getOpaqueValue() const {
    return Data;
  }
};
using ValueWitnessFlags = TargetValueWitnessFlags<size_t>;


template <unsigned PointerSize>
struct RuntimeTarget;

template <>
struct RuntimeTarget<4> {
  using StoredPointer = uint32_t;
  // To avoid implicit conversions from StoredSignedPointer to StoredPointer.
  using StoredSignedPointer = struct {
    uint32_t SignedValue;
  };
  using StoredSize = uint32_t;
  using StoredPointerDifference = int32_t;
  static constexpr size_t PointerSize = 4;
};

template <>
struct RuntimeTarget<8> {
  using StoredPointer = uint64_t;
  // To avoid implicit conversions from StoredSignedPointer to StoredPointer.
  using StoredSignedPointer = struct {
    uint64_t SignedValue;
  };
  using StoredSize = uint64_t;
  using StoredPointerDifference = int64_t;
  static constexpr size_t PointerSize = 8;
};

/// In-process native runtime target.
///
/// For interactions in the runtime, this should be the equivalent of working
/// with a plain old pointer type.
struct InProcess {
  static constexpr size_t PointerSize = sizeof(uintptr_t);
  using StoredPointer = uintptr_t;
  using StoredSignedPointer = uintptr_t;
  using StoredSize = size_t;
  using StoredPointerDifference = ptrdiff_t;

  static_assert(sizeof(StoredSize) == sizeof(StoredPointerDifference),
                "target uses differently-sized size_t and ptrdiff_t");
  
  template <typename T>
  using Pointer = T*;

  template <typename T>
  using SignedPointer = T;
  
  template <typename T, bool Nullable = false>
  using FarRelativeDirectPointer = FarRelativeDirectPointer<T, Nullable>;

  template <typename T, bool Nullable = false>
  using RelativeIndirectablePointer =
    RelativeIndirectablePointer<T, Nullable>;
  
  template <typename T, bool Nullable = true>
  using RelativeDirectPointer = RelativeDirectPointer<T, Nullable>;
};

/// An external process's runtime target, which may be a different architecture.
template <typename Runtime>
struct External {
  using StoredPointer = typename Runtime::StoredPointer;
  using StoredSignedPointer = typename Runtime::StoredSignedPointer;
  using StoredSize = typename Runtime::StoredSize;
  using StoredPointerDifference = typename Runtime::StoredPointerDifference;
  static constexpr size_t PointerSize = Runtime::PointerSize;
  const StoredPointer PointerValue;
  
  template <typename T>
  using Pointer = StoredPointer;

  template <typename T>
  using SignedPointer = StoredSignedPointer;
  
  template <typename T, bool Nullable = false>
  using FarRelativeDirectPointer = StoredPointer;

  template <typename T, bool Nullable = false>
  using RelativeIndirectablePointer = int32_t;
  
  template <typename T, bool Nullable = true>
  using RelativeDirectPointer = int32_t;
};

/// Template for branching on native pointer types versus external ones
template <typename Runtime, template <typename> class Pointee>
using TargetMetadataPointer
  = typename Runtime::template Pointer<Pointee<Runtime>>;
  
template <typename Runtime, template <typename> class Pointee>
using ConstTargetMetadataPointer
  = typename Runtime::template Pointer<const Pointee<Runtime>>;
  
template <typename Runtime, typename T>
using TargetPointer = typename Runtime::template Pointer<T>;

template <typename Runtime, typename T>
using TargetSignedPointer = typename Runtime::template SignedPointer<T>;
  
template <typename Runtime, typename T>
using ConstTargetPointer = typename Runtime::template Pointer<const T>;


template <typename Runtime, template <typename> class Pointee,
          bool Nullable = true>
using ConstTargetFarRelativeDirectPointer
  = typename Runtime::template FarRelativeDirectPointer<const Pointee<Runtime>,
                                                        Nullable>;

template <typename Runtime, typename Pointee, bool Nullable = true>
using TargetRelativeDirectPointer
  = typename Runtime::template RelativeDirectPointer<Pointee, Nullable>;

template <typename Runtime, typename Pointee, bool Nullable = true>
using TargetRelativeIndirectablePointer
  = typename Runtime::template RelativeIndirectablePointer<Pointee,Nullable>;

struct HeapObject;
class WeakReference;
struct UnownedReference;
  
template <typename Runtime> struct TargetMetadata;
using Metadata = TargetMetadata<InProcess>;


// /// The public state of a metadata.
// enum class MetadataState : size_t {
//   // The values of this enum are set up to give us some future flexibility
//   // in adding states.  The compiler emits unsigned comparisons against
//   // these values, so adding states that aren't totally ordered with at
//   // least the existing values will pose a problem; but we also use a
//   // gradually-shrinking bitset in case it's useful to track states as
//   // separate capabilities.  Specific values have been chosen so that a
//   // MetadataRequest of 0 represents a blocking complete request, which
//   // is the most likely request from ordinary code.  The total size of a
//   // state is kept to 8 bits so that a full request, even with additional
//   // flags, can be materialized as a single immediate on common ISAs, and
//   // so that the state can be extracted with a byte truncation.
//   // The spacing between states reflects guesswork about where new
//   // states/capabilities are most likely to be added.

//   /// The metadata is fully complete.  By definition, this is the
//   /// end-state of all metadata.  Generally, metadata is expected to be
//   /// complete before it can be passed to arbitrary code, e.g. as
//   /// a generic argument to a function or as a metatype value.
//   ///
//   /// In addition to the requirements of NonTransitiveComplete, certain
//   /// transitive completeness guarantees must hold.  Most importantly,
//   /// complete nominal type metadata transitively guarantee the completion
//   /// of their stored generic type arguments and superclass metadata.
//   Complete = 0x00,

//   /// The metadata is fully complete except for any transitive completeness
//   /// guarantees.
//   ///
//   /// In addition to the requirements of LayoutComplete, metadata in this
//   /// state must be prepared for all basic type operations.  This includes:
//   ///
//   ///   - any sort of internal layout necessary to allocate and work
//   ///     with concrete values of the type, such as the instance layout
//   ///     of a class;
//   ///
//   ///   - any sort of external dynamic registration that might be required
//   ///     for the type, such as the realization of a class by the Objective-C
//   ///     runtime; and
//   ///
//   ///   - the initialization of any other information kept in the metadata
//   ///     object, such as a class's v-table.
//   NonTransitiveComplete = 0x01,

//   /// The metadata is ready for the layout of other types that store values
//   /// of this type.
//   ///
//   /// In addition to the requirements of Abstract, metadata in this state
//   /// must have a valid value witness table, meaning that its size,
//   /// alignment, and basic type properties (such as POD-ness) have been
//   /// computed.
//   LayoutComplete = 0x3F,

//   /// The metadata has its basic identity established.  It is possible to
//   /// determine what formal type it corresponds to.  Among other things, it
//   /// is possible to use the runtime mangling facilities with the type.
//   ///
//   /// For example, a metadata for a generic struct has a metadata kind,
//   /// a type descriptor, and all of its type arguments.  However, it does not
//   /// necessarily have a meaningful value-witness table.
//   ///
//   /// References to other types that are not part of the type's basic identity
//   /// may not yet have been established.  Most crucially, this includes the
//   /// superclass pointer.
//   Abstract = 0xFF,
// };

// /// Something that can be static_asserted in all the places where we do
// /// comparisons on metadata states.
// constexpr const bool MetadataStateIsReverseOrdered = true;

// /// Return true if the first metadata state is at least as advanced as the
// /// second.
// inline bool isAtLeast(MetadataState lhs, MetadataState rhs) {
//   static_assert(MetadataStateIsReverseOrdered,
//                 "relying on the ordering of MetadataState here");
//   return size_t(lhs) <= size_t(rhs);
// }

// /// Kinds of requests for metadata.
// class MetadataRequest : public FlagSet<size_t> {
//   using IntType = size_t;
//   using super = FlagSet<IntType>;

// public:
//   enum : IntType {
//     State_bit = 0,
//     State_width = 8,

//     /// A blocking request will not return until the runtime is able to produce
//     /// metadata with the given kind.  A non-blocking request will return
//     /// "immediately", producing an abstract metadata and a flag saying that
//     /// the operation failed.
//     ///
//     /// An abstract request will never be non-zero.
//     NonBlocking_bit = 8,
//   };

//   MetadataRequest(MetadataState state, bool isNonBlocking = false) {
//     setState(state);
//     setIsNonBlocking(isNonBlocking);
//   }
//   explicit MetadataRequest(IntType bits) : super(bits) {}
//   constexpr MetadataRequest() {}

//   FLAGSET_DEFINE_EQUALITY(MetadataRequest)

//   FLAGSET_DEFINE_FIELD_ACCESSORS(State_bit,
//                                  State_width,
//                                  MetadataState,
//                                  getState,
//                                  setState)

//   FLAGSET_DEFINE_FLAG_ACCESSORS(NonBlocking_bit,
//                                 isNonBlocking,
//                                 setIsNonBlocking)
//   bool isBlocking() const { return !isNonBlocking(); }

//   /// Is this request satisfied by a metadata that's in the given state?
//   bool isSatisfiedBy(MetadataState state) const {
//     return isAtLeast(state, getState());
//   }
// };

// struct MetadataTrailingFlags : public FlagSet<uint64_t> {
//   enum {
//     /// Whether this metadata is a specialization of a generic metadata pattern
//     /// which was created during compilation.
//     IsStaticSpecialization = 0,

//     /// Whether this metadata is a specialization of a generic metadata pattern
//     /// which was created during compilation and made to be canonical by
//     /// modifying the metadata accessor.
//     IsCanonicalStaticSpecialization = 1,
//   };

//   explicit MetadataTrailingFlags(uint64_t bits) : FlagSet(bits) {}
//   constexpr MetadataTrailingFlags() {}

//   FLAGSET_DEFINE_FLAG_ACCESSORS(IsStaticSpecialization,
//                                 isStaticSpecialization,
//                                 setIsStaticSpecialization)

//   FLAGSET_DEFINE_FLAG_ACCESSORS(IsCanonicalStaticSpecialization,
//                                 isCanonicalStaticSpecialization,
//                                 setIsCanonicalStaticSpecialization)
// };




/// The result of requesting type metadata.  Generally the return value of
/// a function.
///
/// For performance and ABI matching across Swift/C++, functions returning
/// this type must use SWIFT_CC so that the components are returned as separate
/// values.
struct MetadataResponse {
  /// The requested metadata.
  const Metadata *Value;

  /// The current state of the metadata returned.  Always use this
  /// instead of trying to inspect the metadata directly to see if it
  /// satisfies the request.  An incomplete metadata may be getting
  /// initialized concurrently.  But this can generally be ignored if
  /// the metadata request was for abstract metadata or if the request
  /// is blocking.
  MetadataState State;
};

/// A dependency on the metadata progress of other type, indicating that
/// initialization of a metadata cannot progress until another metadata
/// reaches a particular state.
///
/// For performance, functions returning this type should use SWIFT_CC so
/// that the components are returned as separate values.
struct MetadataDependency {
  /// Either null, indicating that initialization was successful, or
  /// a metadata on which initialization depends for further progress.
  const Metadata *Value;

  /// The state that Metadata needs to be in before initialization
  /// can continue.
  MetadataState Requirement;

  MetadataDependency() : Value(nullptr) {}
  MetadataDependency(const Metadata *metadata, MetadataState requirement)
    : Value(metadata), Requirement(requirement) {}

  explicit operator bool() const { return Value != nullptr; }

  bool operator==(MetadataDependency other) const {
    assert(Value && other.Value);
    return Value == other.Value &&
           Requirement == other.Requirement;
  }
};

template <typename Runtime> struct TargetProtocolConformanceDescriptor;

/// Storage for an arbitrary value.  In C/C++ terms, this is an
/// 'object', because it is rooted in memory.
///
/// The context dictates what type is actually stored in this object,
/// and so this type is intentionally incomplete.
///
/// An object can be in one of two states:
///  - An uninitialized object has a completely unspecified state.
///  - An initialized object holds a valid value of the type.
struct OpaqueValue;

/// A fixed-size buffer for local values.  It is capable of owning
/// (possibly in side-allocated memory) the storage necessary
/// to hold a value of an arbitrary type.  Because it is fixed-size,
/// it can be allocated in places that must be agnostic to the
/// actual type: for example, within objects of existential type,
/// or for local variables in generic functions.
///
/// The context dictates its type, which ultimately means providing
/// access to a value witness table by which the value can be
/// accessed and manipulated.
///
/// A buffer can directly store three pointers and is pointer-aligned.
/// Three pointers is a sweet spot for Swift, because it means we can
/// store a structure containing a pointer, a size, and an owning
/// object, which is a common pattern in code due to ARC.  In a GC
/// environment, this could be reduced to two pointers without much loss.
///
/// A buffer can be in one of three states:
///  - An unallocated buffer has a completely unspecified state.
///  - An allocated buffer has been initialized so that it
///    owns uninitialized value storage for the stored type.
///  - An initialized buffer is an allocated buffer whose value
///    storage has been initialized.
template <typename Runtime>
struct TargetValueBuffer {
  TargetPointer<Runtime, void> PrivateData[NumWords_ValueBuffer];
};
using ValueBuffer = TargetValueBuffer<InProcess>;

/// Can a value with the given size and alignment be allocated inline?
constexpr inline bool canBeInline(bool isBitwiseTakable, size_t size,
                                  size_t alignment) {
  return isBitwiseTakable && size <= sizeof(ValueBuffer) &&
         alignment <= alignof(ValueBuffer);
}

template <class T>
constexpr inline bool canBeInline(bool isBitwiseTakable) {
  return canBeInline(isBitwiseTakable, sizeof(T), alignof(T));
}

template <typename Runtime> struct TargetValueWitnessTable;
using ValueWitnessTable = TargetValueWitnessTable<InProcess>;

template <typename Runtime> class TargetValueWitnessTypes;
using ValueWitnessTypes = TargetValueWitnessTypes<InProcess>;

template <typename Runtime>
class TargetValueWitnessTypes {
public:
  using StoredPointer = typename Runtime::StoredPointer;

// Note that, for now, we aren't strict about 'const'.
#define WANT_ALL_VALUE_WITNESSES
#define DATA_VALUE_WITNESS(lowerId, upperId, type)
#define FUNCTION_VALUE_WITNESS(lowerId, upperId, returnType, paramTypes) \
  typedef returnType (*lowerId ## Unsigned) paramTypes; \
  typedef TargetSignedPointer<Runtime, lowerId ## Unsigned> lowerId;
#define MUTABLE_VALUE_TYPE TargetPointer<Runtime, OpaqueValue>
#define IMMUTABLE_VALUE_TYPE ConstTargetPointer<Runtime, OpaqueValue>
#define MUTABLE_BUFFER_TYPE TargetPointer<Runtime, ValueBuffer>
#define IMMUTABLE_BUFFER_TYPE ConstTargetPointer<Runtime, ValueBuffer>
#define TYPE_TYPE ConstTargetPointer<Runtime, Metadata>
#define SIZE_TYPE StoredSize
#define INT_TYPE int
#define UINT_TYPE unsigned
#define VOID_TYPE void
#include "ValueWitness.def"

  // Handle the data witnesses explicitly so we can use more specific
  // types for the flags enums.
  typedef size_t size;
  typedef size_t stride;
  typedef ValueWitnessFlags flags;
  typedef uint32_t extraInhabitantCount;
};

struct TypeLayout;

/// A value-witness table.  A value witness table is built around
/// the requirements of some specific type.  The information in
/// a value-witness table is intended to be sufficient to lay out
/// and manipulate values of an arbitrary type.
template <typename Runtime> struct TargetValueWitnessTable {
  // For the meaning of all of these witnesses, consult the comments
  // on their associated typedefs, above.

#define WANT_ONLY_REQUIRED_VALUE_WITNESSES
#define VALUE_WITNESS(LOWER_ID, UPPER_ID) \
  typename TargetValueWitnessTypes<Runtime>::LOWER_ID LOWER_ID;
#define FUNCTION_VALUE_WITNESS(LOWER_ID, UPPER_ID, RET, PARAMS) \
  typename TargetValueWitnessTypes<Runtime>::LOWER_ID LOWER_ID;

#include "ValueWitness.def"

  using StoredSize = typename Runtime::StoredSize;

  /// Is the external type layout of this type incomplete?
  bool isIncomplete() const {
    return flags.isIncomplete();
  }

  /// Would values of a type with the given layout requirements be
  /// allocated inline?
  static bool isValueInline(bool isBitwiseTakable, StoredSize size,
                            StoredSize alignment) {
    return (isBitwiseTakable && size <= sizeof(TargetValueBuffer<Runtime>) &&
            alignment <= alignof(TargetValueBuffer<Runtime>));
  }

  /// Are values of this type allocated inline?
  bool isValueInline() const {
    return flags.isInlineStorage();
  }

  /// Is this type POD?
  bool isPOD() const {
    return flags.isPOD();
  }

  /// Is this type bitwise-takable?
  bool isBitwiseTakable() const {
    return flags.isBitwiseTakable();
  }

  /// Return the size of this type.  Unlike in C, this has not been
  /// padded up to the alignment; that value is maintained as
  /// 'stride'.
  StoredSize getSize() const {
    return size;
  }

  /// Return the stride of this type.  This is the size rounded up to
  /// be a multiple of the alignment.
  StoredSize getStride() const {
    return stride;
  }

  /// Return the alignment required by this type, in bytes.
  StoredSize getAlignment() const {
    return flags.getAlignment();
  }

  /// The alignment mask of this type.  An offset may be rounded up to
  /// the required alignment by adding this mask and masking by its
  /// bit-negation.
  ///
  /// For example, if the type needs to be 8-byte aligned, the value
  /// of this witness is 0x7.
  StoredSize getAlignmentMask() const {
    return flags.getAlignmentMask();
  }
  
  /// The number of extra inhabitants, that is, bit patterns that do not form
  /// valid values of the type, in this type's binary representation.
  unsigned getNumExtraInhabitants() const {
    return extraInhabitantCount;
  }

  /// Assert that this value witness table is an enum value witness table
  /// and return it as such.
  ///
  /// This has an awful name because it's supposed to be internal to
  /// this file.  Code outside this file should use LLVM's cast/dyn_cast.
  /// We don't want to use those here because we need to avoid accidentally
  /// introducing ABI dependencies on LLVM structures.
  const struct EnumValueWitnessTable *_asEVWT() const;

  /// Get the type layout record within this value witness table.
  const TypeLayout *getTypeLayout() const {
    return reinterpret_cast<const TypeLayout *>(&size);
  }

  /// Check whether this metadata is complete.
  bool checkIsComplete() const;

  /// "Publish" the layout of this type to other threads.  All other stores
  /// to the value witness table (including its extended header) should have
  /// happened before this is called.
  void publishLayout(const TypeLayout &layout);
};

/// The header before a metadata object which appears on all type
/// metadata.  Note that heap metadata are not necessarily type
/// metadata, even for objects of a heap type: for example, objects of
/// Objective-C type possess a form of heap metadata (an Objective-C
/// Class pointer), but this metadata lacks the type metadata header.
/// This case can be distinguished using the isTypeMetadata() flag
/// on ClassMetadata.
template <typename Runtime>
struct TargetTypeMetadataHeader {
  /// A pointer to the value-witnesses for this type.  This is only
  /// present for type metadata.
  TargetPointer<Runtime, const ValueWitnessTable> ValueWitnesses;
};
using TypeMetadataHeader = TargetTypeMetadataHeader<InProcess>;

/// A "full" metadata pointer is simply an adjusted address point on a
/// metadata object; it points to the beginning of the metadata's
/// allocation, rather than to the canonical address point of the
/// metadata object.
template <class T> struct FullMetadata : T::HeaderType, T {
  typedef typename T::HeaderType HeaderType;

  FullMetadata() = default;
  constexpr FullMetadata(const HeaderType &header, const T &metadata)
    : HeaderType(header), T(metadata) {}
};

/// Given a canonical metadata pointer, produce the adjusted metadata pointer.
template <class T>
static inline FullMetadata<T> *asFullMetadata(T *metadata) {
  return (FullMetadata<T>*) (((typename T::HeaderType*) metadata) - 1);
}
template <class T>
static inline const FullMetadata<T> *asFullMetadata(const T *metadata) {
  return asFullMetadata(const_cast<T*>(metadata));
}


// std::result_of is busted in Xcode 5. This is a simplified reimplementation
// that isn't SFINAE-safe.
namespace {
  template<typename T> struct _ResultOf;
  
  template<typename R, typename...A>
  struct _ResultOf<R(*)(A...)> {
    using type = R;
  };
}

template <typename Runtime> struct TargetGenericMetadataInstantiationCache;
template <typename Runtime> struct TargetAnyClassMetadata;
template <typename Runtime> struct TargetClassMetadata;
template <typename Runtime> struct TargetStructMetadata;
template <typename Runtime> struct TargetOpaqueMetadata;
template <typename Runtime> struct TargetValueMetadata;
template <typename Runtime> struct TargetForeignClassMetadata;
template <typename Runtime> struct TargetContextDescriptor;
template <typename Runtime> class TargetTypeContextDescriptor;
template <typename Runtime> class TargetClassDescriptor;
template <typename Runtime> class TargetValueTypeDescriptor;
template <typename Runtime> class TargetEnumDescriptor;
template <typename Runtime> class TargetStructDescriptor;
template <typename Runtime> struct TargetGenericMetadataPattern;

// FIXME: https://bugs.swift.org/browse/SR-1155
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-offsetof"

/// Bounds for metadata objects.
template <typename Runtime>
struct TargetMetadataBounds {
  using StoredSize = typename Runtime::StoredSize;

  /// The negative extent of the metadata, in words.
  uint32_t NegativeSizeInWords;

  /// The positive extent of the metadata, in words.
  uint32_t PositiveSizeInWords;

  /// Return the total size of the metadata in bytes, including both
  /// negatively- and positively-offset members.
  StoredSize getTotalSizeInBytes() const {
    return (StoredSize(NegativeSizeInWords) + StoredSize(PositiveSizeInWords))
              * sizeof(void*);
  }

  /// Return the offset of the address point of the metadata from its
  /// start, in bytes.
  StoredSize getAddressPointInBytes() const {
    return StoredSize(NegativeSizeInWords) * sizeof(void*);
  }
};
using MetadataBounds = TargetMetadataBounds<InProcess>;

/// The common structure of all type metadata.
template <typename Runtime>
struct TargetMetadata {
  using StoredPointer = typename Runtime::StoredPointer;

  /// The basic header type.
  typedef TargetTypeMetadataHeader<Runtime> HeaderType;

  constexpr TargetMetadata()
    : Kind(static_cast<StoredPointer>(MetadataKind::Class)) {}
  constexpr TargetMetadata(MetadataKind Kind)
    : Kind(static_cast<StoredPointer>(Kind)) {}

private:
  /// The kind. Only valid for non-class metadata; getKind() must be used to get
  /// the kind value.
  StoredPointer Kind;
public:
  /// Get the metadata kind.
  MetadataKind getKind() const {
    return getEnumeratedMetadataKind(Kind);
  }
  
  /// Set the metadata kind.
  void setKind(MetadataKind kind) {
    Kind = static_cast<StoredPointer>(kind);
  }

public:
  /// Is this a class object--the metadata record for a Swift class (which also
  /// serves as the class object), or the class object for an ObjC class (which
  /// is not metadata)?
  bool isClassObject() const {
    return static_cast<MetadataKind>(getKind()) == MetadataKind::Class;
  }
  
  /// Does the given metadata kind represent metadata for some kind of class?
  static bool isAnyKindOfClass(MetadataKind k) {
    switch (k) {
    case MetadataKind::Class:
    case MetadataKind::ObjCClassWrapper:
    case MetadataKind::ForeignClass:
      return true;

    default:
      return false;
    }
  }
  
  /// Is this metadata for an existential type?
  bool isAnyExistentialType() const {
    switch (getKind()) {
    case MetadataKind::ExistentialMetatype:
    case MetadataKind::Existential:
      return true;

    default:
      return false;
    }
  }
  
  /// Is this either type metadata or a class object for any kind of class?
  bool isAnyClass() const {
    return isAnyKindOfClass(getKind());
  }

  const ValueWitnessTable *getValueWitnesses() const {
    return asFullMetadata(this)->ValueWitnesses;
  }

  const TypeLayout *getTypeLayout() const {
    return getValueWitnesses()->getTypeLayout();
  }

  void setValueWitnesses(const ValueWitnessTable *table) {
    asFullMetadata(this)->ValueWitnesses = table;
  }
  
  // Define forwarders for value witnesses. These invoke this metadata's value
  // witness table with itself as the 'self' parameter.
  #define WANT_ONLY_REQUIRED_VALUE_WITNESSES
  #define FUNCTION_VALUE_WITNESS(WITNESS, UPPER, RET_TYPE, PARAM_TYPES)    \
    template<typename...A>                                                 \
    _ResultOf<ValueWitnessTypes::WITNESS ## Unsigned>::type                            \
    vw_##WITNESS(A &&...args) const {                                      \
      return getValueWitnesses()->WITNESS(args..., this); \
    }
  #define DATA_VALUE_WITNESS(LOWER, UPPER, TYPE)
  #include "ValueWitness.def"

  unsigned vw_getEnumTag(const OpaqueValue *value) const {
    return getValueWitnesses()->_asEVWT()->getEnumTag(const_cast<OpaqueValue*>(value), this);
  }
  void vw_destructiveProjectEnumData(OpaqueValue *value) const {
    getValueWitnesses()->_asEVWT()->destructiveProjectEnumData(value, this);
  }
  void vw_destructiveInjectEnumTag(OpaqueValue *value, unsigned tag) const {
    getValueWitnesses()->_asEVWT()->destructiveInjectEnumTag(value, tag, this);
  }

  size_t vw_size() const {
    return getValueWitnesses()->getSize();
  }

  size_t vw_alignment() const {
    return getValueWitnesses()->getAlignment();
  }

  size_t vw_stride() const {
    return getValueWitnesses()->getStride();
  }

  unsigned vw_getNumExtraInhabitants() const {
    return getValueWitnesses()->getNumExtraInhabitants();
  }

  /// Allocate an out-of-line buffer if values of this type don't fit in the
  /// ValueBuffer.
  /// NOTE: This is not a box for copy-on-write existentials.
  OpaqueValue *allocateBufferIn(ValueBuffer *buffer) const;

  /// Get the address of the memory previously allocated in the ValueBuffer.
  /// NOTE: This is not a box for copy-on-write existentials.
  OpaqueValue *projectBufferFrom(ValueBuffer *buffer) const;

  /// Deallocate an out-of-line buffer stored in 'buffer' if values of this type
  /// are not stored inline in the ValueBuffer.
  void deallocateBufferIn(ValueBuffer *buffer) const;

  // Allocate an out-of-line buffer box (reference counted) if values of this
  // type don't fit in the ValueBuffer.
  // NOTE: This *is* a box for copy-on-write existentials.
  OpaqueValue *allocateBoxForExistentialIn(ValueBuffer *Buffer) const;

  // Deallocate an out-of-line buffer box if one is present.
  void deallocateBoxForExistentialIn(ValueBuffer *Buffer) const;

  /// Get the nominal type descriptor if this metadata describes a nominal type,
  /// or return null if it does not.
  ConstTargetMetadataPointer<Runtime, TargetTypeContextDescriptor>
  getTypeContextDescriptor() const {
    switch (getKind()) {
    case MetadataKind::Class: {
      const auto cls = static_cast<const TargetClassMetadata<Runtime> *>(this);
      if (!cls->isTypeMetadata())
        return nullptr;
      if (cls->isArtificialSubclass())
        return nullptr;
      return cls->getDescription();
    }
    case MetadataKind::Struct:
    case MetadataKind::Enum:
    case MetadataKind::Optional:
      return static_cast<const TargetValueMetadata<Runtime> *>(this)
          ->Description;
    case MetadataKind::ForeignClass:
      return static_cast<const TargetForeignClassMetadata<Runtime> *>(this)
          ->Description;
    default:
      return nullptr;
    }
  }

  /// Get the class object for this type if it has one, or return null if the
  /// type is not a class (or not a class with a class object).
  const TargetClassMetadata<Runtime> *getClassObject() const;

  /// Retrieve the generic arguments of this type, if it has any.
  ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> const *
  getGenericArgs() const {
    auto description = getTypeContextDescriptor();
    if (!description)
      return nullptr;

    auto generics = description->getGenericContext();
    if (!generics)
      return nullptr;

    auto asWords = reinterpret_cast<
      ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> const *>(this);
    return asWords + description->getGenericArgumentOffset();
  }

  bool satisfiesClassConstraint() const;

  bool isCanonicalStaticallySpecializedGenericMetadata() const;

#ifndef NDEBUG
  LLVM_ATTRIBUTE_DEPRECATED(void dump() const,
                            "Only meant for use in the debugger");
#endif

protected:
  friend struct TargetOpaqueMetadata<Runtime>;
  
  /// Metadata should not be publicly copied or moved.
  constexpr TargetMetadata(const TargetMetadata &) = default;
  TargetMetadata &operator=(const TargetMetadata &) = default;
  constexpr TargetMetadata(TargetMetadata &&) = default;
  TargetMetadata &operator=(TargetMetadata &&) = default;
};

/// The common structure of opaque metadata.  Adds nothing.
template <typename Runtime>
struct TargetOpaqueMetadata {
  typedef TargetTypeMetadataHeader<Runtime> HeaderType;

  // We have to represent this as a member so we can list-initialize it.
  TargetMetadata<Runtime> base;
};

#warning "HeapObjectDestroyer parameter should be SWIFT_CONTEXT but swiftcall is not supported on this platform, investigate any call site issues"
using HeapObjectDestroyer =
  SWIFT_CC(swift) void(HeapObject *);

/// The prefix on a heap metadata.
template <typename Runtime>
struct TargetHeapMetadataHeaderPrefix {
  /// Destroy the object, returning the allocated size of the object
  /// or 0 if the object shouldn't be deallocated.
  TargetSignedPointer<Runtime, HeapObjectDestroyer *__ptrauth_swift_heap_object_destructor> destroy;
};
using HeapMetadataHeaderPrefix =
  TargetHeapMetadataHeaderPrefix<InProcess>;

/// The header present on all heap metadata.
template <typename Runtime>
struct TargetHeapMetadataHeader
    : TargetHeapMetadataHeaderPrefix<Runtime>,
      TargetTypeMetadataHeader<Runtime> {
  constexpr TargetHeapMetadataHeader(
      const TargetHeapMetadataHeaderPrefix<Runtime> &heapPrefix,
      const TargetTypeMetadataHeader<Runtime> &typePrefix)
    : TargetHeapMetadataHeaderPrefix<Runtime>(heapPrefix),
      TargetTypeMetadataHeader<Runtime>(typePrefix) {}
};
using HeapMetadataHeader =
  TargetHeapMetadataHeader<InProcess>;


/// The common structure of all metadata for heap-allocated types.  A
/// pointer to one of these can be retrieved by loading the 'isa'
/// field of any heap object, whether it was managed by Swift or by
/// Objective-C.  However, when loading from an Objective-C object,
/// this metadata may not have the heap-metadata header, and it may
/// not be the Swift type metadata for the object's dynamic type.
template <typename Runtime>
struct TargetHeapMetadata : TargetMetadata<Runtime> {
  using HeaderType = TargetHeapMetadataHeader<Runtime>;

  TargetHeapMetadata() = default;
  constexpr TargetHeapMetadata(MetadataKind kind)
    : TargetMetadata<Runtime>(kind) {}
};
using HeapMetadata = TargetHeapMetadata<InProcess>;

/// An opaque descriptor describing a class or protocol method. References to
/// these descriptors appear in the method override table of a class context
/// descriptor, or a resilient witness table pattern, respectively.
///
/// Clients should not assume anything about the contents of this descriptor
/// other than it having 4 byte alignment.
template <typename Runtime>
struct TargetMethodDescriptor {
  /// Flags describing the method.
  MethodDescriptorFlags Flags;

  /// The method implementation.
  TargetRelativeDirectPointer<Runtime, void> Impl;

  // TODO: add method types or anything else needed for reflection.
};

using MethodDescriptor = TargetMethodDescriptor<InProcess>;

/// Header for a class vtable descriptor. This is a variable-sized
/// structure that describes how to find and parse a vtable
/// within the type metadata for a class.
template <typename Runtime>
struct TargetVTableDescriptorHeader {
  using StoredPointer = typename Runtime::StoredPointer;

private:
  /// The offset of the vtable for this class in its metadata, if any,
  /// in words.
  ///
  /// If this class has a resilient superclass, this offset is relative to the
  /// the start of the immediate class's metadata. Otherwise, it is relative
  /// to the metadata address point.
  uint32_t VTableOffset;

public:
  /// The number of vtable entries. This is the number of MethodDescriptor
  /// records following the vtable header in the class's nominal type
  /// descriptor, which is equal to the number of words this subclass's vtable
  /// entries occupy in instantiated class metadata.
  uint32_t VTableSize;

  uint32_t getVTableOffset(const TargetClassDescriptor<Runtime> *description) const {
    if (description->hasResilientSuperclass()) {
      auto bounds = description->getMetadataBounds();
      return (bounds.ImmediateMembersOffset / sizeof(StoredPointer)
              + VTableOffset);
    }

    return VTableOffset;
  }
};

template<typename Runtime> struct TargetContextDescriptor;

template<typename Runtime,
         template<typename _Runtime> class Context = TargetContextDescriptor>
using TargetSignedContextPointer = TargetSignedPointer<Runtime,
                          Context<Runtime> * __ptrauth_swift_type_descriptor>;

template<typename Runtime,
         template<typename _Runtime> class Context = TargetContextDescriptor>
using TargetRelativeContextPointer =
  RelativeIndirectablePointer<const Context<Runtime>,
                              /*nullable*/ true, int32_t,
                              TargetSignedContextPointer<Runtime, Context>>;

using RelativeContextPointer = TargetRelativeContextPointer<InProcess>;

template<typename Runtime, typename IntTy,
         template<typename _Runtime> class Context = TargetContextDescriptor>
using RelativeContextPointerIntPair =
  RelativeIndirectablePointerIntPair<const Context<Runtime>, IntTy,
                              /*nullable*/ true, int32_t,
                              TargetSignedContextPointer<Runtime, Context>>;

template<typename Runtime> struct TargetMethodDescriptor;

template<typename Runtime>
using TargetRelativeMethodDescriptorPointer =
  RelativeIndirectablePointer<const TargetMethodDescriptor<Runtime>,
                              /*nullable*/ true>;

using RelativeMethodDescriptorPointer =
  TargetRelativeMethodDescriptorPointer<InProcess>;

template<typename Runtime> struct TargetProtocolRequirement;

template<typename Runtime>
using TargetRelativeProtocolRequirementPointer =
  RelativeIndirectablePointer<const TargetProtocolRequirement<Runtime>,
                              /*nullable*/ true>;

using RelativeProtocolRequirementPointer =
  TargetRelativeProtocolRequirementPointer<InProcess>;

/// An entry in the method override table, referencing a method from one of our
/// ancestor classes, together with an implementation.
template <typename Runtime>
struct TargetMethodOverrideDescriptor {
  /// The class containing the base method.
  TargetRelativeContextPointer<Runtime> Class;

  /// The base method.
  TargetRelativeMethodDescriptorPointer<Runtime> Method;

  /// The implementation of the override.
  TargetRelativeDirectPointer<Runtime, void, /*nullable*/ true> Impl;
};

/// Header for a class vtable override descriptor. This is a variable-sized
/// structure that provides implementations for overrides of methods defined
/// in superclasses.
template <typename Runtime>
struct TargetOverrideTableHeader {
  /// The number of MethodOverrideDescriptor records following the vtable
  /// override header in the class's nominal type descriptor.
  uint32_t NumEntries;
};














/// Heap metadata for a box, which may have been generated statically by the
/// compiler or by the runtime.
template <typename Runtime>
struct TargetBoxHeapMetadata : public TargetHeapMetadata<Runtime> {
  /// The offset from the beginning of a box to its value.
  unsigned Offset;

  constexpr TargetBoxHeapMetadata(MetadataKind kind, unsigned offset)
  : TargetHeapMetadata<Runtime>(kind), Offset(offset) {}
};
using BoxHeapMetadata = TargetBoxHeapMetadata<InProcess>;

/// Heap metadata for runtime-instantiated generic boxes.
template <typename Runtime>
struct TargetGenericBoxHeapMetadata : public TargetBoxHeapMetadata<Runtime> {
  using super = TargetBoxHeapMetadata<Runtime>;
  using super::Offset;

  /// The type inside the box.
  ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> BoxedType;

  constexpr
  TargetGenericBoxHeapMetadata(MetadataKind kind, unsigned offset,
    ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> boxedType)
  : TargetBoxHeapMetadata<Runtime>(kind, offset), BoxedType(boxedType)
  {}

  static unsigned getHeaderOffset(const Metadata *boxedType) {
    // Round up the header size to alignment.
    unsigned alignMask = boxedType->getValueWitnesses()->getAlignmentMask();
    return (sizeof(HeapObject) + alignMask) & ~alignMask;
  }

  /// Project the value out of a box of this type.
  OpaqueValue *project(HeapObject *box) const {
    auto bytes = reinterpret_cast<char*>(box);
    return reinterpret_cast<OpaqueValue *>(bytes + Offset);
  }

  /// Get the allocation size of this box.
  unsigned getAllocSize() const {
    return Offset + BoxedType->getValueWitnesses()->getSize();
  }

  /// Get the allocation alignment of this box.
  unsigned getAllocAlignMask() const {
    // Heap allocations are at least pointer aligned.
    return BoxedType->getValueWitnesses()->getAlignmentMask()
      | (alignof(void*) - 1);
  }

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::HeapGenericLocalVariable;
  }
};
using GenericBoxHeapMetadata = TargetGenericBoxHeapMetadata<InProcess>;


/// The structure of metadata for heap-allocated local variables.
/// This is non-type metadata.
template <typename Runtime>
struct TargetHeapLocalVariableMetadata
  : public TargetHeapMetadata<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;
  uint32_t OffsetToFirstCapture;
  TargetPointer<Runtime, const char> CaptureDescription;

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::HeapLocalVariable;
  }
  constexpr TargetHeapLocalVariableMetadata()
      : TargetHeapMetadata<Runtime>(MetadataKind::HeapLocalVariable),
        OffsetToFirstCapture(0), CaptureDescription(nullptr) {}
};
using HeapLocalVariableMetadata
  = TargetHeapLocalVariableMetadata<InProcess>;

/// The structure of metadata for foreign types where the source
/// language doesn't provide any sort of more interesting metadata for
/// us to use.
template <typename Runtime>
struct TargetForeignTypeMetadata : public TargetMetadata<Runtime> {
};
using ForeignTypeMetadata = TargetForeignTypeMetadata<InProcess>;

/// The structure of metadata objects for foreign class types.
/// A foreign class is a foreign type with reference semantics and
/// Swift-supported reference counting.  Generally this requires
/// special logic in the importer.
///
/// We assume for now that foreign classes are entirely opaque
/// to Swift introspection.
template <typename Runtime>
struct TargetForeignClassMetadata : public TargetForeignTypeMetadata<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;

  /// An out-of-line description of the type.
  TargetSignedPointer<Runtime, const TargetClassDescriptor<Runtime> * __ptrauth_swift_type_descriptor> Description;

  /// The superclass of the foreign class, if any.
  ConstTargetMetadataPointer<Runtime, swift::TargetForeignClassMetadata>
    Superclass;

  /// Reserved space.  For now, this should be zero-initialized.
  /// If this is used for anything in the future, at least some of these
  /// first bits should be flags.
  StoredPointer Reserved[1];

  ConstTargetMetadataPointer<Runtime, TargetClassDescriptor>
  getDescription() const {
    return Description;
  }

  typename Runtime::StoredSignedPointer
  getDescriptionAsSignedPointer() const {
    return Description;
  }

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::ForeignClass;
  }
};
using ForeignClassMetadata = TargetForeignClassMetadata<InProcess>;

/// The common structure of metadata for structs and enums.
template <typename Runtime>
struct TargetValueMetadata : public TargetMetadata<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;
  TargetValueMetadata(MetadataKind Kind,
                      const TargetTypeContextDescriptor<Runtime> *description)
      : TargetMetadata<Runtime>(Kind), Description(description) {}

  /// An out-of-line description of the type.
  TargetSignedPointer<Runtime, const TargetValueTypeDescriptor<Runtime> * __ptrauth_swift_type_descriptor> Description;

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Struct
      || metadata->getKind() == MetadataKind::Enum
      || metadata->getKind() == MetadataKind::Optional;
  }

  ConstTargetMetadataPointer<Runtime, TargetValueTypeDescriptor>
  getDescription() const {
    return Description;
  }

  typename Runtime::StoredSignedPointer
  getDescriptionAsSignedPointer() const {
    return Description;
  }
};
using ValueMetadata = TargetValueMetadata<InProcess>;

/// The structure of type metadata for structs.
template <typename Runtime>
struct TargetStructMetadata : public TargetValueMetadata<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;
  using TargetValueMetadata<Runtime>::TargetValueMetadata;

  const TargetStructDescriptor<Runtime> *getDescription() const {
    return llvm::cast<TargetStructDescriptor<Runtime>>(this->Description);
  }

  // The first trailing field of struct metadata is always the generic
  // argument array.

  /// Get a pointer to the field offset vector, if present, or null.
  const uint32_t *getFieldOffsets() const {
    auto offset = getDescription()->FieldOffsetVectorOffset;
    if (offset == 0)
      return nullptr;
    auto asWords = reinterpret_cast<const void * const*>(this);
    return reinterpret_cast<const uint32_t *>(asWords + offset);
  }

  bool isCanonicalStaticallySpecializedGenericMetadata() const {
    auto *description = getDescription();
    if (!description->isGeneric())
      return false;

    auto *trailingFlags = getTrailingFlags();
    if (trailingFlags == nullptr)
      return false;

    return trailingFlags->isCanonicalStaticSpecialization();
  }

  const MetadataTrailingFlags *getTrailingFlags() const {
    auto description = getDescription();
    auto flags = description->getFullGenericContextHeader()
                     .DefaultInstantiationPattern->PatternFlags;
    if (!flags.hasTrailingFlags())
      return nullptr;
    auto fieldOffset = description->FieldOffsetVectorOffset;
    auto offset =
        fieldOffset +
        // Pad to the nearest pointer.
        ((description->NumFields * sizeof(uint32_t) + sizeof(void *) - 1) /
         sizeof(void *));
    auto asWords = reinterpret_cast<const void *const *>(this);
    return reinterpret_cast<const MetadataTrailingFlags *>(asWords + offset);
  }

  static constexpr int32_t getGenericArgumentOffset() {
    return sizeof(TargetStructMetadata<Runtime>) / sizeof(StoredPointer);
  }

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Struct;
  }
};
using StructMetadata = TargetStructMetadata<InProcess>;

/// The structure of type metadata for enums.
template <typename Runtime>
struct TargetEnumMetadata : public TargetValueMetadata<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;
  using StoredSize = typename Runtime::StoredSize;
  using TargetValueMetadata<Runtime>::TargetValueMetadata;

  const TargetEnumDescriptor<Runtime> *getDescription() const {
    return llvm::cast<TargetEnumDescriptor<Runtime>>(this->Description);
  }

  // The first trailing field of enum metadata is always the generic
  // argument array.

  /// True if the metadata records the size of the payload area.
  bool hasPayloadSize() const {
    return getDescription()->hasPayloadSizeOffset();
  }

  /// Retrieve the size of the payload area.
  ///
  /// `hasPayloadSize` must be true for this to be valid.
  StoredSize getPayloadSize() const {
    assert(hasPayloadSize());
    auto offset = getDescription()->getPayloadSizeOffset();
    const StoredSize *asWords = reinterpret_cast<const StoredSize *>(this);
    asWords += offset;
    return *asWords;
  }

  StoredSize &getPayloadSize() {
    assert(hasPayloadSize());
    auto offset = getDescription()->getPayloadSizeOffset();
    StoredSize *asWords = reinterpret_cast<StoredSize *>(this);
    asWords += offset;
    return *asWords;
  }

  bool isCanonicalStaticallySpecializedGenericMetadata() const {
    auto *description = getDescription();
    if (!description->isGeneric())
      return false;

    auto *trailingFlags = getTrailingFlags();
    if (trailingFlags == nullptr)
      return false;

    return trailingFlags->isCanonicalStaticSpecialization();
  }

  const MetadataTrailingFlags *getTrailingFlags() const {
    auto description = getDescription();
    auto flags = description->getFullGenericContextHeader()
                     .DefaultInstantiationPattern->PatternFlags;
    if (!flags.hasTrailingFlags())
      return nullptr;
    auto offset =
        getGenericArgumentOffset() +
        description->getFullGenericContextHeader().Base.getNumArguments() +
        (hasPayloadSize() ? 1 : 0);
    auto asWords = reinterpret_cast<const void *const *>(this);
    return reinterpret_cast<const MetadataTrailingFlags *>(asWords + offset);
  }

  static constexpr int32_t getGenericArgumentOffset() {
    return sizeof(TargetEnumMetadata<Runtime>) / sizeof(StoredPointer);
  }

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Enum
      || metadata->getKind() == MetadataKind::Optional;
  }
};
using EnumMetadata = TargetEnumMetadata<InProcess>;

/// The structure of function type metadata.
template <typename Runtime>
struct TargetFunctionTypeMetadata : public TargetMetadata<Runtime> {
  using StoredSize = typename Runtime::StoredSize;
  using Parameter = ConstTargetMetadataPointer<Runtime, swift::TargetMetadata>;

  TargetFunctionTypeFlags<StoredSize> Flags;

  /// The type metadata for the result type.
  ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> ResultType;

  Parameter *getParameters() { return reinterpret_cast<Parameter *>(this + 1); }

  const Parameter *getParameters() const {
    return reinterpret_cast<const Parameter *>(this + 1);
  }

  Parameter getParameter(unsigned index) const {
    assert(index < getNumParameters());
    return getParameters()[index];
  }

  ParameterFlags getParameterFlags(unsigned index) const {
    assert(index < getNumParameters());
    auto flags = hasParameterFlags() ? getParameterFlags()[index] : 0;
    return ParameterFlags::fromIntValue(flags);
  }

  StoredSize getNumParameters() const {
    return Flags.getNumParameters();
  }
  FunctionMetadataConvention getConvention() const {
    return Flags.getConvention();
  }
  bool throws() const { return Flags.throws(); }
  bool hasParameterFlags() const { return Flags.hasParameterFlags(); }
  bool isEscaping() const { return Flags.isEscaping(); }

  static constexpr StoredSize OffsetToFlags = sizeof(TargetMetadata<Runtime>);

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Function;
  }

  uint32_t *getParameterFlags() {
    return reinterpret_cast<uint32_t *>(getParameters() + getNumParameters());
  }

  const uint32_t *getParameterFlags() const {
    return reinterpret_cast<const uint32_t *>(getParameters() +
                                              getNumParameters());
  }
};
using FunctionTypeMetadata = TargetFunctionTypeMetadata<InProcess>;

/// The structure of metadata for metatypes.
template <typename Runtime>
struct TargetMetatypeMetadata : public TargetMetadata<Runtime> {
  /// The type metadata for the element.
  ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> InstanceType;

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Metatype;
  }
};
using MetatypeMetadata = TargetMetatypeMetadata<InProcess>;

/// The structure of tuple type metadata.
template <typename Runtime>
struct TargetTupleTypeMetadata : public TargetMetadata<Runtime> {
  using StoredSize = typename Runtime::StoredSize;
  TargetTupleTypeMetadata() = default;
  constexpr TargetTupleTypeMetadata(const TargetMetadata<Runtime> &base,
                                    uint32_t numElements,
                                    TargetPointer<Runtime, const char> labels)
    : TargetMetadata<Runtime>(base),
      NumElements(numElements),
      Labels(labels) {}

  /// The number of elements.
  StoredSize NumElements;

  /// The labels string;  see swift_getTupleTypeMetadata.
  TargetPointer<Runtime, const char> Labels;

  struct Element {
    /// The type of the element.
    ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> Type;

    /// The offset of the tuple element within the tuple.
#if __APPLE__
    StoredSize Offset;
#else
    uint32_t Offset;
#endif

    OpaqueValue *findIn(OpaqueValue *tuple) const {
      return (OpaqueValue*) (((char*) tuple) + Offset);
    }

    const TypeLayout *getTypeLayout() const {
      return Type->getTypeLayout();
    }
  };

  static_assert(sizeof(StoredSize) == 2,
                "element size should be 2");

  static_assert(sizeof(Element) == 6,
                "element size should be 6");

  // static_assert(sizeof(Element) == sizeof(StoredSize) * 2,
  //               "element size should be two words");

  Element *getElements() {
    return reinterpret_cast<Element*>(this + 1);
  }

  const Element *getElements() const {
    return reinterpret_cast<const Element*>(this + 1);
  }

  const Element &getElement(unsigned i) const {
    return getElements()[i];
  }

  Element &getElement(unsigned i) {
    return getElements()[i];
  }

  static constexpr StoredSize getOffsetToNumElements();
  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Tuple;
  }
};
using TupleTypeMetadata = TargetTupleTypeMetadata<InProcess>;
  
template <typename Runtime>
constexpr inline auto
TargetTupleTypeMetadata<Runtime>::getOffsetToNumElements() -> StoredSize {
  return offsetof(TargetTupleTypeMetadata<Runtime>, NumElements);
}

template <typename Runtime> struct TargetProtocolDescriptor;

/// A reference to a protocol within the runtime, which may be either
/// a Swift protocol or (when Objective-C interoperability is enabled) an
/// Objective-C protocol.
///
/// This type always contains a single target pointer, whose lowest bit is
/// used to distinguish between a Swift protocol referent and an Objective-C
/// protocol referent.
template <typename Runtime>
class TargetProtocolDescriptorRef {
  using StoredPointer = typename Runtime::StoredPointer;
  using ProtocolDescriptorPointer =
    ConstTargetMetadataPointer<Runtime, TargetProtocolDescriptor>;

  enum : StoredPointer {
    // The bit used to indicate whether this is an Objective-C protocol.
    IsObjCBit = 0x1U,
  };

  /// A direct pointer to a protocol descriptor for either an Objective-C
  /// protocol (if the low bit is set) or a Swift protocol (if the low bit
  /// is clear).
  StoredPointer storage;

public:
  constexpr TargetProtocolDescriptorRef(StoredPointer storage)
    : storage(storage) { }

  constexpr TargetProtocolDescriptorRef() : storage() { }

  TargetProtocolDescriptorRef(
                        ProtocolDescriptorPointer protocol,
                        ProtocolDispatchStrategy dispatchStrategy) {
#if SWIFT_OBJC_INTEROP
    storage = reinterpret_cast<StoredPointer>(protocol)
      | (dispatchStrategy == ProtocolDispatchStrategy::ObjC ? IsObjCBit : 0);
#else
    assert(dispatchStrategy == ProtocolDispatchStrategy::Swift);
    storage = reinterpret_cast<StoredPointer>(protocol);
#endif
  }

  const static TargetProtocolDescriptorRef forSwift(
                                          ProtocolDescriptorPointer protocol) {
    return TargetProtocolDescriptorRef{
        reinterpret_cast<StoredPointer>(protocol)};
  }

#if SWIFT_OBJC_INTEROP
  constexpr static TargetProtocolDescriptorRef forObjC(Protocol *objcProtocol) {
    return TargetProtocolDescriptorRef{
        reinterpret_cast<StoredPointer>(objcProtocol) | IsObjCBit};
  }
#endif

  explicit constexpr operator bool() const {
    return storage != 0;
  }

  /// The name of the protocol.
  TargetPointer<Runtime, const char> getName() const {
#if SWIFT_OBJC_INTEROP
    if (isObjC()) {
      return reinterpret_cast<TargetObjCProtocolPrefix<Runtime> *>(
          getObjCProtocol())->Name;
    }
#endif

    return getSwiftProtocol()->Name;
  }

  /// Determine what kind of protocol this is, Swift or Objective-C.
  ProtocolDispatchStrategy getDispatchStrategy() const {
#if SWIFT_OBJC_INTEROP
    if (isObjC()) {
      return ProtocolDispatchStrategy::ObjC;
    }
#endif

    return ProtocolDispatchStrategy::Swift;
  }

  /// Determine whether this protocol has a 'class' constraint.
  ProtocolClassConstraint getClassConstraint() const {
#if SWIFT_OBJC_INTEROP
    if (isObjC()) {
      return ProtocolClassConstraint::Class;
    }
#endif

    return getSwiftProtocol()->getProtocolContextDescriptorFlags()
        .getClassConstraint();
  }

  /// Determine whether this protocol needs a witness table.
  bool needsWitnessTable() const {
#if SWIFT_OBJC_INTEROP
    if (isObjC()) {
      return false;
    }
#endif

    return true;
  }

  SpecialProtocol getSpecialProtocol() const {
#if SWIFT_OBJC_INTEROP
    if (isObjC()) {
      return SpecialProtocol::None;
    }
#endif

    return getSwiftProtocol()->getProtocolContextDescriptorFlags()
        .getSpecialProtocol();
  }

  /// Retrieve the Swift protocol descriptor.
  ProtocolDescriptorPointer getSwiftProtocol() const {
#if SWIFT_OBJC_INTEROP
    assert(!isObjC());
#endif

    // NOTE: we explicitly use a C-style cast here because cl objects to the
    // reinterpret_cast from a uintptr_t type to an unsigned type which the
    // Pointer type may be depending on the instantiation.  Using the C-style
    // cast gives us a single path irrespective of the template type parameters.
    return (ProtocolDescriptorPointer)(storage & ~IsObjCBit);
  }

  /// Retrieve the raw stored pointer and discriminator bit.
  constexpr StoredPointer getRawData() const {
    return storage;
  }

#if SWIFT_OBJC_INTEROP
  /// Whether this references an Objective-C protocol.
  bool isObjC() const {
    return (storage & IsObjCBit) != 0;
  }

  /// Retrieve the Objective-C protocol.
  TargetPointer<Runtime, Protocol> getObjCProtocol() const {
    assert(isObjC());
    return reinterpret_cast<TargetPointer<Runtime, Protocol> >(
                                                         storage & ~IsObjCBit);
  }
#endif
};

using ProtocolDescriptorRef = TargetProtocolDescriptorRef<InProcess>;

/// A protocol requirement descriptor. This describes a single protocol
/// requirement in a protocol descriptor. The index of the requirement in
/// the descriptor determines the offset of the witness in a witness table
/// for this protocol.
template <typename Runtime>
struct TargetProtocolRequirement {
  ProtocolRequirementFlags Flags;
  // TODO: name, type

  /// The optional default implementation of the protocol.
  RelativeDirectPointer<void, /*nullable*/ true> DefaultImplementation;
};

using ProtocolRequirement = TargetProtocolRequirement<InProcess>;

template<typename Runtime> struct TargetProtocolDescriptor;
using ProtocolDescriptor = TargetProtocolDescriptor<InProcess>;

/// A witness table for a protocol.
///
/// With the exception of the initial protocol conformance descriptor,
/// the layout of a witness table is dependent on the protocol being
/// represented.
template <typename Runtime>
class TargetWitnessTable {
  /// The protocol conformance descriptor from which this witness table
  /// was generated.
  ConstTargetMetadataPointer<Runtime, TargetProtocolConformanceDescriptor>
    Description;

public:
  const TargetProtocolConformanceDescriptor<Runtime> *getDescription() const {
    return Description;
  }
};

using WitnessTable = TargetWitnessTable<InProcess>;

template <typename Runtime>
using TargetWitnessTablePointer =
  ConstTargetMetadataPointer<Runtime, TargetWitnessTable>;

using WitnessTablePointer = TargetWitnessTablePointer<InProcess>;

using AssociatedWitnessTableAccessFunction =
  SWIFT_CC(swift) WitnessTable *(const Metadata *associatedType,
                                 const Metadata *self,
                                 const WitnessTable *selfConformance);

/// The possible physical representations of existential types.
enum class ExistentialTypeRepresentation {
  /// The type uses an opaque existential representation.
  Opaque,
  /// The type uses a class existential representation.
  Class,
  /// The type uses the Error boxed existential representation.
  Error,
};

/// The structure of existential type metadata.
template <typename Runtime>
struct TargetExistentialTypeMetadata
  : TargetMetadata<Runtime>,
    swift::ABI::TrailingObjects<
      TargetExistentialTypeMetadata<Runtime>,
      ConstTargetMetadataPointer<Runtime, TargetMetadata>,
      TargetProtocolDescriptorRef<Runtime>> {

private:
  using ProtocolDescriptorRef = TargetProtocolDescriptorRef<Runtime>;
  using MetadataPointer =
      ConstTargetMetadataPointer<Runtime, swift::TargetMetadata>;
  using TrailingObjects =
          swift::ABI::TrailingObjects<
          TargetExistentialTypeMetadata<Runtime>,
          MetadataPointer,
          ProtocolDescriptorRef>;
  friend TrailingObjects;

  template<typename T>
  using OverloadToken = typename TrailingObjects::template OverloadToken<T>;

  size_t numTrailingObjects(OverloadToken<ProtocolDescriptorRef>) const {
    return NumProtocols;
  }

  size_t numTrailingObjects(OverloadToken<MetadataPointer>) const {
    return Flags.hasSuperclassConstraint() ? 1 : 0;
  }

public:
  using StoredPointer = typename Runtime::StoredPointer;
  /// The number of witness tables and class-constrained-ness of the type.
  ExistentialTypeFlags Flags;

  /// The number of protocols.
  uint32_t NumProtocols;

  constexpr TargetExistentialTypeMetadata()
    : TargetMetadata<Runtime>(MetadataKind::Existential),
      Flags(ExistentialTypeFlags()), NumProtocols(0) {}
  
  explicit constexpr TargetExistentialTypeMetadata(ExistentialTypeFlags Flags)
    : TargetMetadata<Runtime>(MetadataKind::Existential),
      Flags(Flags), NumProtocols(0) {}

  /// Get the representation form this existential type uses.
  ExistentialTypeRepresentation getRepresentation() const;

  /// True if it's valid to take ownership of the value in the existential
  /// container if we own the container.
  bool mayTakeValue(const OpaqueValue *container) const;
  
  /// Clean up an existential container whose value is uninitialized.
  void deinitExistentialContainer(OpaqueValue *container) const;
  
  /// Project the value pointer from an existential container of the type
  /// described by this metadata.
  const OpaqueValue *projectValue(const OpaqueValue *container) const;
  
  OpaqueValue *projectValue(OpaqueValue *container) const {
    return const_cast<OpaqueValue *>(projectValue((const OpaqueValue*)container));
  }

  /// Get the dynamic type from an existential container of the type described
  /// by this metadata.
  const TargetMetadata<Runtime> *
  getDynamicType(const OpaqueValue *container) const;
  
  /// Get a witness table from an existential container of the type described
  /// by this metadata.
  const TargetWitnessTable<Runtime> * getWitnessTable(
                                                  const OpaqueValue *container,
                                                  unsigned i) const;

  /// Return true iff all the protocol constraints are @objc.
  bool isObjC() const {
    return isClassBounded() && Flags.getNumWitnessTables() == 0;
  }

  bool isClassBounded() const {
    return Flags.getClassConstraint() == ProtocolClassConstraint::Class;
  }

  // not implemented because I can't be bothered to import ArrayRef from llvm
  // /// Retrieve the set of protocols required by the existential.
  // ArrayRef<ProtocolDescriptorRef> getProtocols() const {
  //   return { this->template getTrailingObjects<ProtocolDescriptorRef>(),
  //            NumProtocols };
  // }

  MetadataPointer getSuperclassConstraint() const {
    if (!Flags.hasSuperclassConstraint())
      return MetadataPointer();

    return this->template getTrailingObjects<MetadataPointer>()[0];
  }

  // not implemented because I can't be bothered to import ArrayRef from llvm
  // /// Retrieve the set of protocols required by the existential.
  // MutableArrayRef<ProtocolDescriptorRef> getMutableProtocols() {
  //   return { this->template getTrailingObjects<ProtocolDescriptorRef>(),
  //            NumProtocols };
  // }

  /// Set the superclass.
  void setSuperclassConstraint(MetadataPointer superclass) {
    assert(Flags.hasSuperclassConstraint());
    assert(superclass != nullptr);
    this->template getTrailingObjects<MetadataPointer>()[0] = superclass;
  }

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Existential;
  }
};
using ExistentialTypeMetadata
  = TargetExistentialTypeMetadata<InProcess>;

/// The basic layout of an existential metatype type.
template <typename Runtime>
struct TargetExistentialMetatypeContainer {
  ConstTargetMetadataPointer<Runtime, TargetMetadata> Value;

  TargetWitnessTablePointer<Runtime> *getWitnessTables() {
    return reinterpret_cast<TargetWitnessTablePointer<Runtime> *>(this + 1);
  }
  TargetWitnessTablePointer<Runtime> const *getWitnessTables() const {
    return reinterpret_cast<TargetWitnessTablePointer<Runtime> const *>(this+1);
  }

  void copyTypeInto(TargetExistentialMetatypeContainer *dest,
                    unsigned numTables) const {
    for (unsigned i = 0; i != numTables; ++i)
      dest->getWitnessTables()[i] = getWitnessTables()[i];
  }
};
using ExistentialMetatypeContainer
  = TargetExistentialMetatypeContainer<InProcess>;

/// The structure of metadata for existential metatypes.
template <typename Runtime>
struct TargetExistentialMetatypeMetadata
  : public TargetMetadata<Runtime> {
  /// The type metadata for the element.
  ConstTargetMetadataPointer<Runtime, swift::TargetMetadata> InstanceType;

  /// The number of witness tables and class-constrained-ness of the
  /// underlying type.
  ExistentialTypeFlags Flags;

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::ExistentialMetatype;
  }

  /// Return true iff all the protocol constraints are @objc.
  bool isObjC() const {
    return isClassBounded() && Flags.getNumWitnessTables() == 0;
  }

  bool isClassBounded() const {
    return Flags.getClassConstraint() == ProtocolClassConstraint::Class;
  }
};
using ExistentialMetatypeMetadata
  = TargetExistentialMetatypeMetadata<InProcess>;

/// The control structure of a generic or resilient protocol
/// conformance witness.
///
/// Resilient conformances must use a pattern where new requirements
/// with default implementations can be added and the order of existing
/// requirements can be changed.
///
/// This is accomplished by emitting an order-independent series of
/// relative pointer pairs, consisting of a protocol requirement together
/// with a witness. The requirement is identified by an indirectable relative
/// pointer to the protocol requirement descriptor.
template <typename Runtime>
struct TargetResilientWitness {
  TargetRelativeProtocolRequirementPointer<Runtime> Requirement;
  RelativeDirectPointer<void> Witness;
};
using ResilientWitness = TargetResilientWitness<InProcess>;

template <typename Runtime>
struct TargetResilientWitnessTable final
  : public swift::ABI::TrailingObjects<
             TargetResilientWitnessTable<Runtime>,
             TargetResilientWitness<Runtime>> {
  uint32_t NumWitnesses;

  using TrailingObjects = swift::ABI::TrailingObjects<
                             TargetResilientWitnessTable<Runtime>,
                             TargetResilientWitness<Runtime>>;
  friend TrailingObjects;

  template<typename T>
  using OverloadToken = typename TrailingObjects::template OverloadToken<T>;

  size_t numTrailingObjects(
                        OverloadToken<TargetResilientWitness<Runtime>>) const {
    return NumWitnesses;
  }

  // not implemented because I can't be bothered to import ArrayRef from llvm
  // llvm::ArrayRef<TargetResilientWitness<Runtime>>
  // getWitnesses() const {
  //   return {this->template getTrailingObjects<TargetResilientWitness<Runtime>>(),
  //           NumWitnesses};
  // }

  // const TargetResilientWitness<Runtime> &
  // getWitness(unsigned i) const {
  //   return getWitnesses()[i];
  // }
};
using ResilientWitnessTable = TargetResilientWitnessTable<InProcess>;

/// The control structure of a generic or resilient protocol
/// conformance, which is embedded in the protocol conformance descriptor.
///
/// Witness tables need to be instantiated at runtime in these cases:
/// - For a generic conforming type, associated type requirements might be
///   dependent on the conforming type.
/// - For a type conforming to a resilient protocol, the runtime size of
///   the witness table is not known because default requirements can be
///   added resiliently.
///
/// One per conformance.
template <typename Runtime>
struct TargetGenericWitnessTable {
  /// The size of the witness table in words.  This amount is copied from
  /// the witness table template into the instantiated witness table.
  uint16_t WitnessTableSizeInWords;

  /// The amount of private storage to allocate before the address point,
  /// in words. This memory is zeroed out in the instantiated witness table
  /// template.
  ///
  /// The low bit is used to indicate whether this witness table is known
  /// to require instantiation.
  uint16_t WitnessTablePrivateSizeInWordsAndRequiresInstantiation;

  /// The instantiation function, which is called after the template is copied.
  RelativeDirectPointer<void(TargetWitnessTable<Runtime> *instantiatedTable,
                             const TargetMetadata<Runtime> *type,
                             const void * const *instantiationArgs),
                        /*nullable*/ true> Instantiator;

  using PrivateDataType = void *[swift::NumGenericMetadataPrivateDataWords];

  /// Private data for the instantiator.  Out-of-line so that the rest
  /// of this structure can be constant.
  RelativeDirectPointer<PrivateDataType> PrivateData;

  uint16_t getWitnessTablePrivateSizeInWords() const {
    return WitnessTablePrivateSizeInWordsAndRequiresInstantiation >> 1;
  }

  /// This bit doesn't really mean anything. Currently, the compiler always
  /// sets it when emitting a generic witness table.
  uint16_t requiresInstantiation() const {
    return WitnessTablePrivateSizeInWordsAndRequiresInstantiation & 0x01;
  }
};
using GenericWitnessTable = TargetGenericWitnessTable<InProcess>;

// /// The structure of a type metadata record.
// ///
// /// This contains enough static information to recover type metadata from a
// /// name.
// template <typename Runtime>
// struct TargetTypeMetadataRecord {
// private:
//   union {
//     /// A direct reference to a nominal type descriptor.
//     RelativeDirectPointerIntPair<TargetContextDescriptor<Runtime>,
//                                  TypeReferenceKind>
//       DirectNominalTypeDescriptor;

//     /// An indirect reference to a nominal type descriptor.
//     RelativeDirectPointerIntPair<TargetSignedPointer<Runtime, TargetContextDescriptor<Runtime> * __ptrauth_swift_type_descriptor>,
//                                  TypeReferenceKind>
//       IndirectNominalTypeDescriptor;

//     // We only allow a subset of the TypeReferenceKinds here.
//     // Should we just acknowledge that this is a different enum?
//   };

// public:
//   TypeReferenceKind getTypeKind() const {
//     return DirectNominalTypeDescriptor.getInt();
//   }
  
//   const TargetContextDescriptor<Runtime> *
//   getContextDescriptor() const {
//     switch (getTypeKind()) {
//     case TypeReferenceKind::DirectTypeDescriptor:
//       return DirectNominalTypeDescriptor.getPointer();

//     case TypeReferenceKind::IndirectTypeDescriptor:
//       return *IndirectNominalTypeDescriptor.getPointer();

//     // These types (and any others we might add to TypeReferenceKind
//     // in the future) are just never used in these lists.
//     case TypeReferenceKind::DirectObjCClassName:
//     case TypeReferenceKind::IndirectObjCClass:
//       return nullptr;
//     }
    
//     return nullptr;
//   }
// };

// using TypeMetadataRecord = TargetTypeMetadataRecord<InProcess>;

// /// The structure of a protocol reference record.
// template <typename Runtime>
// struct TargetProtocolRecord {
//   /// The protocol referenced.
//   ///
//   /// The remaining low bit is reserved for future use.
//   RelativeContextPointerIntPair<Runtime, /*reserved=*/bool,
//                                 TargetProtocolDescriptor>
//     Protocol;
// };
// using ProtocolRecord = TargetProtocolRecord<InProcess>;

// template<typename Runtime> class TargetGenericRequirementDescriptor;

// /// A relative pointer to a protocol descriptor, which provides the relative-
// /// pointer equivalent to \c TargetProtocolDescriptorRef.
// template <typename Runtime>
// class RelativeTargetProtocolDescriptorPointer {
//   union {
//     /// Relative pointer to a Swift protocol descriptor.
//     /// The \c bool value will be false to indicate that the protocol
//     /// is a Swift protocol, or true to indicate that this references
//     /// an Objective-C protocol.
//     RelativeContextPointerIntPair<Runtime, bool, TargetProtocolDescriptor>
//       swiftPointer;
// #if SWIFT_OBJC_INTEROP    
//     /// Relative pointer to an ObjC protocol descriptor.
//     /// The \c bool value will be false to indicate that the protocol
//     /// is a Swift protocol, or true to indicate that this references
//     /// an Objective-C protocol.
//     RelativeIndirectablePointerIntPair<Protocol, bool> objcPointer;
// #endif
//   };

// #if SWIFT_OBJC_INTEROP
//   bool isObjC() const {
//     return objcPointer.getInt();
//   }
// #endif

// public:
//   /// Retrieve a reference to the protocol.
//   TargetProtocolDescriptorRef<Runtime> getProtocol() const {
// #if SWIFT_OBJC_INTEROP
//     if (isObjC()) {
//       return TargetProtocolDescriptorRef<Runtime>::forObjC(
//           const_cast<Protocol*>(objcPointer.getPointer()));
//     }
// #endif

//     return TargetProtocolDescriptorRef<Runtime>::forSwift(
//         reinterpret_cast<ConstTargetMetadataPointer<
//             Runtime, TargetProtocolDescriptor>>(swiftPointer.getPointer()));
//   }

//   operator TargetProtocolDescriptorRef<Runtime>() const {
//     return getProtocol();
//   }
// };

// /// A reference to a type.
// template <typename Runtime>
// struct TargetTypeReference {
//   union {
//     /// A direct reference to a TypeContextDescriptor or ProtocolDescriptor.
//     RelativeDirectPointer<TargetContextDescriptor<Runtime>>
//       DirectTypeDescriptor;

//     /// An indirect reference to a TypeContextDescriptor or ProtocolDescriptor.
//     RelativeDirectPointer<
//         TargetSignedPointer<Runtime, TargetContextDescriptor<Runtime> * __ptrauth_swift_type_descriptor>>
//       IndirectTypeDescriptor;

//     /// An indirect reference to an Objective-C class.
//     RelativeDirectPointer<
//         ConstTargetMetadataPointer<Runtime, TargetClassMetadata>>
//       IndirectObjCClass;

//     /// A direct reference to an Objective-C class name.
//     RelativeDirectPointer<const char>
//       DirectObjCClassName;
//   };

//   const TargetContextDescriptor<Runtime> *
//   getTypeDescriptor(TypeReferenceKind kind) const {
//     switch (kind) {
//     case TypeReferenceKind::DirectTypeDescriptor:
//       return DirectTypeDescriptor;

//     case TypeReferenceKind::IndirectTypeDescriptor:
//       return *IndirectTypeDescriptor;

//     case TypeReferenceKind::DirectObjCClassName:
//     case TypeReferenceKind::IndirectObjCClass:
//       return nullptr;
//     }

//     return nullptr;
//   }

// #if SWIFT_OBJC_INTEROP
//   /// If this type reference is one of the kinds that supports ObjC
//   /// references,
//   const TargetClassMetadata<Runtime> *
//   getObjCClass(TypeReferenceKind kind) const;
// #endif

//   const TargetClassMetadata<Runtime> * const *
//   getIndirectObjCClass(TypeReferenceKind kind) const {
//     assert(kind == TypeReferenceKind::IndirectObjCClass);
//     return IndirectObjCClass.get();
//   }

//   const char *getDirectObjCClassName(TypeReferenceKind kind) const {
//     assert(kind == TypeReferenceKind::DirectObjCClassName);
//     return DirectObjCClassName.get();
//   }
// };
// using TypeReference = TargetTypeReference<InProcess>;

// /// Header containing information about the resilient witnesses in a
// /// protocol conformance descriptor.
// template <typename Runtime>
// struct TargetResilientWitnessesHeader {
//   uint32_t NumWitnesses;
// };
// using ResilientWitnessesHeader = TargetResilientWitnessesHeader<InProcess>;

// /// The structure of a protocol conformance.
// ///
// /// This contains enough static information to recover the witness table for a
// /// type's conformance to a protocol.
// template <typename Runtime>
// struct TargetProtocolConformanceDescriptor final
//   : public swift::ABI::TrailingObjects<
//              TargetProtocolConformanceDescriptor<Runtime>,
//              TargetRelativeContextPointer<Runtime>,
//              TargetGenericRequirementDescriptor<Runtime>,
//              TargetResilientWitnessesHeader<Runtime>,
//              TargetResilientWitness<Runtime>,
//              TargetGenericWitnessTable<Runtime>> {

//   using TrailingObjects = swift::ABI::TrailingObjects<
//                              TargetProtocolConformanceDescriptor<Runtime>,
//                              TargetRelativeContextPointer<Runtime>,
//                              TargetGenericRequirementDescriptor<Runtime>,
//                              TargetResilientWitnessesHeader<Runtime>,
//                              TargetResilientWitness<Runtime>,
//                              TargetGenericWitnessTable<Runtime>>;
//   friend TrailingObjects;

//   template<typename T>
//   using OverloadToken = typename TrailingObjects::template OverloadToken<T>;

// public:
//   using GenericRequirementDescriptor =
//     TargetGenericRequirementDescriptor<Runtime>;

//   using ResilientWitnessesHeader = TargetResilientWitnessesHeader<Runtime>;
//   using ResilientWitness = TargetResilientWitness<Runtime>;
//   using GenericWitnessTable = TargetGenericWitnessTable<Runtime>;

// private:
//   /// The protocol being conformed to.
//   TargetRelativeContextPointer<Runtime, TargetProtocolDescriptor> Protocol;
  
//   // Some description of the type that conforms to the protocol.
//   TargetTypeReference<Runtime> TypeRef;

//   /// The witness table pattern, which may also serve as the witness table.
//   RelativeDirectPointer<const TargetWitnessTable<Runtime>> WitnessTablePattern;

//   /// Various flags, including the kind of conformance.
//   ConformanceFlags Flags;

// public:
//   ConstTargetPointer<Runtime, TargetProtocolDescriptor<Runtime>>
//   getProtocol() const {
//     return Protocol;
//   }

//   TypeReferenceKind getTypeKind() const {
//     return Flags.getTypeReferenceKind();
//   }

//   const char *getDirectObjCClassName() const {
//     return TypeRef.getDirectObjCClassName(getTypeKind());
//   }

//   const TargetClassMetadata<Runtime> * const *getIndirectObjCClass() const {
//     return TypeRef.getIndirectObjCClass(getTypeKind());
//   }
  
//   const TargetContextDescriptor<Runtime> *getTypeDescriptor() const {
//     return TypeRef.getTypeDescriptor(getTypeKind());
//   }

//   TargetContextDescriptor<Runtime> * __ptrauth_swift_type_descriptor *
//   _getTypeDescriptorLocation() const {
//     if (getTypeKind() != TypeReferenceKind::IndirectTypeDescriptor)
//       return nullptr;
//     return TypeRef.IndirectTypeDescriptor.get();
//   }

//   /// Retrieve the context of a retroactive conformance.
//   const TargetContextDescriptor<Runtime> *getRetroactiveContext() const {
//     if (!Flags.isRetroactive()) return nullptr;

//     return this->template getTrailingObjects<
//         TargetRelativeContextPointer<Runtime>>();
//   }

//   /// Whether this conformance is non-unique because it has been synthesized
//   /// for a foreign type.
//   bool isSynthesizedNonUnique() const {
//     return Flags.isSynthesizedNonUnique();
//   }

//   /// Whether this conformance has any conditional requirements that need to
//   /// be evaluated.
//   bool hasConditionalRequirements() const {
//     return Flags.getNumConditionalRequirements() > 0;
//   }

//   // /// Retrieve the conditional requirements that must also be
//   // /// satisfied
//   // llvm::ArrayRef<GenericRequirementDescriptor>
//   // getConditionalRequirements() const {
//   //   return {this->template getTrailingObjects<GenericRequirementDescriptor>(),
//   //           Flags.getNumConditionalRequirements()};
//   // }

//   /// Get the directly-referenced witness table pattern, which may also
//   /// serve as the witness table.
//   const swift::TargetWitnessTable<Runtime> *getWitnessTablePattern() const {
//     return WitnessTablePattern;
//   }

//   /// Get the canonical metadata for the type referenced by this record, or
//   /// return null if the record references a generic or universal type.
//   const TargetMetadata<Runtime> *getCanonicalTypeMetadata() const;
  
//   /// Get the witness table for the specified type, realizing it if
//   /// necessary, or return null if the conformance does not apply to the
//   /// type.
//   const swift::TargetWitnessTable<Runtime> *
//   getWitnessTable(const TargetMetadata<Runtime> *type) const;

//   // /// Retrieve the resilient witnesses.
//   // ArrayRef<ResilientWitness> getResilientWitnesses() const{
//   //   if (!Flags.hasResilientWitnesses())
//   //     return { };

//   //   return ArrayRef<ResilientWitness>(
//   //            this->template getTrailingObjects<ResilientWitness>(),
//   //            numTrailingObjects(OverloadToken<ResilientWitness>()));
//   // }

//   ConstTargetPointer<Runtime, GenericWitnessTable>
//   getGenericWitnessTable() const {
//     if (!Flags.hasGenericWitnessTable())
//       return nullptr;

//     return this->template getTrailingObjects<GenericWitnessTable>();
//   }

// #if !defined(NDEBUG) && SWIFT_OBJC_INTEROP
//   void dump() const;
// #endif

// #ifndef NDEBUG
//   /// Verify that the protocol descriptor obeys all invariants.
//   ///
//   /// We currently check that the descriptor:
//   ///
//   /// 1. Has a valid TypeReferenceKind.
//   /// 2. Has a valid conformance kind.
//   void verify() const;
// #endif

// private:
//   size_t numTrailingObjects(
//                         OverloadToken<TargetRelativeContextPointer<Runtime>>) const {
//     return Flags.isRetroactive() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<GenericRequirementDescriptor>) const {
//     return Flags.getNumConditionalRequirements();
//   }

//   size_t numTrailingObjects(OverloadToken<ResilientWitnessesHeader>) const {
//     return Flags.hasResilientWitnesses() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<ResilientWitness>) const {
//     return Flags.hasResilientWitnesses()
//       ? this->template getTrailingObjects<ResilientWitnessesHeader>()
//           ->NumWitnesses
//       : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<GenericWitnessTable>) const {
//     return Flags.hasGenericWitnessTable() ? 1 : 0;
//   }
// };
// using ProtocolConformanceDescriptor
//   = TargetProtocolConformanceDescriptor<InProcess>;

// template<typename Runtime>
// using TargetProtocolConformanceRecord =
//   RelativeDirectPointer<TargetProtocolConformanceDescriptor<Runtime>,
//                         /*Nullable=*/false>;

// using ProtocolConformanceRecord = TargetProtocolConformanceRecord<InProcess>;

// template<typename Runtime>
// struct TargetGenericContext;

// template<typename Runtime>
// struct TargetModuleContextDescriptor;

// /// Base class for all context descriptors.
// template<typename Runtime>
// struct TargetContextDescriptor {
//   /// Flags describing the context, including its kind and format version.
//   ContextDescriptorFlags Flags;
  
//   /// The parent context, or null if this is a top-level context.
//   TargetRelativeContextPointer<Runtime> Parent;

//   bool isGeneric() const { return Flags.isGeneric(); }
//   bool isUnique() const { return Flags.isUnique(); }
//   ContextDescriptorKind getKind() const { return Flags.getKind(); }

//   /// Get the generic context information for this context, or null if the
//   /// context is not generic.
//   const TargetGenericContext<Runtime> *getGenericContext() const;

//   /// Get the module context for this context.
//   const TargetModuleContextDescriptor<Runtime> *getModuleContext() const;

//   /// Is this context part of a C-imported module?
//   bool isCImportedContext() const;

//   unsigned getNumGenericParams() const {
//     auto *genericContext = getGenericContext();
//     return genericContext
//               ? genericContext->getGenericContextHeader().NumParams
//               : 0;
//   }

// #ifndef NDEBUG
//   LLVM_ATTRIBUTE_DEPRECATED(void dump() const,
//                             "only for use in the debugger");
// #endif

// private:
//   TargetContextDescriptor(const TargetContextDescriptor &) = delete;
//   TargetContextDescriptor(TargetContextDescriptor &&) = delete;
//   TargetContextDescriptor &operator=(const TargetContextDescriptor &) = delete;
//   TargetContextDescriptor &operator=(TargetContextDescriptor &&) = delete;
// };

// using ContextDescriptor = TargetContextDescriptor<InProcess>;

// // inline bool isCImportedModuleName(StringRef name) {
// //   // This does not include MANGLING_MODULE_CLANG_IMPORTER because that's
// //   // used only for synthesized declarations and not actual imported
// //   // declarations.
// //   return name == MANGLING_MODULE_OBJC;
// // }

// /// Descriptor for a module context.
// template<typename Runtime>
// struct TargetModuleContextDescriptor final : TargetContextDescriptor<Runtime> {
//   /// The module name.
//   RelativeDirectPointer<const char, /*nullable*/ false> Name;

//   /// Is this module a special C-imported module?
//   bool isCImportedContext() const {
//     // return isCImportedModuleName(Name.get());
//     // llvm string ref not imported
//     return false;
//   }

//   static bool classof(const TargetContextDescriptor<Runtime> *cd) {
//     return cd->getKind() == ContextDescriptorKind::Module;
//   }
// };

// using ModuleContextDescriptor = TargetModuleContextDescriptor<InProcess>;

// template<typename Runtime>
// inline bool TargetContextDescriptor<Runtime>::isCImportedContext() const {
//   return getModuleContext()->isCImportedContext();
// }

// template<typename Runtime>
// inline const TargetModuleContextDescriptor<Runtime> *
// TargetContextDescriptor<Runtime>::getModuleContext() const {
//   // All context chains should eventually find a module.
//   for (auto cur = this; true; cur = cur->Parent.get()) {
//     if (auto module = dyn_cast<TargetModuleContextDescriptor<Runtime>>(cur))
//       return module;
//   }
// }

// template<typename Runtime>
// struct TargetGenericContextDescriptorHeader {
//   uint16_t NumParams, NumRequirements, NumKeyArguments, NumExtraArguments;
  
//   uint32_t getNumArguments() const {
//     return NumKeyArguments + NumExtraArguments;
//   }

//   bool hasArguments() const {
//     return getNumArguments() > 0;
//   }
// };
// using GenericContextDescriptorHeader =
//   TargetGenericContextDescriptorHeader<InProcess>;

// template<typename Runtime>
// class TargetGenericRequirementDescriptor {
// public:
//   GenericRequirementFlags Flags;

//   /// The type that's constrained, described as a mangled name.
//   RelativeDirectPointer<const char, /*nullable*/ false> Param;

//   union {
//     /// A mangled representation of the same-type or base class the param is
//     /// constrained to.
//     ///
//     /// Only valid if the requirement has SameType or BaseClass kind.
//     RelativeDirectPointer<const char, /*nullable*/ false> Type;
    
//     /// The protocol the param is constrained to.
//     ///
//     /// Only valid if the requirement has Protocol kind.
//     RelativeTargetProtocolDescriptorPointer<Runtime> Protocol;
    
//     /// The conformance the param is constrained to use.
//     ///
//     /// Only valid if the requirement has SameConformance kind.
//     RelativeIndirectablePointer<TargetProtocolConformanceDescriptor<Runtime>,
//                                 /*nullable*/ false> Conformance;
    
//     /// The kind of layout constraint.
//     ///
//     /// Only valid if the requirement has Layout kind.
//     GenericRequirementLayoutKind Layout;
//   };

//   constexpr GenericRequirementFlags getFlags() const {
//     return Flags;
//   }

//   constexpr GenericRequirementKind getKind() const {
//     return getFlags().getKind();
//   }

//   // /// Retrieve the generic parameter that is the subject of this requirement,
//   // /// as a mangled type name.
//   // StringRef getParam() const {
//   //   return swift::Demangle::makeSymbolicMangledNameStringRef(Param.get());
//   // }

//   /// Retrieve the protocol for a Protocol requirement.
//   TargetProtocolDescriptorRef<Runtime> getProtocol() const {
//     assert(getKind() == GenericRequirementKind::Protocol);
//     return Protocol;
//   }

//   // /// Retrieve the right-hand type for a SameType or BaseClass requirement.
//   // StringRef getMangledTypeName() const {
//   //   assert(getKind() == GenericRequirementKind::SameType ||
//   //          getKind() == GenericRequirementKind::BaseClass);
//   //   return swift::Demangle::makeSymbolicMangledNameStringRef(Type.get());
//   // }

//   /// Retrieve the protocol conformance record for a SameConformance
//   /// requirement.
//   const TargetProtocolConformanceDescriptor<Runtime> *getConformance() const {
//     assert(getKind() == GenericRequirementKind::SameConformance);
//     return Conformance;
//   }

//   /// Retrieve the layout constraint.
//   GenericRequirementLayoutKind getLayout() const {
//     assert(getKind() == GenericRequirementKind::Layout);
//     return Layout;
//   }

//   /// Determine whether this generic requirement has a known kind.
//   ///
//   /// \returns \c false for any future generic requirement kinds.
//   bool hasKnownKind() const {
//     switch (getKind()) {
//     case GenericRequirementKind::BaseClass:
//     case GenericRequirementKind::Layout:
//     case GenericRequirementKind::Protocol:
//     case GenericRequirementKind::SameConformance:
//     case GenericRequirementKind::SameType:
//       return true;
//     }

//     return false;
//   }
// };
// using GenericRequirementDescriptor =
//   TargetGenericRequirementDescriptor<InProcess>;

// template <typename Runtime>
// struct TargetTypeGenericContextDescriptorHeader {
//   /// The metadata instantiation cache.
//   TargetRelativeDirectPointer<Runtime,
//                               TargetGenericMetadataInstantiationCache<Runtime>>
//     InstantiationCache;

//   GenericMetadataInstantiationCache *getInstantiationCache() const {
//     return InstantiationCache.get();
//   }

//   /// The default instantiation pattern.
//   TargetRelativeDirectPointer<Runtime, TargetGenericMetadataPattern<Runtime>>
//     DefaultInstantiationPattern;

//   /// The base header.  Must always be the final member.
//   TargetGenericContextDescriptorHeader<Runtime> Base;
  
//   operator const TargetGenericContextDescriptorHeader<Runtime> &() const {
//     return Base;
//   }
// };
// using TypeGenericContextDescriptorHeader =
//   TargetTypeGenericContextDescriptorHeader<InProcess>;


// template <typename Runtime>
// class TargetTypeContextDescriptor
//     : public TargetContextDescriptor<Runtime> {
// public:
//   /// The name of the type.
//   TargetRelativeDirectPointer<Runtime, const char, /*nullable*/ false> Name;

//   /// A pointer to the metadata access function for this type.
//   ///
//   /// The function type here is a stand-in. You should use getAccessFunction()
//   /// to wrap the function pointer in an accessor that uses the proper calling
//   /// convention for a given number of arguments.
//   TargetRelativeDirectPointer<Runtime, MetadataResponse(...),
//                               /*Nullable*/ true> AccessFunctionPtr;
  
//   /// A pointer to the field descriptor for the type, if any.
//   TargetRelativeDirectPointer<Runtime, const reflection::FieldDescriptor,
//                               /*nullable*/ true> Fields;
      
//   bool isReflectable() const { return (bool)Fields; }

//   MetadataAccessFunction getAccessFunction() const {
//     return MetadataAccessFunction(AccessFunctionPtr.get());
//   }

//   TypeContextDescriptorFlags getTypeContextDescriptorFlags() const {
//     return TypeContextDescriptorFlags(this->Flags.getKindSpecificFlags());
//   }

//   /// Return the kind of metadata initialization required by this type.
//   /// Note that this is only meaningful for non-generic types.
//   TypeContextDescriptorFlags::MetadataInitializationKind
//   getMetadataInitialization() const {
//     return getTypeContextDescriptorFlags().getMetadataInitialization();
//   }

//   /// Does this type have non-trivial "singleton" metadata initialization?
//   ///
//   /// The type of the initialization-control structure differs by subclass,
//   /// so it doesn't appear here.
//   bool hasSingletonMetadataInitialization() const {
//     return getTypeContextDescriptorFlags().hasSingletonMetadataInitialization();
//   }

//   /// Does this type have "foreign" metadata initialiation?
//   bool hasForeignMetadataInitialization() const {
//     return getTypeContextDescriptorFlags().hasForeignMetadataInitialization();
//   }

//   /// Given that this type has foreign metadata initialization, return the
//   /// control structure for it.
//   const TargetForeignMetadataInitialization<Runtime> &
//   getForeignMetadataInitialization() const;

//   const TargetSingletonMetadataInitialization<Runtime> &
//   getSingletonMetadataInitialization() const;

//   const TargetTypeGenericContextDescriptorHeader<Runtime> &
//   getFullGenericContextHeader() const;

//   const TargetGenericContextDescriptorHeader<Runtime> &
//   getGenericContextHeader() const {
//     return getFullGenericContextHeader();
//   }

//   llvm::ArrayRef<GenericParamDescriptor> getGenericParams() const;

//   /// Return the offset of the start of generic arguments in the nominal
//   /// type's metadata. The returned value is measured in sizeof(StoredPointer).
//   int32_t getGenericArgumentOffset() const;

//   /// Return the start of the generic arguments array in the nominal
//   /// type's metadata. The returned value is measured in sizeof(StoredPointer).
//   const TargetMetadata<Runtime> * const *getGenericArguments(
//                                const TargetMetadata<Runtime> *metadata) const {
//     auto offset = getGenericArgumentOffset();
//     auto words =
//       reinterpret_cast<const TargetMetadata<Runtime> * const *>(metadata);
//     return words + offset;
//   }

//   static bool classof(const TargetContextDescriptor<Runtime> *cd) {
//     return cd->getKind() >= ContextDescriptorKind::Type_First
//         && cd->getKind() <= ContextDescriptorKind::Type_Last;
//   }
// };

// using TypeContextDescriptor = TargetTypeContextDescriptor<InProcess>;

// /// Storage for class metadata bounds.  This is the variable returned
// /// by getAddrOfClassMetadataBounds in the compiler.
// ///
// /// This storage is initialized before the allocation of any metadata
// /// for the class to which it belongs.  In classes without resilient
// /// superclasses, it is initialized statically with values derived
// /// during compilation.  In classes with resilient superclasses, it
// /// is initialized dynamically, generally during the allocation of
// /// the first metadata of this class's type.  If metadata for this
// /// class is available to you to use, you must have somehow synchronized
// /// with the thread which allocated the metadata, and therefore the
// /// complete initialization of this variable is also ordered before
// /// your access.  That is why you can safely access this variable,
// /// and moreover access it without further atomic accesses.  However,
// /// since this variable may be accessed in a way that is not dependency-
// /// ordered on the metadata pointer, it is important that you do a full
// /// synchronization and not just a dependency-ordered (consume)
// /// synchronization when sharing class metadata pointers between
// /// threads.  (There are other reasons why this is true; for example,
// /// field offset variables are also accessed without dependency-ordering.)
// ///
// /// If you are accessing this storage without such a guarantee, you
// /// should be aware that it may be lazily initialized, and moreover
// /// it may be getting lazily initialized from another thread.  To ensure
// /// correctness, the fields must be read in the correct order: the
// /// immediate-members offset is initialized last with a store-release,
// /// so it must be read first with a load-acquire, and if the result
// /// is non-zero then the rest of the variable is known to be valid.
// /// (No locking is required because racing initializations should always
// /// assign the same values to the storage.)
// template <typename Runtime>
// struct TargetStoredClassMetadataBounds {
//   using StoredPointerDifference =
//     typename Runtime::StoredPointerDifference;

//   /// The offset to the immediate members.  This value is in bytes so that
//   /// clients don't have to sign-extend it.


//   /// It is not necessary to use atomic-ordered loads when accessing this
//   /// variable just to read the immediate-members offset when drilling to
//   /// the immediate members of an already-allocated metadata object.
//   /// The proper initialization of this variable is always ordered before
//   /// any allocation of metadata for this class.
//   std::atomic<StoredPointerDifference> ImmediateMembersOffset;

//   /// The positive and negative bounds of the class metadata.
//   TargetMetadataBounds<Runtime> Bounds;

//   /// Attempt to read the cached immediate-members offset.
//   ///
//   /// \return true if the read was successful, or false if the cache hasn't
//   ///   been filled yet
//   bool tryGetImmediateMembersOffset(StoredPointerDifference &output) {
//     output = ImmediateMembersOffset.load(std::memory_order_relaxed);
//     return output != 0;
//   }

//   /// Attempt to read the full cached bounds.
//   ///
//   /// \return true if the read was successful, or false if the cache hasn't
//   ///   been filled yet
//   bool tryGet(TargetClassMetadataBounds<Runtime> &output) {
//     auto offset = ImmediateMembersOffset.load(std::memory_order_acquire);
//     if (offset == 0) return false;

//     output.ImmediateMembersOffset = offset;
//     output.NegativeSizeInWords = Bounds.NegativeSizeInWords;
//     output.PositiveSizeInWords = Bounds.PositiveSizeInWords;
//     return true;
//   }

//   void initialize(TargetClassMetadataBounds<Runtime> value) {
//     assert(value.ImmediateMembersOffset != 0 &&
//            "attempting to initialize metadata bounds cache to a zero state!");

//     Bounds.NegativeSizeInWords = value.NegativeSizeInWords;
//     Bounds.PositiveSizeInWords = value.PositiveSizeInWords;
//     ImmediateMembersOffset.store(value.ImmediateMembersOffset,
//                                  std::memory_order_release);
//   }
// };
// using StoredClassMetadataBounds =
//   TargetStoredClassMetadataBounds<InProcess>;

// template <typename Runtime>
// struct TargetResilientSuperclass {
//   /// The superclass of this class.  This pointer can be interpreted
//   /// using the superclass reference kind stored in the type context
//   /// descriptor flags.  It is null if the class has no formal superclass.
//   ///
//   /// Note that SwiftObject, the implicit superclass of all Swift root
//   /// classes when building with ObjC compatibility, does not appear here.
//   TargetRelativeDirectPointer<Runtime, const void, /*nullable*/true> Superclass;
// };

// /// A structure that stores a reference to an Objective-C class stub.
// ///
// /// This is not the class stub itself; it is part of a class context
// /// descriptor.
// template <typename Runtime>
// struct TargetObjCResilientClassStubInfo {
//   /// A relative pointer to an Objective-C resilient class stub.
//   ///
//   /// We do not declare a struct type for class stubs since the Swift runtime
//   /// does not need to interpret them. The class stub struct is part of
//   /// the Objective-C ABI, and is laid out as follows:
//   /// - isa pointer, always 1
//   /// - an update callback, of type 'Class (*)(Class *, objc_class_stub *)'
//   ///
//   /// Class stubs are used for two purposes:
//   ///
//   /// - Objective-C can reference class stubs when calling static methods.
//   /// - Objective-C and Swift can reference class stubs when emitting
//   ///   categories (in Swift, extensions with @objc members).
//   TargetRelativeDirectPointer<Runtime, const void> Stub;
// };

// template <typename Runtime>
// class TargetClassDescriptor final
//     : public TargetTypeContextDescriptor<Runtime>,
//       public TrailingGenericContextObjects<TargetClassDescriptor<Runtime>,
//                               TargetTypeGenericContextDescriptorHeader,
//                               /*additional trailing objects:*/
//                               TargetResilientSuperclass<Runtime>,
//                               TargetForeignMetadataInitialization<Runtime>,
//                               TargetSingletonMetadataInitialization<Runtime>,
//                               TargetVTableDescriptorHeader<Runtime>,
//                               TargetMethodDescriptor<Runtime>,
//                               TargetOverrideTableHeader<Runtime>,
//                               TargetMethodOverrideDescriptor<Runtime>,
//                               TargetObjCResilientClassStubInfo<Runtime>> {
// private:
//   using TrailingGenericContextObjects =
//     swift::TrailingGenericContextObjects<TargetClassDescriptor<Runtime>,
//                                          TargetTypeGenericContextDescriptorHeader,
//                                          TargetResilientSuperclass<Runtime>,
//                                          TargetForeignMetadataInitialization<Runtime>,
//                                          TargetSingletonMetadataInitialization<Runtime>,
//                                          TargetVTableDescriptorHeader<Runtime>,
//                                          TargetMethodDescriptor<Runtime>,
//                                          TargetOverrideTableHeader<Runtime>,
//                                          TargetMethodOverrideDescriptor<Runtime>,
//                                          TargetObjCResilientClassStubInfo<Runtime>>;

//   using TrailingObjects =
//     typename TrailingGenericContextObjects::TrailingObjects;
//   friend TrailingObjects;

// public:
//   using MethodDescriptor = TargetMethodDescriptor<Runtime>;
//   using VTableDescriptorHeader = TargetVTableDescriptorHeader<Runtime>;
//   using OverrideTableHeader = TargetOverrideTableHeader<Runtime>;
//   using MethodOverrideDescriptor = TargetMethodOverrideDescriptor<Runtime>;
//   using ResilientSuperclass = TargetResilientSuperclass<Runtime>;
//   using ForeignMetadataInitialization =
//     TargetForeignMetadataInitialization<Runtime>;
//   using SingletonMetadataInitialization =
//     TargetSingletonMetadataInitialization<Runtime>;
//   using ObjCResilientClassStubInfo =
//     TargetObjCResilientClassStubInfo<Runtime>;

//   using StoredPointer = typename Runtime::StoredPointer;
//   using StoredPointerDifference = typename Runtime::StoredPointerDifference;
//   using StoredSize = typename Runtime::StoredSize;

//   using TrailingGenericContextObjects::getGenericContext;
//   using TrailingGenericContextObjects::getGenericContextHeader;
//   using TrailingGenericContextObjects::getFullGenericContextHeader;
//   using TrailingGenericContextObjects::getGenericParams;
//   using TargetTypeContextDescriptor<Runtime>::getTypeContextDescriptorFlags;

//   TypeReferenceKind getResilientSuperclassReferenceKind() const {
//     return getTypeContextDescriptorFlags()
//       .class_getResilientSuperclassReferenceKind();
//   }

//   /// The type of the superclass, expressed as a mangled type name that can
//   /// refer to the generic arguments of the subclass type.
//   TargetRelativeDirectPointer<Runtime, const char> SuperclassType;

//   union {
//     /// If this descriptor does not have a resilient superclass, this is the
//     /// negative size of metadata objects of this class (in words).
//     uint32_t MetadataNegativeSizeInWords;

//     /// If this descriptor has a resilient superclass, this is a reference
//     /// to a cache holding the metadata's extents.
//     TargetRelativeDirectPointer<Runtime,
//                                 TargetStoredClassMetadataBounds<Runtime>>
//       ResilientMetadataBounds;
//   };

//   union {
//     /// If this descriptor does not have a resilient superclass, this is the
//     /// positive size of metadata objects of this class (in words).
//     uint32_t MetadataPositiveSizeInWords;

//     /// Otherwise, these flags are used to do things like indicating
//     /// the presence of an Objective-C resilient class stub.
//     ExtraClassDescriptorFlags ExtraClassFlags;
//   };

//   /// The number of additional members added by this class to the class
//   /// metadata.  This data is opaque by default to the runtime, other than
//   /// as exposed in other members; it's really just
//   /// NumImmediateMembers * sizeof(void*) bytes of data.
//   ///
//   /// Whether those bytes are added before or after the address point
//   /// depends on areImmediateMembersNegative().
//   uint32_t NumImmediateMembers; // ABI: could be uint16_t?

//   StoredSize getImmediateMembersSize() const {
//     return StoredSize(NumImmediateMembers) * sizeof(StoredPointer);
//   }

//   /// Are the immediate members of the class metadata allocated at negative
//   /// offsets instead of positive?
//   bool areImmediateMembersNegative() const {
//     return getTypeContextDescriptorFlags().class_areImmediateMembersNegative();
//   }

//   /// The number of stored properties in the class, not including its
//   /// superclasses. If there is a field offset vector, this is its length.
//   uint32_t NumFields;

// private:
//   /// The offset of the field offset vector for this class's stored
//   /// properties in its metadata, in words. 0 means there is no field offset
//   /// vector.
//   ///
//   /// If this class has a resilient superclass, this offset is relative to
//   /// the size of the resilient superclass metadata. Otherwise, it is
//   /// absolute.
//   uint32_t FieldOffsetVectorOffset;

//   template<typename T>
//   using OverloadToken =
//     typename TrailingGenericContextObjects::template OverloadToken<T>;
  
//   using TrailingGenericContextObjects::numTrailingObjects;

//   size_t numTrailingObjects(OverloadToken<ResilientSuperclass>) const {
//     return this->hasResilientSuperclass() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<ForeignMetadataInitialization>) const{
//     return this->hasForeignMetadataInitialization() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<SingletonMetadataInitialization>) const{
//     return this->hasSingletonMetadataInitialization() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<VTableDescriptorHeader>) const {
//     return hasVTable() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<MethodDescriptor>) const {
//     if (!hasVTable())
//       return 0;

//     return getVTableDescriptor()->VTableSize;
//   }

//   size_t numTrailingObjects(OverloadToken<OverrideTableHeader>) const {
//     return hasOverrideTable() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<MethodOverrideDescriptor>) const {
//     if (!hasOverrideTable())
//       return 0;

//     return getOverrideTable()->NumEntries;
//   }

//   size_t numTrailingObjects(OverloadToken<ObjCResilientClassStubInfo>) const {
//     return hasObjCResilientClassStub() ? 1 : 0;
//   }

// public:
//   const TargetRelativeDirectPointer<Runtime, const void, /*nullable*/true> &
//   getResilientSuperclass() const {
//     assert(this->hasResilientSuperclass());
//     return this->template getTrailingObjects<ResilientSuperclass>()->Superclass;
//   }

//   const ForeignMetadataInitialization &getForeignMetadataInitialization() const{
//     assert(this->hasForeignMetadataInitialization());
//     return *this->template getTrailingObjects<ForeignMetadataInitialization>();
//   }

//   const SingletonMetadataInitialization &getSingletonMetadataInitialization() const{
//     assert(this->hasSingletonMetadataInitialization());
//     return *this->template getTrailingObjects<SingletonMetadataInitialization>();
//   }

//   /// True if metadata records for this type have a field offset vector for
//   /// its stored properties.
//   bool hasFieldOffsetVector() const { return FieldOffsetVectorOffset != 0; }

//   unsigned getFieldOffsetVectorOffset() const {
//     if (hasResilientSuperclass()) {
//       auto bounds = getMetadataBounds();
//       return (bounds.ImmediateMembersOffset / sizeof(StoredPointer)
//               + FieldOffsetVectorOffset);
//     }

//     return FieldOffsetVectorOffset;
//   }

//   bool hasVTable() const {
//     return this->getTypeContextDescriptorFlags().class_hasVTable();
//   }

//   bool hasOverrideTable() const {
//     return this->getTypeContextDescriptorFlags().class_hasOverrideTable();
//   }

//   bool hasResilientSuperclass() const {
//     return this->getTypeContextDescriptorFlags().class_hasResilientSuperclass();
//   }
  
//   const VTableDescriptorHeader *getVTableDescriptor() const {
//     if (!hasVTable())
//       return nullptr;
//     return this->template getTrailingObjects<VTableDescriptorHeader>();
//   }

//   llvm::ArrayRef<MethodDescriptor> getMethodDescriptors() const {
//     if (!hasVTable())
//       return {};
//     return {this->template getTrailingObjects<MethodDescriptor>(),
//             numTrailingObjects(OverloadToken<MethodDescriptor>{})};
//   }

//   const OverrideTableHeader *getOverrideTable() const {
//     if (!hasOverrideTable())
//       return nullptr;
//     return this->template getTrailingObjects<OverrideTableHeader>();
//   }

//   llvm::ArrayRef<MethodOverrideDescriptor> getMethodOverrideDescriptors() const {
//     if (!hasOverrideTable())
//       return {};
//     return {this->template getTrailingObjects<MethodOverrideDescriptor>(),
//             numTrailingObjects(OverloadToken<MethodOverrideDescriptor>{})};
//   }

//   /// Return the bounds of this class's metadata.
//   TargetClassMetadataBounds<Runtime> getMetadataBounds() const {
//     if (!hasResilientSuperclass())
//       return getNonResilientMetadataBounds();

//     // This lookup works by ADL and will intentionally fail for
//     // non-InProcess instantiations.
//     return getResilientMetadataBounds(this);
//   }

//   /// Given that this class is known to not have a resilient superclass
//   /// return its metadata bounds.
//   TargetClassMetadataBounds<Runtime> getNonResilientMetadataBounds() const {
//     return { getNonResilientImmediateMembersOffset()
//                * StoredPointerDifference(sizeof(void*)),
//              MetadataNegativeSizeInWords,
//              MetadataPositiveSizeInWords };
//   }

//   /// Return the offset of the start of generic arguments in the nominal
//   /// type's metadata. The returned value is measured in words.
//   int32_t getGenericArgumentOffset() const {
//     if (!hasResilientSuperclass())
//       return getNonResilientGenericArgumentOffset();

//     // This lookup works by ADL and will intentionally fail for
//     // non-InProcess instantiations.
//     return getResilientImmediateMembersOffset(this);
//   }

//   /// Given that this class is known to not have a resilient superclass,
//   /// return the offset of its generic arguments in words.
//   int32_t getNonResilientGenericArgumentOffset() const {
//     return getNonResilientImmediateMembersOffset();
//   }

//   /// Given that this class is known to not have a resilient superclass,
//   /// return the offset of its immediate members in words.
//   int32_t getNonResilientImmediateMembersOffset() const {
//     assert(!hasResilientSuperclass());
//     return areImmediateMembersNegative()
//              ? -int32_t(MetadataNegativeSizeInWords)
//              : int32_t(MetadataPositiveSizeInWords - NumImmediateMembers);
//   }

//   void *getMethod(unsigned i) const {
//     assert(hasVTable()
//            && i < numTrailingObjects(OverloadToken<MethodDescriptor>{}));
//     return getMethodDescriptors()[i].Impl.get();
//   }

//   /// Whether this context descriptor references an Objective-C resilient
//   /// class stub. See the above description of TargetObjCResilientClassStubInfo
//   /// for details.
//   bool hasObjCResilientClassStub() const {
//     if (!hasResilientSuperclass())
//       return false;
//     return ExtraClassFlags.hasObjCResilientClassStub();
//   }

//   const void *getObjCResilientClassStub() const {
//     if (!hasObjCResilientClassStub())
//       return nullptr;

//     return this->template getTrailingObjects<ObjCResilientClassStubInfo>()
//       ->Stub.get();
//   }

//   static bool classof(const TargetContextDescriptor<Runtime> *cd) {
//     return cd->getKind() == ContextDescriptorKind::Class;
//   }
// };

// using ClassDescriptor = TargetClassDescriptor<InProcess>;

// template <typename Runtime>
// class TargetValueTypeDescriptor
//     : public TargetTypeContextDescriptor<Runtime> {
// public:
//   static bool classof(const TargetContextDescriptor<Runtime> *cd) {
//     return cd->getKind() == ContextDescriptorKind::Struct ||
//            cd->getKind() == ContextDescriptorKind::Enum;
//   }
// };
// using ValueTypeDescriptor = TargetValueTypeDescriptor<InProcess>;

// template <typename Runtime>
// class TargetStructDescriptor final
//     : public TargetValueTypeDescriptor<Runtime>,
//       public TrailingGenericContextObjects<TargetStructDescriptor<Runtime>,
//                             TargetTypeGenericContextDescriptorHeader,
//                             /*additional trailing objects*/
//                             TargetForeignMetadataInitialization<Runtime>,
//                             TargetSingletonMetadataInitialization<Runtime>> {
// public:
//   using ForeignMetadataInitialization =
//     TargetForeignMetadataInitialization<Runtime>;
//   using SingletonMetadataInitialization =
//     TargetSingletonMetadataInitialization<Runtime>;

// private:
//   using TrailingGenericContextObjects =
//       swift::TrailingGenericContextObjects<TargetStructDescriptor<Runtime>,
//                                            TargetTypeGenericContextDescriptorHeader,
//                                            ForeignMetadataInitialization,
//                                            SingletonMetadataInitialization>;

//   using TrailingObjects =
//     typename TrailingGenericContextObjects::TrailingObjects;
//   friend TrailingObjects;

//   template<typename T>
//   using OverloadToken = typename TrailingObjects::template OverloadToken<T>;
//   using TrailingGenericContextObjects::numTrailingObjects;

//   size_t numTrailingObjects(OverloadToken<ForeignMetadataInitialization>) const{
//     return this->hasForeignMetadataInitialization() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<SingletonMetadataInitialization>) const{
//     return this->hasSingletonMetadataInitialization() ? 1 : 0;
//   }

// public:
//   using TrailingGenericContextObjects::getGenericContext;
//   using TrailingGenericContextObjects::getGenericContextHeader;
//   using TrailingGenericContextObjects::getFullGenericContextHeader;
//   using TrailingGenericContextObjects::getGenericParams;

//   /// The number of stored properties in the struct.
//   /// If there is a field offset vector, this is its length.
//   uint32_t NumFields;
//   /// The offset of the field offset vector for this struct's stored
//   /// properties in its metadata, if any. 0 means there is no field offset
//   /// vector.
//   uint32_t FieldOffsetVectorOffset;
  
//   /// True if metadata records for this type have a field offset vector for
//   /// its stored properties.
//   bool hasFieldOffsetVector() const { return FieldOffsetVectorOffset != 0; }

//   const ForeignMetadataInitialization &getForeignMetadataInitialization() const{
//     assert(this->hasForeignMetadataInitialization());
//     return *this->template getTrailingObjects<ForeignMetadataInitialization>();
//   }

//   const SingletonMetadataInitialization &getSingletonMetadataInitialization() const{
//     assert(this->hasSingletonMetadataInitialization());
//     return *this->template getTrailingObjects<SingletonMetadataInitialization>();
//   }

//   static constexpr int32_t getGenericArgumentOffset() {
//     return TargetStructMetadata<Runtime>::getGenericArgumentOffset();
//   }

//   static bool classof(const TargetContextDescriptor<Runtime> *cd) {
//     return cd->getKind() == ContextDescriptorKind::Struct;
//   }
// };

// using StructDescriptor = TargetStructDescriptor<InProcess>;

// template <typename Runtime>
// class TargetEnumDescriptor final
//     : public TargetValueTypeDescriptor<Runtime>,
//       public TrailingGenericContextObjects<TargetEnumDescriptor<Runtime>,
//                             TargetTypeGenericContextDescriptorHeader,
//                             /*additional trailing objects*/
//                             TargetForeignMetadataInitialization<Runtime>,
//                             TargetSingletonMetadataInitialization<Runtime>> {
// public:
//   using SingletonMetadataInitialization =
//     TargetSingletonMetadataInitialization<Runtime>;
//   using ForeignMetadataInitialization =
//     TargetForeignMetadataInitialization<Runtime>;

// private:
//   using TrailingGenericContextObjects =
//     swift::TrailingGenericContextObjects<TargetEnumDescriptor<Runtime>,
//                                         TargetTypeGenericContextDescriptorHeader,
//                                         ForeignMetadataInitialization,
//                                         SingletonMetadataInitialization>;

//   using TrailingObjects =
//     typename TrailingGenericContextObjects::TrailingObjects;
//   friend TrailingObjects;

//   template<typename T>
//   using OverloadToken = typename TrailingObjects::template OverloadToken<T>;
//   using TrailingGenericContextObjects::numTrailingObjects;

//   size_t numTrailingObjects(OverloadToken<ForeignMetadataInitialization>) const{
//     return this->hasForeignMetadataInitialization() ? 1 : 0;
//   }

//   size_t numTrailingObjects(OverloadToken<SingletonMetadataInitialization>) const{
//     return this->hasSingletonMetadataInitialization() ? 1 : 0;
//   }

// public:
//   using TrailingGenericContextObjects::getGenericContext;
//   using TrailingGenericContextObjects::getGenericContextHeader;
//   using TrailingGenericContextObjects::getFullGenericContextHeader;
//   using TrailingGenericContextObjects::getGenericParams;

//   /// The number of non-empty cases in the enum are in the low 24 bits;
//   /// the offset of the payload size in the metadata record in words,
//   /// if any, is stored in the high 8 bits.
//   uint32_t NumPayloadCasesAndPayloadSizeOffset;

//   /// The number of empty cases in the enum.
//   uint32_t NumEmptyCases;

//   uint32_t getNumPayloadCases() const {
//     return NumPayloadCasesAndPayloadSizeOffset & 0x00FFFFFFU;
//   }

//   uint32_t getNumEmptyCases() const {
//     return NumEmptyCases;
//   }
//   uint32_t getNumCases() const {
//     return getNumPayloadCases() + NumEmptyCases;
//   }
//   size_t getPayloadSizeOffset() const {
//     return ((NumPayloadCasesAndPayloadSizeOffset & 0xFF000000U) >> 24);
//   }
  
//   bool hasPayloadSizeOffset() const {
//     return getPayloadSizeOffset() != 0;
//   }

//   static constexpr int32_t getGenericArgumentOffset() {
//     return TargetEnumMetadata<Runtime>::getGenericArgumentOffset();
//   }

//   const ForeignMetadataInitialization &getForeignMetadataInitialization() const{
//     assert(this->hasForeignMetadataInitialization());
//     return *this->template getTrailingObjects<ForeignMetadataInitialization>();
//   }

//   const SingletonMetadataInitialization &getSingletonMetadataInitialization() const{
//     assert(this->hasSingletonMetadataInitialization());
//     return *this->template getTrailingObjects<SingletonMetadataInitialization>();
//   }

//   static bool classof(const TargetContextDescriptor<Runtime> *cd) {
//     return cd->getKind() == ContextDescriptorKind::Enum;
//   }

// #ifndef NDEBUG
//   LLVM_ATTRIBUTE_DEPRECATED(void dump() const,
//                             "Only meant for use in the debugger");
// #endif
// };

// using EnumDescriptor = TargetEnumDescriptor<InProcess>;







/// The portion of a class metadata object that is compatible with
/// all classes, even non-Swift ones.
template <typename Runtime>
struct TargetAnyClassMetadata : public TargetHeapMetadata<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;
  using StoredSize = typename Runtime::StoredSize;

  constexpr TargetAnyClassMetadata(TargetClassMetadata<Runtime> *superclass)
    : TargetHeapMetadata<Runtime>(MetadataKind::Class),
      Superclass(superclass),
      CacheData{nullptr, nullptr},
      Data(SWIFT_CLASS_IS_SWIFT_MASK) {}

  // Note that ObjC classes does not have a metadata header.

  /// The metadata for the superclass.  This is null for the root class.
  ConstTargetMetadataPointer<Runtime, swift::TargetClassMetadata> Superclass;

  // TODO: remove the CacheData and Data fields in non-ObjC-interop builds.

  /// The cache data is used for certain dynamic lookups; it is owned
  /// by the runtime and generally needs to interoperate with
  /// Objective-C's use.
  TargetPointer<Runtime, void> CacheData[2];

  /// The data pointer is used for out-of-line metadata and is
  /// generally opaque, except that the compiler sets the low bit in
  /// order to indicate that this is a Swift metatype and therefore
  /// that the type metadata header is present.
  StoredSize Data;
  
  static constexpr StoredPointer offsetToData() {
    return offsetof(TargetAnyClassMetadata, Data);
  }

  /// Is this object a valid swift type metadata?  That is, can it be
  /// safely downcast to ClassMetadata?
  bool isTypeMetadata() const {
    return (Data & SWIFT_CLASS_IS_SWIFT_MASK);
  }
  /// A different perspective on the same bit
  bool isPureObjC() const {
    return !isTypeMetadata();
  }
};
using AnyClassMetadata =
  TargetAnyClassMetadata<InProcess>;

#warning "ClassIVarDestroyer parameter should be SWIFT_CONTEXT but swiftcall is not supported on this platform, investigate any call site issues"
using ClassIVarDestroyer =
  SWIFT_CC(swift) void(HeapObject *);  




// class metadata... this has a lot of guff in it...


/// The bounds of a class metadata object.
///
/// This type is a currency type and is not part of the ABI.
/// See TargetStoredClassMetadataBounds for the type of the class
/// metadata bounds variable.
template <typename Runtime>
struct TargetClassMetadataBounds : TargetMetadataBounds<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;
  using StoredSize = typename Runtime::StoredSize;
  using StoredPointerDifference = typename Runtime::StoredPointerDifference;

  using TargetMetadataBounds<Runtime>::NegativeSizeInWords;
  using TargetMetadataBounds<Runtime>::PositiveSizeInWords;

  /// The offset from the address point of the metadata to the immediate
  /// members.
  StoredPointerDifference ImmediateMembersOffset;

  constexpr TargetClassMetadataBounds() = default;
  constexpr TargetClassMetadataBounds(
              StoredPointerDifference immediateMembersOffset,
              uint32_t negativeSizeInWords, uint32_t positiveSizeInWords)
    : TargetMetadataBounds<Runtime>{negativeSizeInWords, positiveSizeInWords},
      ImmediateMembersOffset(immediateMembersOffset) {}

  /// Return the basic bounds of all Swift class metadata.
  /// The immediate members offset will not be meaningful.
  static constexpr TargetClassMetadataBounds<Runtime> forSwiftRootClass() {
    using Metadata = FullMetadata<TargetClassMetadata<Runtime>>;
    return forAddressPointAndSize(sizeof(typename Metadata::HeaderType),
                                  sizeof(Metadata));
  }

  /// Return the bounds of a Swift class metadata with the given address
  /// point and size (both in bytes).
  /// The immediate members offset will not be meaningful.
  static constexpr TargetClassMetadataBounds<Runtime>
  forAddressPointAndSize(StoredSize addressPoint, StoredSize totalSize) {
    return {
      // Immediate offset in bytes.
      StoredPointerDifference(totalSize - addressPoint),
      // Negative size in words.
      uint32_t(addressPoint / sizeof(StoredPointer)),
      // Positive size in words.
      uint32_t((totalSize - addressPoint) / sizeof(StoredPointer))
    };
  }

  /// Adjust these bounds for a subclass with the given immediate-members
  /// section.
  void adjustForSubclass(bool areImmediateMembersNegative,
                         uint32_t numImmediateMembers) {
    if (areImmediateMembersNegative) {
      NegativeSizeInWords += numImmediateMembers;
      ImmediateMembersOffset =
        -StoredPointerDifference(NegativeSizeInWords) * sizeof(StoredPointer);
    } else {
      ImmediateMembersOffset = PositiveSizeInWords * sizeof(StoredPointer);
      PositiveSizeInWords += numImmediateMembers;
    }
  }
};
using ClassMetadataBounds =
  TargetClassMetadataBounds<InProcess>;



/// Swift class flags.
/// These flags are valid only when isTypeMetadata().
/// When !isTypeMetadata() these flags will collide with other Swift ABIs.
enum class ClassFlags : uint32_t {
  /// Is this a Swift class from the Darwin pre-stable ABI?
  /// This bit is clear in stable ABI Swift classes.
  /// The Objective-C runtime also reads this bit.
  IsSwiftPreStableABI = 0x1,

  /// Does this class use Swift refcounting?
  UsesSwiftRefcounting = 0x2,

  /// Has this class a custom name, specified with the @objc attribute?
  HasCustomObjCName = 0x4,

  /// Whether this metadata is a specialization of a generic metadata pattern
  /// which was created during compilation.
  IsStaticSpecialization = 0x8,

  /// Whether this metadata is a specialization of a generic metadata pattern
  /// which was created during compilation and made to be canonical by
  /// modifying the metadata accessor.
  IsCanonicalStaticSpecialization = 0x10,
};
inline bool operator&(ClassFlags a, ClassFlags b) {
  return (uint32_t(a) & uint32_t(b)) != 0;
}
inline ClassFlags operator|(ClassFlags a, ClassFlags b) {
  return ClassFlags(uint32_t(a) | uint32_t(b));
}
inline ClassFlags &operator|=(ClassFlags &a, ClassFlags b) {
  return a = (a | b);
}

  /// The structure of all class metadata.  This structure is embedded
/// directly within the class's heap metadata structure and therefore
/// cannot be extended without an ABI break.
///
/// Note that the layout of this type is compatible with the layout of
/// an Objective-C class.
template <typename Runtime>
struct TargetClassMetadata : public TargetAnyClassMetadata<Runtime> {
  using StoredPointer = typename Runtime::StoredPointer;
  using StoredSize = typename Runtime::StoredSize;

  TargetClassMetadata() = default;
  constexpr TargetClassMetadata(const TargetAnyClassMetadata<Runtime> &base,
             ClassFlags flags,
             ClassIVarDestroyer *ivarDestroyer,
             StoredPointer size, StoredPointer addressPoint,
             StoredPointer alignMask,
             StoredPointer classSize, StoredPointer classAddressPoint)
    : TargetAnyClassMetadata<Runtime>(base),
      Flags(flags), InstanceAddressPoint(addressPoint),
      InstanceSize(size), InstanceAlignMask(alignMask),
      Reserved(0), ClassSize(classSize), ClassAddressPoint(classAddressPoint),
      Description(nullptr), IVarDestroyer(ivarDestroyer) {}

  // The remaining fields are valid only when isTypeMetadata().
  // The Objective-C runtime knows the offsets to some of these fields.
  // Be careful when accessing them.

  /// Swift-specific class flags.
  ClassFlags Flags;

  /// The address point of instances of this type.
  uint32_t InstanceAddressPoint;

  /// The required size of instances of this type.
  /// 'InstanceAddressPoint' bytes go before the address point;
  /// 'InstanceSize - InstanceAddressPoint' bytes go after it.
  uint32_t InstanceSize;

  /// The alignment mask of the address point of instances of this type.
  uint16_t InstanceAlignMask;

  /// Reserved for runtime use.
  uint16_t Reserved;

  /// The total size of the class object, including prefix and suffix
  /// extents.
  uint32_t ClassSize;

  /// The offset of the address point within the class object.
  uint32_t ClassAddressPoint;

  // Description is by far the most likely field for a client to try
  // to access directly, so we force access to go through accessors.
private:
  /// An out-of-line Swift-specific description of the type, or null
  /// if this is an artificial subclass.  We currently provide no
  /// supported mechanism for making a non-artificial subclass
  /// dynamically.
  TargetSignedPointer<Runtime, const TargetClassDescriptor<Runtime> *> Description;

public:
  /// A function for destroying instance variables, used to clean up after an
  /// early return from a constructor. If null, no clean up will be performed
  /// and all ivars must be trivial.
  TargetSignedPointer<Runtime, ClassIVarDestroyer *> IVarDestroyer;

  // After this come the class members, laid out as follows:
  //   - class members for the superclass (recursively)
  //   - metadata reference for the parent, if applicable
  //   - generic parameters for this class
  //   - class variables (if we choose to support these)
  //   - "tabulated" virtual methods

  using TargetAnyClassMetadata<Runtime>::isTypeMetadata;

  ConstTargetMetadataPointer<Runtime, TargetClassDescriptor>
  getDescription() const {
    assert(isTypeMetadata());
    return Description;
  }

  typename Runtime::StoredSignedPointer
  getDescriptionAsSignedPointer() const {
    assert(isTypeMetadata());
    return Description;
  }

  void setDescription(const TargetClassDescriptor<Runtime> *description) {
    Description = description;
  }

  /// Is this class an artificial subclass, such as one dynamically
  /// created for various dynamic purposes like KVO?
  bool isArtificialSubclass() const {
    assert(isTypeMetadata());
    return Description == nullptr;
  }
  void setArtificialSubclass() {
    assert(isTypeMetadata());
    Description = nullptr;
  }

  ClassFlags getFlags() const {
    assert(isTypeMetadata());
    return Flags;
  }
  void setFlags(ClassFlags flags) {
    assert(isTypeMetadata());
    Flags = flags;
  }

  StoredSize getInstanceSize() const {
    assert(isTypeMetadata());
    return InstanceSize;
  }
  void setInstanceSize(StoredSize size) {
    assert(isTypeMetadata());
    InstanceSize = size;
  }

  StoredPointer getInstanceAddressPoint() const {
    assert(isTypeMetadata());
    return InstanceAddressPoint;
  }
  void setInstanceAddressPoint(StoredSize size) {
    assert(isTypeMetadata());
    InstanceAddressPoint = size;
  }

  StoredPointer getInstanceAlignMask() const {
    assert(isTypeMetadata());
    return InstanceAlignMask;
  }
  void setInstanceAlignMask(StoredSize mask) {
    assert(isTypeMetadata());
    InstanceAlignMask = mask;
  }

  StoredPointer getClassSize() const {
    assert(isTypeMetadata());
    return ClassSize;
  }
  void setClassSize(StoredSize size) {
    assert(isTypeMetadata());
    ClassSize = size;
  }

  StoredPointer getClassAddressPoint() const {
    assert(isTypeMetadata());
    return ClassAddressPoint;
  }
  void setClassAddressPoint(StoredSize offset) {
    assert(isTypeMetadata());
    ClassAddressPoint = offset;
  }

  uint16_t getRuntimeReservedData() const {
    assert(isTypeMetadata());
    return Reserved;
  }
  void setRuntimeReservedData(uint16_t data) {
    assert(isTypeMetadata());
    Reserved = data;
  }

  /// Get a pointer to the field offset vector, if present, or null.
  const StoredPointer *getFieldOffsets() const {
    assert(isTypeMetadata());
    auto offset = getDescription()->getFieldOffsetVectorOffset();
    if (offset == 0)
      return nullptr;
    auto asWords = reinterpret_cast<const void * const*>(this);
    return reinterpret_cast<const StoredPointer *>(asWords + offset);
  }

  uint32_t getSizeInWords() const {
    assert(isTypeMetadata());
    uint32_t size = getClassSize() - getClassAddressPoint();
    assert(size % sizeof(StoredPointer) == 0);
    return size / sizeof(StoredPointer);
  }

  /// Given that this class is serving as the superclass of a Swift class,
  /// return its bounds as metadata.
  ///
  /// Note that the ImmediateMembersOffset member will not be meaningful.
  TargetClassMetadataBounds<Runtime>
  getClassBoundsAsSwiftSuperclass() const {
    using Bounds = TargetClassMetadataBounds<Runtime>;

    auto rootBounds = Bounds::forSwiftRootClass();

    // If the class is not type metadata, just use the root-class bounds.
    if (!isTypeMetadata())
      return rootBounds;

    // Otherwise, pull out the bounds from the metadata.
    auto bounds = Bounds::forAddressPointAndSize(getClassAddressPoint(),
                                                 getClassSize());

    // Round the bounds up to the required dimensions.
    if (bounds.NegativeSizeInWords < rootBounds.NegativeSizeInWords)
      bounds.NegativeSizeInWords = rootBounds.NegativeSizeInWords;
    if (bounds.PositiveSizeInWords < rootBounds.PositiveSizeInWords)
      bounds.PositiveSizeInWords = rootBounds.PositiveSizeInWords;

    return bounds;
  }

  /// Given a statically-emitted metadata template, this sets the correct
  /// "is Swift" bit for the current runtime. Depending on the deployment
  /// target a binary was compiled for, statically emitted metadata templates
  /// may have a different bit set from the one that this runtime canonically
  /// considers the "is Swift" bit.
  void setAsTypeMetadata() {
    // If the wrong "is Swift" bit is set, set the correct one.
    //
    // Note that the only time we should see the "new" bit set while
    // expecting the "old" one is when running a binary built for a
    // new OS on an old OS, which is not supported, however we do
    // have tests that exercise this scenario.
    auto otherSwiftBit = (3ULL - SWIFT_CLASS_IS_SWIFT_MASK);
    assert(otherSwiftBit == 1ULL || otherSwiftBit == 2ULL);

    if ((this->Data & 3) == otherSwiftBit) {
      this->Data ^= 3;
    }

    // Otherwise there should be nothing to do, since only the old "is
    // Swift" bit is used for backward-deployed runtimes.
    
    assert(isTypeMetadata());
  }

  bool isCanonicalStaticallySpecializedGenericMetadata() const {
    auto *description = getDescription();
    if (!description->isGeneric())
      return false;

    return this->Flags & ClassFlags::IsCanonicalStaticSpecialization;
  }

  static bool classof(const TargetMetadata<Runtime> *metadata) {
    return metadata->getKind() == MetadataKind::Class;
  }
};
using ClassMetadata = TargetClassMetadata<InProcess>;



  /// Return the class of an object which is known to be an allocated
  /// heap object.
  /// Note, in this case, the object may or may not have a non-pointer ISA.
  /// Masking, or otherwise, may be required to get a class pointer.
  static inline const ClassMetadata *_swift_getClassOfAllocated(const void *object) {
    // Load the isa field.
    uintptr_t bits = *reinterpret_cast<const uintptr_t*>(object);
    // The result is a class pointer.
    return reinterpret_cast<const ClassMetadata *>(bits);
  }

  static inline
  bool objectUsesNativeSwiftReferenceCounting(const void *object) {
    // return usesNativeSwiftReferenceCounting(_swift_getClassOfAllocated(object));
    return true; // no objective C... always true
  }



#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreturn-type-c-linkage"

// /// The buffer used by a yield-once coroutine (such as the generalized
// /// accessors `read` and `modify`).
// struct YieldOnceBuffer {
//   void *Data[NumWords_YieldOnceBuffer];
// };
// using YieldOnceContinuation =
//   SWIFT_CC(swift) void (YieldOnceBuffer *buffer, bool forUnwind);

// /// The return type of a call to a yield-once coroutine.  The function
// /// must be declared with the swiftcall calling convention.
// template <class ResultTy>
// struct YieldOnceResult {
//   YieldOnceContinuation *Continuation;
//   ResultTy YieldValue;
// };

// template <class FnTy>
// struct YieldOnceCoroutine;

// /// A template which generates the type of the ramp function of a
// /// yield-once coroutine.
// template <class ResultTy, class... ArgTys>
// struct YieldOnceCoroutine<ResultTy(ArgTys...)> {
//   using type =
//     SWIFT_CC(swift) YieldOnceResult<ResultTy> (YieldOnceBuffer *buffer,
//                                                ArgTys...);
// };

// /// A standard routine, suitable for placement in the value witness
// /// table, for copying an opaque POD object.
SWIFT_RUNTIME_EXPORT
OpaqueValue *swift_copyPOD(OpaqueValue *dest,
                           OpaqueValue *src,
                           const Metadata *self);
 
/// A value-witness table with enum entry points.
/// These entry points are available only if the HasEnumWitnesses flag bit is
/// set in the 'flags' field.
struct EnumValueWitnessTable : ValueWitnessTable {
#define WANT_ONLY_ENUM_VALUE_WITNESSES
#define VALUE_WITNESS(LOWER_ID, UPPER_ID) \
  ValueWitnessTypes::LOWER_ID LOWER_ID;
#define FUNCTION_VALUE_WITNESS(LOWER_ID, UPPER_ID, RET, PARAMS) \
  ValueWitnessTypes::LOWER_ID LOWER_ID;

#include "ValueWitness.def"

  constexpr EnumValueWitnessTable()
    : ValueWitnessTable{},
      getEnumTag(nullptr),
      destructiveProjectEnumData(nullptr),
      destructiveInjectEnumTag(nullptr) {}
  constexpr EnumValueWitnessTable(
          const ValueWitnessTable &base,
          ValueWitnessTypes::getEnumTagUnsigned getEnumTag,
          ValueWitnessTypes::destructiveProjectEnumDataUnsigned
            destructiveProjectEnumData,
          ValueWitnessTypes::destructiveInjectEnumTagUnsigned
            destructiveInjectEnumTag)
    : ValueWitnessTable(base),
      getEnumTag(getEnumTag),
      destructiveProjectEnumData(destructiveProjectEnumData),
      destructiveInjectEnumTag(destructiveInjectEnumTag) {}

  static bool classof(const ValueWitnessTable *table) {
    return table->flags.hasEnumWitnesses();
  }
};

/// A type layout record. This is the subset of the value witness table that is
/// necessary to perform dependent layout of generic value types. It excludes
/// the value witness functions and includes only the size, alignment,
/// extra inhabitants, and miscellaneous flags about the type.
struct TypeLayout {
  ValueWitnessTypes::size size;
  ValueWitnessTypes::stride stride;
  ValueWitnessTypes::flags flags;
  ValueWitnessTypes::extraInhabitantCount extraInhabitantCount;

private:
  void _static_assert_layout();
public:
  TypeLayout() = default;
  constexpr TypeLayout(ValueWitnessTypes::size size,
                       ValueWitnessTypes::stride stride,
                       ValueWitnessTypes::flags flags,
                       ValueWitnessTypes::extraInhabitantCount xiCount)
    : size(size), stride(stride), flags(flags), extraInhabitantCount(xiCount) {}

  const TypeLayout *getTypeLayout() const { return this; }

  /// The number of extra inhabitants, that is, bit patterns that do not form
  /// valid values of the type, in this type's binary representation.
  unsigned getNumExtraInhabitants() const {
    return extraInhabitantCount;
  }

  bool hasExtraInhabitants() const {
    return extraInhabitantCount != 0;
  }
};

inline void TypeLayout::_static_assert_layout() {
  #define CHECK_TYPE_LAYOUT_OFFSET(FIELD)                               \
    static_assert(offsetof(ValueWitnessTable, FIELD)                    \
                    - offsetof(ValueWitnessTable, size)                 \
                  == offsetof(TypeLayout, FIELD),                       \
                  "layout of " #FIELD " in TypeLayout doesn't match "   \
                  "value witness table")
  CHECK_TYPE_LAYOUT_OFFSET(size);
  CHECK_TYPE_LAYOUT_OFFSET(flags);
  CHECK_TYPE_LAYOUT_OFFSET(extraInhabitantCount);
  CHECK_TYPE_LAYOUT_OFFSET(stride);

  #undef CHECK_TYPE_LAYOUT_OFFSET
}

template <>
inline void ValueWitnessTable::publishLayout(const TypeLayout &layout) {
  size = layout.size;
  stride = layout.stride;
  extraInhabitantCount = layout.extraInhabitantCount;

  // Currently there is nothing in the runtime or ABI which tries to
  // asynchronously check completion, so we can just do a normal store here.
  //
  // If we decide to start allowing that (to speed up checkMetadataState,
  // maybe), we'll have to:
  //   - turn this into an store-release,
  //   - turn the load in checkIsComplete() into a load-acquire, and
  //   - do something about getMutableVWTableForInit.
  flags = layout.flags;
}

template <> inline bool ValueWitnessTable::checkIsComplete() const {
  return !flags.isIncomplete();
}

template <>
inline const EnumValueWitnessTable *ValueWitnessTable::_asEVWT() const {
  assert(EnumValueWitnessTable::classof(this));
  return static_cast<const EnumValueWitnessTable *>(this);
}

// Standard value-witness tables.

#define BUILTIN_TYPE(Symbol, _) \
  SWIFT_RUNTIME_EXPORT const ValueWitnessTable VALUE_WITNESS_SYM(Symbol);
#define BUILTIN_POINTER_TYPE(Symbol, _) \
  SWIFT_RUNTIME_EXPORT const ValueWitnessTable VALUE_WITNESS_SYM(Symbol);
#include "BuiltinTypes.def"

// The () -> () table can be used for arbitrary function types.
SWIFT_RUNTIME_EXPORT
const ValueWitnessTable
  VALUE_WITNESS_SYM(FUNCTION_MANGLING);     // () -> ()

// The @escaping () -> () table can be used for arbitrary escaping function types.
SWIFT_RUNTIME_EXPORT
const ValueWitnessTable
  VALUE_WITNESS_SYM(NOESCAPE_FUNCTION_MANGLING);     // @noescape () -> ()

// The @convention(thin) () -> () table can be used for arbitrary thin function types.
SWIFT_RUNTIME_EXPORT
const ValueWitnessTable
  VALUE_WITNESS_SYM(THIN_FUNCTION_MANGLING);    // @convention(thin) () -> ()

// The () table can be used for arbitrary empty types.
SWIFT_RUNTIME_EXPORT
const ValueWitnessTable VALUE_WITNESS_SYM(EMPTY_TUPLE_MANGLING);        // ()

// The table for aligned-pointer-to-pointer types.
SWIFT_RUNTIME_EXPORT
const ValueWitnessTable METATYPE_VALUE_WITNESS_SYM(Bo); // Builtin.NativeObject.Type

/// Return the value witnesses for unmanaged pointers.
static inline const ValueWitnessTable &getUnmanagedPointerValueWitnesses() {
#if __POINTER_WIDTH__ == 64
  return VALUE_WITNESS_SYM(Bi64_);
#else
  return VALUE_WITNESS_SYM(Bi32_);
#endif
}

/// Return value witnesses for a pointer-aligned pointer type.
static inline
const ValueWitnessTable &
getUnmanagedPointerPointerValueWitnesses() {
  return METATYPE_VALUE_WITNESS_SYM(Bo);
}

using OpaqueMetadata = TargetOpaqueMetadata<InProcess>;

// Standard POD opaque metadata.
// The "Int" metadata are used for arbitrary POD data with the
// matching characteristics.
using FullOpaqueMetadata = FullMetadata<OpaqueMetadata>;
#define BUILTIN_TYPE(Symbol, Name) \
    SWIFT_RUNTIME_EXPORT \
    const FullOpaqueMetadata METADATA_SYM(Symbol);
#include "BuiltinTypes.def"

/// The standard metadata for the empty tuple type.
SWIFT_RUNTIME_EXPORT
const
  FullMetadata<TupleTypeMetadata> METADATA_SYM(EMPTY_TUPLE_MANGLING);

/// The standard metadata for the empty protocol composition type, Any.
SWIFT_RUNTIME_EXPORT
const
  FullMetadata<ExistentialTypeMetadata> METADATA_SYM(ANY_MANGLING);

/// The standard metadata for the empty class-constrained protocol composition
/// type, AnyObject.
SWIFT_RUNTIME_EXPORT
const
  FullMetadata<ExistentialTypeMetadata> METADATA_SYM(ANYOBJECT_MANGLING);


/// True if two context descriptors in the currently running program describe
/// the same context.
// bool equalContexts(const ContextDescriptor *a, const ContextDescriptor *b);

/// Compute the bounds of class metadata with a resilient superclass.
// ClassMetadataBounds getResilientMetadataBounds(
//                                            const ClassDescriptor *descriptor);
// int32_t getResilientImmediateMembersOffset(const ClassDescriptor *descriptor);

/// Fetch a uniqued metadata object for a nominal type which requires
/// singleton metadata initialization.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse
// swift_getSingletonMetadata(MetadataRequest request,
//                            const TypeContextDescriptor *description);

// /// Fetch a uniqued metadata object for a generic nominal type.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse
// swift_getGenericMetadata(MetadataRequest request,
//                          const void * const *arguments,
//                          const TypeContextDescriptor *description);

// /// Allocate a generic class metadata object.  This is intended to be
// /// called by the metadata instantiation function of a generic class.
// ///
// /// This function:
// ///   - computes the required size of the metadata object based on the
// ///     class hierarchy;
// ///   - allocates memory for the metadata object based on the computed
// ///     size and the additional requirements imposed by the pattern;
// ///   - copies information from the pattern into the allocated metadata; and
// ///   - fully initializes the ClassMetadata header, except that the
// ///     superclass pointer will be null (or SwiftObject under ObjC interop
// ///     if there is no formal superclass).
// ///
// /// The instantiation function is responsible for completing the
// /// initialization, including:
// ///   - setting the superclass pointer;
// ///   - copying class data from the superclass;
// ///   - installing the generic arguments;
// ///   - installing new v-table entries and overrides; and
// ///   - registering the class with the runtime under ObjC interop.
// /// Most of this work can be achieved by calling swift_initClassMetadata.
// SWIFT_RUNTIME_EXPORT
// ClassMetadata *
// swift_allocateGenericClassMetadata(const ClassDescriptor *description,
//                                    const void *arguments,
//                                    const GenericClassMetadataPattern *pattern);

// /// Allocate a generic value metadata object.  This is intended to be
// /// called by the metadata instantiation function of a generic struct or
// /// enum.
// SWIFT_RUNTIME_EXPORT
// ValueMetadata *
// swift_allocateGenericValueMetadata(const ValueTypeDescriptor *description,
//                                    const void *arguments,
//                                    const GenericValueMetadataPattern *pattern,
//                                    size_t extraDataSize);

// /// Check that the given metadata has the right state.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse swift_checkMetadataState(MetadataRequest request,
//                                           const Metadata *type);

// /// Retrieve a witness table based on a given conformance.
// ///
// /// \param conformance - The protocol conformance descriptor, which
// ///   contains any information required to form the witness table.
// ///
// /// \param type - The conforming type, used to form a uniquing key
// ///   for the conformance.
// ///
// /// \param instantiationArgs - An opaque pointer that's forwarded to
// ///   the instantiation function, used for conditional conformances.
// ///   This API implicitly embeds an assumption that these arguments
// ///   never form part of the uniquing key for the conformance, which
// ///   is ultimately a statement about the user model of overlapping
// ///   conformances.
// SWIFT_RUNTIME_EXPORT
// const WitnessTable *
// swift_getWitnessTable(const ProtocolConformanceDescriptor *conformance,
//                       const Metadata *type,
//                       const void * const *instantiationArgs);

// /// Retrieve an associated type witness from the given witness table.
// ///
// /// \param wtable The witness table.
// /// \param conformingType Metadata for the conforming type.
// /// \param reqBase "Base" requirement used to compute the witness index
// /// \param assocType Associated type descriptor.
// ///
// /// \returns metadata for the associated type witness.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse swift_getAssociatedTypeWitness(
//                                           MetadataRequest request,
//                                           WitnessTable *wtable,
//                                           const Metadata *conformingType,
//                                           const ProtocolRequirement *reqBase,
//                                           const ProtocolRequirement *assocType);

// /// Retrieve an associated conformance witness table from the given witness
// /// table.
// ///
// /// \param wtable The witness table.
// /// \param conformingType Metadata for the conforming type.
// /// \param assocType Metadata for the associated type.
// /// \param reqBase "Base" requirement used to compute the witness index
// /// \param assocConformance Associated conformance descriptor.
// ///
// /// \returns corresponding witness table.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// const WitnessTable *swift_getAssociatedConformanceWitness(
//                                   WitnessTable *wtable,
//                                   const Metadata *conformingType,
//                                   const Metadata *assocType,
//                                   const ProtocolRequirement *reqBase,
//                                   const ProtocolRequirement *assocConformance);

// /// Fetch a uniqued metadata for a function type.
// SWIFT_RUNTIME_EXPORT
// const FunctionTypeMetadata *
// swift_getFunctionTypeMetadata(FunctionTypeFlags flags,
//                               const Metadata *const *parameters,
//                               const uint32_t *parameterFlags,
//                               const Metadata *result);

// SWIFT_RUNTIME_EXPORT
// const FunctionTypeMetadata *
// swift_getFunctionTypeMetadata0(FunctionTypeFlags flags,
//                                const Metadata *result);

// SWIFT_RUNTIME_EXPORT
// const FunctionTypeMetadata *
// swift_getFunctionTypeMetadata1(FunctionTypeFlags flags,
//                                const Metadata *arg0,
//                                const Metadata *result);

// SWIFT_RUNTIME_EXPORT
// const FunctionTypeMetadata *
// swift_getFunctionTypeMetadata2(FunctionTypeFlags flags,
//                                const Metadata *arg0,
//                                const Metadata *arg1,
//                                const Metadata *result);

// SWIFT_RUNTIME_EXPORT
// const FunctionTypeMetadata *swift_getFunctionTypeMetadata3(
//                                                 FunctionTypeFlags flags,
//                                                 const Metadata *arg0,
//                                                 const Metadata *arg1,
//                                                 const Metadata *arg2,
//                                                 const Metadata *result);

// #if SWIFT_OBJC_INTEROP
// SWIFT_RUNTIME_EXPORT
// void
// swift_instantiateObjCClass(const ClassMetadata *theClass);

// SWIFT_RUNTIME_EXPORT
// Class
// swift_getInitializedObjCClass(Class c);

// /// Fetch a uniqued type metadata for an ObjC class.
// SWIFT_RUNTIME_EXPORT
// const Metadata *
// swift_getObjCClassMetadata(const ClassMetadata *theClass);

// /// Get the ObjC class object from class type metadata.
// SWIFT_RUNTIME_EXPORT
// const ClassMetadata *
// swift_getObjCClassFromMetadata(const Metadata *theClass);

// // Get the ObjC class object from class type metadata,
// // or nullptr if the type isn't an ObjC class.
// const ClassMetadata *
// swift_getObjCClassFromMetadataConditional(const Metadata *theClass);

// SWIFT_RUNTIME_EXPORT
// const ClassMetadata *
// swift_getObjCClassFromObject(HeapObject *object);
// #endif

// /// Fetch a unique type metadata object for a foreign type.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse
// swift_getForeignTypeMetadata(MetadataRequest request,
//                              ForeignTypeMetadata *nonUnique);

// /// Fetch a uniqued metadata for a tuple type.
// ///
// /// The labels argument is null if and only if there are no element
// /// labels in the tuple.  Otherwise, it is a null-terminated
// /// concatenation of space-terminated NFC-normalized UTF-8 strings,
// /// assumed to point to constant global memory.
// ///
// /// That is, for the tuple type (a : Int, Int, c : Int), this
// /// argument should be:
// ///   "a  c \0"
// ///
// /// This representation allows label strings to be efficiently
// /// (1) uniqued within a linkage unit and (2) compared with strcmp.
// /// In other words, it's optimized for code size and uniquing
// /// efficiency, not for the convenience of actually consuming
// /// these strings.
// ///
// /// \param elements - potentially invalid if numElements is zero;
// ///   otherwise, an array of metadata pointers.
// /// \param labels - the labels string
// /// \param proposedWitnesses - an optional proposed set of value witnesses.
// ///   This is useful when working with a non-dependent tuple type
// ///   where the entrypoint is just being used to unique the metadata.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse
// swift_getTupleTypeMetadata(MetadataRequest request,
//                            TupleTypeFlags flags,
//                            const Metadata * const *elements,
//                            const char *labels,
//                            const ValueWitnessTable *proposedWitnesses);

// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse
// swift_getTupleTypeMetadata2(MetadataRequest request,
//                             const Metadata *elt0, const Metadata *elt1,
//                             const char *labels,
//                             const ValueWitnessTable *proposedWitnesses);
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataResponse
// swift_getTupleTypeMetadata3(MetadataRequest request,
//                             const Metadata *elt0, const Metadata *elt1,
//                             const Metadata *elt2, const char *labels,
//                             const ValueWitnessTable *proposedWitnesses);

// /// Perform layout as if for a tuple whose elements have the given layouts.
// ///
// /// \param tupleLayout - A structure into which to write the tuple layout.
// ///   Must be non-null.
// /// \param elementOffsets - An array into which to write the offsets of
// ///   the elements.  May be null.  Must have space for all elements,
// ///   including element 0 (which will always have offset 0).
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// void swift_getTupleTypeLayout(TypeLayout *tupleLayout,
//                               uint32_t *elementOffsets,
//                               TupleTypeFlags flags,
//                               const TypeLayout * const *elements);

// /// Perform layout as if for a two-element tuple whose elements have
// /// the given layouts.
// ///
// /// \param tupleLayout - A structure into which to write the tuple layout.
// ///   Must be non-null.
// /// \returns The offset of the second element.
// ///   The first element always has offset 0.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// size_t swift_getTupleTypeLayout2(TypeLayout *tupleLayout,
//                                  const TypeLayout *elt0,
//                                  const TypeLayout *elt1);

// struct OffsetPair { size_t First; size_t Second; };

// /// Perform layout as if for a three-element tuple whose elements have
// /// the given layouts.
// ///
// /// \param tupleLayout - A structure into which to write the tuple layout.
// ///   Must be non-null.
// /// \returns The offsets of the second and third elements.
// ///   The first element always has offset 0.
// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// OffsetPair swift_getTupleTypeLayout3(TypeLayout *tupleLayout,
//                                      const TypeLayout *elt0Layout,
//                                      const TypeLayout *elt1Layout,
//                                      const TypeLayout *elt2Layout);

// /// Initialize the value witness table and struct field offset vector for a
// /// struct, using the "Universal" layout strategy.
// SWIFT_RUNTIME_EXPORT
// void swift_initStructMetadata(StructMetadata *self,
//                               StructLayoutFlags flags,
//                               size_t numFields,
//                               const TypeLayout * const *fieldTypes,
//                               uint32_t *fieldOffsets);

// /// Allocate the metadata for a class and copy fields from the given pattern.
// /// The final size of the metadata is calculated at runtime from the metadata
// /// bounds in the class descriptor.
// ///
// /// This function is only intended to be called from the relocation function
// /// of a resilient class pattern.
// ///
// /// The metadata completion function must complete the metadata by calling
// /// swift_initClassMetadata().
// SWIFT_RUNTIME_EXPORT
// ClassMetadata *
// swift_relocateClassMetadata(const ClassDescriptor *descriptor,
//                             const ResilientClassMetadataPattern *pattern);

// /// Initialize various fields of the class metadata.
// ///
// /// Namely:
// /// - The superclass field is set to \p super.
// /// - If the class metadata was allocated at runtime, copies the
// ///   vtable entries from the superclass and installs the class's
// ///   own vtable entries and overrides of superclass vtable entries.
// /// - Copies the field offsets and generic parameters and conformances
// ///   from the superclass.
// /// - Initializes the field offsets using the runtime type layouts
// ///   passed in \p fieldTypes.
// ///
// /// This initialization pattern in the following cases:
// /// - The class has generic ancestry, or resiliently-sized fields.
// ///   In this case the metadata was emitted statically but is incomplete,
// ///   because, the superclass field, generic parameters and conformances,
// ///   and field offset vector entries require runtime completion.
// ///
// /// - The class is not generic, and has resilient ancestry.
// ///   In this case the class metadata was allocated from a resilient
// ///   class metadata pattern by swift_relocateClassMetadata().
// ///
// /// - The class is generic.
// ///   In this case the class metadata was allocated from a generic
// ///   class metadata pattern by swift_allocateGenericClassMetadata().
// SWIFT_RUNTIME_EXPORT
// void swift_initClassMetadata(ClassMetadata *self,
//                              ClassLayoutFlags flags,
//                              size_t numFields,
//                              const TypeLayout * const *fieldTypes,
//                              size_t *fieldOffsets);

// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataDependency
// swift_initClassMetadata2(ClassMetadata *self,
//                          ClassLayoutFlags flags,
//                          size_t numFields,
//                          const TypeLayout * const *fieldTypes,
//                          size_t *fieldOffsets);

// #if SWIFT_OBJC_INTEROP
// /// Initialize various fields of the class metadata.
// ///
// /// This is a special function only used to re-initialize metadata of
// /// classes that are visible to Objective-C and have resilient fields.
// ///
// /// This means the class does not have generic or resilient ancestry,
// /// and is itself not generic. However, it might have fields whose
// /// size is not known at compile time.
// SWIFT_RUNTIME_EXPORT
// void swift_updateClassMetadata(ClassMetadata *self,
//                                ClassLayoutFlags flags,
//                                size_t numFields,
//                                const TypeLayout * const *fieldTypes,
//                                size_t *fieldOffsets);

// SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
// MetadataDependency
// swift_updateClassMetadata2(ClassMetadata *self,
//                            ClassLayoutFlags flags,
//                            size_t numFields,
//                            const TypeLayout * const *fieldTypes,
//                            size_t *fieldOffsets);
// #endif

// /// Given class metadata, a class descriptor and a method descriptor, look up
// /// and load the vtable entry from the given metadata. The metadata must be of
// /// the same class or a subclass of the descriptor.
// SWIFT_RUNTIME_EXPORT
// void *
// swift_lookUpClassMethod(const ClassMetadata *metadata,
//                         const MethodDescriptor *method,
//                         const ClassDescriptor *description);

// /// Fetch a uniqued metadata for a metatype type.
// SWIFT_RUNTIME_EXPORT
// const MetatypeMetadata *
// swift_getMetatypeMetadata(const Metadata *instanceType);

// /// Fetch a uniqued metadata for an existential metatype type.
// SWIFT_RUNTIME_EXPORT
// const ExistentialMetatypeMetadata *
// swift_getExistentialMetatypeMetadata(const Metadata *instanceType);

// /// Fetch a uniqued metadata for an existential type. The array
// /// referenced by \c protocols will be sorted in-place.
// SWIFT_RUNTIME_EXPORT
// const ExistentialTypeMetadata *
// swift_getExistentialTypeMetadata(ProtocolClassConstraint classConstraint,
//                                  const Metadata *superclassConstraint,
//                                  size_t numProtocols,
//                                  const ProtocolDescriptorRef *protocols);

/// Perform a copy-assignment from one existential container to another.
/// Both containers must be of the same existential type representable with the
/// same number of witness tables.
SWIFT_RUNTIME_EXPORT
OpaqueValue *swift_assignExistentialWithCopy(OpaqueValue *dest,
                                             const OpaqueValue *src,
                                             const Metadata *type);

/// Perform a copy-assignment from one existential container to another.
/// Both containers must be of the same existential type representable with no
/// witness tables.
OpaqueValue *swift_assignExistentialWithCopy0(OpaqueValue *dest,
                                              const OpaqueValue *src,
                                              const Metadata *type);

/// Perform a copy-assignment from one existential container to another.
/// Both containers must be of the same existential type representable with one
/// witness table.
OpaqueValue *swift_assignExistentialWithCopy1(OpaqueValue *dest,
                                              const OpaqueValue *src,
                                              const Metadata *type);

/// Calculate the numeric index of an extra inhabitant of a heap object
/// pointer in memory.
inline int swift_getHeapObjectExtraInhabitantIndex(HeapObject * const* src) {
  // This must be consistent with the getHeapObjectExtraInhabitantIndex
  // implementation in IRGen's ExtraInhabitants.cpp.

  using namespace heap_object_abi;

  uintptr_t value = reinterpret_cast<uintptr_t>(*src);
  if (value >= LeastValidPointerValue)
    return -1;

  // Check for tagged pointers on appropriate platforms.  Knowing that
  // value < LeastValidPointerValue tells us a lot.
#if SWIFT_OBJC_INTEROP
  if (value & ((uintptr_t(1) << ObjCReservedLowBits) - 1))
    return -1;
  return int(value >> ObjCReservedLowBits);
#else
  return int(value);
#endif
}
  
/// Store an extra inhabitant of a heap object pointer to memory,
/// in the style of a value witness.
inline void swift_storeHeapObjectExtraInhabitant(HeapObject **dest, int index) {
  // This must be consistent with the storeHeapObjectExtraInhabitant
  // implementation in IRGen's ExtraInhabitants.cpp.

#if SWIFT_OBJC_INTEROP
  auto value = uintptr_t(index) << heap_object_abi::ObjCReservedLowBits;
#else
  auto value = uintptr_t(index);
#endif
  *dest = reinterpret_cast<HeapObject*>(value);
}

/// Return the number of extra inhabitants in a heap object pointer.
inline constexpr unsigned swift_getHeapObjectExtraInhabitantCount() {
  // This must be consistent with the getHeapObjectExtraInhabitantCount
  // implementation in IRGen's ExtraInhabitants.cpp.

  using namespace heap_object_abi;

  // The runtime needs no more than INT_MAX inhabitants.
#if SWIFT_OBJC_INTEROP
  return (LeastValidPointerValue >> ObjCReservedLowBits) > INT_MAX
    ? (unsigned)INT_MAX
    : (unsigned)(LeastValidPointerValue >> ObjCReservedLowBits);
#else
  return (LeastValidPointerValue) > INT_MAX
    ? unsigned(INT_MAX)
    : unsigned(LeastValidPointerValue);
#endif
}  

/// Calculate the numeric index of an extra inhabitant of a function
/// pointer in memory.
inline int swift_getFunctionPointerExtraInhabitantIndex(void * const* src) {
  // This must be consistent with the getFunctionPointerExtraInhabitantIndex
  // implementation in IRGen's ExtraInhabitants.cpp.
  uintptr_t value = reinterpret_cast<uintptr_t>(*src);
  return (value < heap_object_abi::LeastValidPointerValue
            ? (int) value : -1);
}
  
/// Store an extra inhabitant of a function pointer to memory, in the
/// style of a value witness.
inline void swift_storeFunctionPointerExtraInhabitant(void **dest, int index) {
  // This must be consistent with the storeFunctionPointerExtraInhabitantIndex
  // implementation in IRGen's ExtraInhabitants.cpp.
  *dest = reinterpret_cast<void*>(static_cast<uintptr_t>(index));
}

/// Return the number of extra inhabitants in a function pointer.
inline constexpr unsigned swift_getFunctionPointerExtraInhabitantCount() {
  // This must be consistent with the getFunctionPointerExtraInhabitantCount
  // implementation in IRGen's ExtraInhabitants.cpp.

  using namespace heap_object_abi;

  // The runtime needs no more than INT_MAX inhabitants.
  return (LeastValidPointerValue) > INT_MAX
    ? (unsigned)INT_MAX
    : (unsigned)(LeastValidPointerValue);
}

// /// Return the type name for a given type metadata.
// std::string nameForMetadata(const Metadata *type,
//                             bool qualified = true);

// /// Register a block of protocol records for dynamic lookup.
// SWIFT_RUNTIME_EXPORT
// void swift_registerProtocols(const ProtocolRecord *begin,
//                              const ProtocolRecord *end);

// /// Register a block of protocol conformance records for dynamic lookup.
// SWIFT_RUNTIME_EXPORT
// void swift_registerProtocolConformances(const ProtocolConformanceRecord *begin,
//                                         const ProtocolConformanceRecord *end);

// /// Register a block of type context descriptors for dynamic lookup.
// SWIFT_RUNTIME_EXPORT
// void swift_registerTypeMetadataRecords(const TypeMetadataRecord *begin,
//                                        const TypeMetadataRecord *end);

// /// Return the superclass, if any.  The result is nullptr for root
// /// classes and class protocol types.
// SWIFT_CC(swift)
// SWIFT_RUNTIME_STDLIB_INTERNAL
// const Metadata *_swift_class_getSuperclass(const Metadata *theClass);

// SWIFT_CC(swift)
// SWIFT_RUNTIME_STDLIB_INTERNAL MetadataResponse
// getSuperclassMetadata(MetadataRequest request, const ClassMetadata *self);

// #if !NDEBUG
// /// Verify that the given metadata pointer correctly roundtrips its
// /// mangled name through the demangler.
// void verifyMangledNameRoundtrip(const Metadata *metadata);
// #endif

// SWIFT_CC(swift) SWIFT_RUNTIME_STDLIB_API
// const TypeContextDescriptor *swift_getTypeContextDescriptor(const Metadata *type);

// // Defined in KeyPath.swift in the standard library.
// SWIFT_RUNTIME_EXPORT
// const HeapObject *swift_getKeyPath(const void *pattern, const void *arguments);

// #if defined(swiftCore_EXPORTS)
// /// Given a pointer to a borrowed value of type `Root` and a
// /// `KeyPath<Root, Value>`, project a pointer to a borrowed value of type
// /// `Value`.
// SWIFT_RUNTIME_EXPORT
// YieldOnceCoroutine<const OpaqueValue* (const OpaqueValue *root,
//                                        void *keyPath)>::type
// swift_readAtKeyPath;

// /// Given a pointer to a mutable value of type `Root` and a
// /// `WritableKeyPath<Root, Value>`, project a pointer to a mutable value
// /// of type `Value`.
// SWIFT_RUNTIME_EXPORT
// YieldOnceCoroutine<OpaqueValue* (OpaqueValue *root, void *keyPath)>::type
// swift_modifyAtWritableKeyPath;

// /// Given a pointer to a borrowed value of type `Root` and a
// /// `ReferenceWritableKeyPath<Root, Value>`, project a pointer to a
// /// mutable value of type `Value`.
// SWIFT_RUNTIME_EXPORT
// YieldOnceCoroutine<OpaqueValue* (const OpaqueValue *root, void *keyPath)>::type
// swift_modifyAtReferenceWritableKeyPath;
// #endif

// SWIFT_RUNTIME_EXPORT
// void swift_enableDynamicReplacementScope(const DynamicReplacementScope *scope);

// SWIFT_RUNTIME_EXPORT
// void swift_disableDynamicReplacementScope(const DynamicReplacementScope *scope);

#pragma clang diagnostic pop

} // end namespace swift

#endif // SWIFT_RUNTIME_METADATA_H
