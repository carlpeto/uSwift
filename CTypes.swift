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
// C Primitive Types
//===----------------------------------------------------------------------===//

public typealias CChar = Int8

public typealias CUnsignedChar = UInt8

public typealias CUnsignedShort = UInt16

public typealias CUnsignedInt = UInt

public typealias CUnsignedLong = UInt32

public typealias CUnsignedLongLong = UInt64

public typealias CSignedChar = Int8

public typealias CShort = Int16

public typealias CInt = Int

public typealias CLong = Int32

public typealias CLongLong = Int64

public typealias CFloat = Float

// #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
// // On Darwin, long double is Float80 on x86, and Double otherwise.
// #if arch(x86_64) || arch(i386)
// public typealias CLongDouble = Float80
// #else
// public typealias CLongDouble = Double
// #endif
// #elseif os(Windows)
// // On Windows, long double is always Double.
// public typealias CLongDouble = Double
// #elseif os(Linux)
// // On Linux/x86, long double is Float80.
// // TODO: Fill in definitions for additional architectures as needed. IIRC
// // armv7 should map to Double, but arm64 and ppc64le should map to Float128,
// // which we don't yet have in Swift.
// #if arch(x86_64) || arch(i386)
// public typealias CLongDouble = Float80
// #endif
// // TODO: Fill in definitions for other OSes.
// #if arch(s390x)
// // On s390x '-mlong-double-64' option with size of 64-bits makes the
// // Long Double type equivalent to Double type.
// public typealias CLongDouble = Double
// #endif
// #endif

// FIXME: Is it actually UTF-32 on Darwin?
//
// public typealias CWideChar = Unicode.Scalar

// FIXME: Swift should probably have a UTF-16 type other than UInt16.
//
public typealias CChar16 = UInt16

// public typealias CChar32 = Unicode.Scalar

public typealias CBool = Bool

@frozen
public struct OpaquePointer {
  @usableFromInline
  internal var _rawValue: Builtin.RawPointer

  @usableFromInline @_transparent
  internal init(_ v: Builtin.RawPointer) {
    self._rawValue = v
  }

  @_transparent
  public init?(bitPattern: Int) {
    if bitPattern == 0 { return nil }
    self._rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  @_transparent
  public init?(bitPattern: UInt) {
    if bitPattern == 0 { return nil }
    self._rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  /// Converts a typed `UnsafePointer` to an opaque C pointer.
  @_transparent
  @_preInverseGenerics
  @safe
  public init<T: ~Copyable>(@_nonEphemeral _ from: UnsafePointer<T>) {
    unsafe self._rawValue = from._rawValue
  }

  /// Converts a typed `UnsafePointer` to an opaque C pointer.
  ///
  /// The result is `nil` if `from` is `nil`.
  @_transparent
  @_preInverseGenerics
  @safe
  public init?<T: ~Copyable>(@_nonEphemeral _ from: UnsafePointer<T>?) {
    guard let unwrapped = unsafe from else { return nil }
    self.init(unwrapped)
  }

  /// Converts a typed `UnsafeMutablePointer` to an opaque C pointer.
  @_transparent
  @_preInverseGenerics
  @safe
  public init<T: ~Copyable>(@_nonEphemeral _ from: UnsafeMutablePointer<T>) {
    unsafe self._rawValue = from._rawValue
  }

  /// Converts a typed `UnsafeMutablePointer` to an opaque C pointer.
  ///
  /// The result is `nil` if `from` is `nil`.
  @_transparent
  @_preInverseGenerics
  @safe
  public init?<T: ~Copyable>(@_nonEphemeral _ from: UnsafeMutablePointer<T>?) {
    guard let unwrapped = unsafe from else { return nil }
    self.init(unwrapped)
  }
}

@available(*, unavailable)
extension OpaquePointer: Sendable {}

extension OpaquePointer: Equatable {
  @inlinable // unsafe-performance
  public static func == (lhs: OpaquePointer, rhs: OpaquePointer) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension OpaquePointer: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(Int(Builtin.ptrtoint_Word(_rawValue)))
  }
}

// extension OpaquePointer : CustomDebugStringConvertible {
//   public var debugDescription: String {
//     return _rawPointerToString(_rawValue)
//   }
// }

extension Int {
  @inlinable // unsafe-performance
  @safe
  public init(bitPattern pointer: OpaquePointer?) {
    unsafe self.init(bitPattern: UnsafeRawPointer(pointer))
  }
}

extension UInt {
  @inlinable // unsafe-performance
  @safe
  public init(bitPattern pointer: OpaquePointer?) {
    unsafe self.init(bitPattern: UnsafeRawPointer(pointer))
  }
}

#if arch(arm64) && !(os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(Windows))
@frozen
public struct CVaListPointer {
  @usableFromInline // unsafe-performance
  internal var _value: (__stack: UnsafeMutablePointer<Int>?,
                        __gr_top: UnsafeMutablePointer<Int>?,
                        __vr_top: UnsafeMutablePointer<Int>?,
                        __gr_off: Int32,
                        __vr_off: Int32)

  @inlinable // unsafe-performance
  public // @testable
  init(__stack: UnsafeMutablePointer<Int>?,
       __gr_top: UnsafeMutablePointer<Int>?,
       __vr_top: UnsafeMutablePointer<Int>?,
       __gr_off: Int32,
       __vr_off: Int32) {
    _value = (__stack, __gr_top, __vr_top, __gr_off, __vr_off)
  }
}

extension CVaListPointer : CustomDebugStringConvertible {
  public var debugDescription: String {
    return "(\(_value.__stack.debugDescription), " +
           "\(_value.__gr_top.debugDescription), " +
           "\(_value.__vr_top.debugDescription), " +
           "\(_value.__gr_off), " +
           "\(_value.__vr_off))"
  }
}

#else

@frozen
public struct CVaListPointer {
  @usableFromInline // unsafe-performance
  internal var _value: UnsafeMutableRawPointer

  @inlinable // unsafe-performance
  public // @testable
  init(_fromUnsafeMutablePointer from: UnsafeMutableRawPointer) {
    _value = from
  }
}

// extension CVaListPointer : CustomDebugStringConvertible {
//   public var debugDescription: String {
//     return _value.debugDescription
//   }
// }

#endif

@inlinable
internal func _memcpy(
  dest destination: UnsafeMutableRawPointer,
  src: UnsafeRawPointer,
  size: UInt
) {
  let dest = destination._rawValue
  let src = src._rawValue
  let size = UInt64(size)._value
  Builtin.int_memcpy_RawPointer_RawPointer_Int64(
    dest, src, size,
    /*volatile:*/ false._value)
}

@inlinable
internal func _memmove(
  dest destination: UnsafeMutableRawPointer,
  src: UnsafeRawPointer,
  size: UInt
) {
  let dest = destination._rawValue
  let src = src._rawValue
  let size = UInt64(size)._value
  Builtin.int_memmove_RawPointer_RawPointer_Int64(
    dest, src, size,
    /*volatile:*/ false._value)
}
