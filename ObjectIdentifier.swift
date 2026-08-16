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

@frozen // trivial-implementation
public struct ObjectIdentifier {
  @usableFromInline // trivial-implementation
  internal let _value: Builtin.RawPointer

  @inlinable // trivial-implementation
  public init(_ x: AnyObject) {
    self._value = Builtin.bridgeToRawPointer(x)
  }

  @inlinable // trivial-implementation
  public init(_ x: Any.Type) {
    self._value = unsafeBitCast(x, to: Builtin.RawPointer.self)
  }
}

// extension ObjectIdentifier : CustomDebugStringConvertible {
//   public var debugDescription: String {
//     return "ObjectIdentifier(\(_rawPointerToString(_value)))"
//   }
// }

extension ObjectIdentifier: Equatable {
  @inlinable // trivial-implementation
  public static func == (x: ObjectIdentifier, y: ObjectIdentifier) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(x._value, y._value))
  }
}

extension ObjectIdentifier: Comparable {
  @inlinable // trivial-implementation
  public static func < (lhs: ObjectIdentifier, rhs: ObjectIdentifier) -> Bool {
    return UInt(bitPattern: lhs) < UInt(bitPattern: rhs)
  }
}

extension ObjectIdentifier: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(Int(Builtin.ptrtoint_Word(_value)))
  }
}

extension UInt {
  @inlinable // trivial-implementation
  public init(bitPattern objectID: ObjectIdentifier) {
    self.init(Builtin.ptrtoint_Word(objectID._value))
  }
}

extension Int {
  @inlinable // trivial-implementation
  public init(bitPattern objectID: ObjectIdentifier) {
    self.init(bitPattern: UInt(bitPattern: objectID))
  }
}
