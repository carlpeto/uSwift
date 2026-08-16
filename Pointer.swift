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

public protocol _Pointer
: Hashable, Strideable, BitwiseCopyable {
  // , CustomDebugStringConvertible, CustomReflectable {
  typealias Distance = Int
  
  associatedtype Pointee: ~Copyable

  var _rawValue: Builtin.RawPointer { get }

  // we are changing the standard wrapping/raw pointer
  // initialiser that is used extensively throughout the
  // standard library to indicate that if a nil pointer is passed
  // the initialiser will fail... this is useful to make it simpler
  // to capture and indicate the case when allocRaw returns a nil
  // pointer due to an out of memory condition
  init?(_ _rawValue: Builtin.RawPointer)

  // this is the wrong name really, what I'm trying to convey
  // is the idea of creating a pointer where you don't check
  // if it is nil or not on creation... it will most of the time
  // not be nil but it being nil does not represent an out of
  // memory condition or if it does, this issue is handled elsewhere
  init(knownNotNilRawPointer: Builtin.RawPointer)
}

extension _Pointer {
  @_transparent
  public init?(_ from : OpaquePointer) {
    self.init(from._rawValue)
  }

  @_transparent
  public init?(_ from : OpaquePointer?) {
    guard let unwrapped = from else { return nil }
    self.init(unwrapped)
  }

  @_transparent
  public init?(bitPattern: Int) {
    if bitPattern == 0 { return nil }
    self.init(Builtin.inttoptr_Word(bitPattern._builtinWordValue))
  }

  // special microcontroller hack, use with care
  @_transparent
  public init(knownNotNilBitPattern bitPattern: Int) {
    self.init(knownNotNilRawPointer: Builtin.inttoptr_Word(bitPattern._builtinWordValue))
  }

  @_transparent
  public init?(bitPattern: UInt) {
    if bitPattern == 0 { return nil }
    self.init(Builtin.inttoptr_Word(bitPattern._builtinWordValue))
  }

  @_transparent
  public init?(_ other: Self) {
    self.init(other._rawValue)
  }

  @_transparent
  public init?(_ other: Self?) {
    guard let unwrapped = other else { return nil }
    self.init(unwrapped._rawValue)
  }
}

// well, this is pretty annoying
extension _Pointer /*: Equatable */ {
  // - Note: This may be more efficient than Strideable's implementation
  //   calling self.distance().
  @_transparent
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension _Pointer /*: Comparable */ {
  // - Note: This is an unsigned comparison unlike Strideable's
  //   implementation.
  @_transparent
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return Bool(Builtin.cmp_ult_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension _Pointer /*: Strideable*/ {
  @_transparent
  public func successor() -> Self {
    return advanced(by: 1)
  }

  @_transparent
  public func predecessor() -> Self {
    return advanced(by: -1)
  }

  @_transparent
  public func distance(to end: Self) -> Int {
    return
      Int(Builtin.sub_Word(Builtin.ptrtoint_Word(end._rawValue),
                           Builtin.ptrtoint_Word(_rawValue)))
      / MemoryLayout<Pointee>.stride
  }

  @_transparent
  public func advanced(by n: Int) -> Self {
    return Self(Builtin.gep_Word(
      self._rawValue, n._builtinWordValue, Pointee.self)) ?? self
  }
}

extension _Pointer /*: Hashable */ {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(UInt(bitPattern: self))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(seed: seed, UInt(bitPattern: self))
  }
}

// extension _Pointer /*: CustomDebugStringConvertible */ {
//   public var debugDescription: String {
//     return _rawPointerToString(_rawValue)
//   }
// }

// extension _Pointer /*: CustomReflectable */ {
//   public var customMirror: Mirror {
//     let ptrValue = UInt64(
//       bitPattern: Int64(Int(Builtin.ptrtoint_Word(_rawValue))))
//     return Mirror(self, children: ["pointerValue": ptrValue])
//   }
// }

extension Int {
  @_transparent
  public init<P: _Pointer>(bitPattern pointer: P?) {
    if let pointer = pointer {
      self = Int(Builtin.ptrtoint_Word(pointer._rawValue))
    } else {
      self = 0
    }
  }
}

extension UInt {
  @_transparent
  public init<P: _Pointer>(bitPattern pointer: P?) {
    if let pointer = pointer {
      self = UInt(Builtin.ptrtoint_Word(pointer._rawValue))
    } else {
      self = 0
    }
  }
}

// Pointer arithmetic operators (formerly via Strideable)
extension Strideable where Self : _Pointer {
  @_transparent
  public static func + (lhs: Self, rhs: Self.Stride) -> Self {
    return lhs.advanced(by: rhs)
  }

  @_transparent
  public static func + (lhs: Self.Stride, rhs: Self) -> Self {
    return rhs.advanced(by: lhs)
  }

  @_transparent
  public static func - (lhs: Self, rhs: Self.Stride) -> Self {
    return lhs.advanced(by: -rhs)
  }

  @_transparent
  public static func - (lhs: Self, rhs: Self) -> Self.Stride {
    return rhs.distance(to: lhs)
  }

  @_transparent
  public static func += (lhs: inout Self, rhs: Self.Stride) {
    lhs = lhs.advanced(by: rhs)
  }

  @_transparent
  public static func -= (lhs: inout Self, rhs: Self.Stride) {
    lhs = lhs.advanced(by: -rhs)
  }
}

@_transparent
public // COMPILER_INTRINSIC
func _convertPointerToPointerArgument<
  FromPointer : _Pointer,
  ToPointer : _Pointer
>(_ from: FromPointer) -> ToPointer {
  return ToPointer(knownNotNilRawPointer: from._rawValue)
}

@_transparent
public // COMPILER_INTRINSIC
func _convertInOutToPointerArgument<
  ToPointer : _Pointer
>(_ from: Builtin.RawPointer) -> ToPointer {
  return ToPointer(knownNotNilRawPointer: from)
}


// //dummy intrinsic operations
@_transparent
public // COMPILER_INTRINSIC
func _convertConstStringToUTF8PointerArgument() {
}

/// Derive a pointer argument from a value array parameter.
///
/// This always produces a non-null pointer, even if the array doesn't have any
/// storage.
@_transparent
public // COMPILER_INTRINSIC
func _convertConstArrayToPointerArgument<
  FromElement,
  ToPointer: _Pointer
>(_ arr: [FromElement]) -> (AnyObject?, ToPointer) {
  let (owner, opaquePointer) = arr._cPointerArgs()

  let validPointer: ToPointer
  if let addr = opaquePointer {
    validPointer = ToPointer(knownNotNilRawPointer: addr._rawValue)
  } else {
    let lastAlignedValue = ~(MemoryLayout<FromElement>.alignment - 1)
    let lastAlignedPointer = UnsafeRawPointer(bitPattern: lastAlignedValue)!
    validPointer = ToPointer(knownNotNilRawPointer: lastAlignedPointer._rawValue)
  }
  return (owner, validPointer)
}

/// Derive a pointer argument from an inout array parameter.
///
/// This always produces a non-null pointer, even if the array's length is 0.
@_transparent
public // COMPILER_INTRINSIC
func _convertMutableArrayToPointerArgument<
  FromElement,
  ToPointer: _Pointer
>(_ a: inout [FromElement]) -> (AnyObject?, ToPointer) {
  // TODO: Putting a canary at the end of the array in checked builds might
  // be a good idea

  // Call reserve to force contiguous storage.
  // a.reserveCapacity(0)
  // _debugPrecondition(a._baseAddressIfContiguous != nil || a.isEmpty)

  return _convertConstArrayToPointerArgument(a)
}
