//===--- UnsafePointer.swift ----------------------------------*- swift -*-===//
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

@frozen // unsafe-performance
public struct UnsafePointer<Pointee: ~Copyable>: Copyable {
  public let _rawValue: Builtin.RawPointer

  @_transparent
  public init?(_ _rawValue : Builtin.RawPointer) {
    guard Int(Builtin.ptrtoint_Word(_rawValue)) != 0 else {
      return nil
    }

    self._rawValue = _rawValue
  }

  @_transparent
  public init(knownNotNilRawPointer _rawValue: Builtin.RawPointer) {
    self._rawValue = _rawValue
  }
}

@available(*, unavailable)
extension UnsafePointer: Sendable where Pointee: ~Copyable {}

@_preInverseGenerics
extension UnsafePointer: _Pointer where Pointee: ~Copyable {
  /// A type that represents the distance between two pointers.
  public typealias Distance = Int
}

@_preInverseGenerics
extension UnsafePointer: Equatable where Pointee: ~Copyable {}

@_preInverseGenerics
extension UnsafePointer: Hashable where Pointee: ~Copyable {
  // Note: This explicit `hashValue` applies @_preInverseGenerics to emulate the
  // original (pre-6.0) compiler-synthesized version.
  @_preInverseGenerics
  @safe
  public var hashValue: Int {
    unsafe _hashValue(for: self)
  }
}

@_preInverseGenerics
extension UnsafePointer: Comparable where Pointee: ~Copyable {}

@_preInverseGenerics
extension UnsafePointer: Strideable where Pointee: ~Copyable {}

extension UnsafePointer where Pointee: ~Copyable  {

  @inlinable
  public func deallocate() {
    // Passing zero alignment to the runtime forces "aligned
    // deallocation". Since allocation via `UnsafeMutable[Raw][Buffer]Pointer`
    // always uses the "aligned allocation" path, this ensures that the
    // runtime's allocation and deallocation paths are compatible.
    Builtin.deallocRaw(_rawValue, (-1 as Int)._builtinWordValue, (0 as Int)._builtinWordValue)
  }

  @inlinable // unsafe-performance
  public var pointee: Pointee {
    @_transparent unsafeAddress {
      return self
    }
  }

  @inlinable
  public func withMemoryRebound<T: ~Copyable, E: Error, Result: ~Copyable>(
    to type: T.Type, capacity count: Int,
    _ body: (UnsafePointer<T>?) throws(E) -> Result
  ) throws(E) -> Result {
    Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
    defer {
      Builtin.bindMemory(_rawValue, count._builtinWordValue, Pointee.self)
    }
    return try body(UnsafePointer<T>(_rawValue))
  }

  @inlinable
  public subscript(i: Int) -> Pointee {
    @_transparent
    unsafeAddress {
      return self + i
    }
  }

  @inlinable // unsafe-performance
  internal static var _max : UnsafePointer {
    return UnsafePointer(
      bitPattern: 0 as Int &- MemoryLayout<Pointee>.stride
    )._unsafelyUnwrappedUnchecked
  }
}


@frozen // unsafe-performance
public struct UnsafeMutablePointer<Pointee: ~Copyable>: Copyable{

  // public typealias Distance = Int

  public let _rawValue: Builtin.RawPointer

  @_transparent
  public init?(_ _rawValue : Builtin.RawPointer) {
    guard Int(Builtin.ptrtoint_Word(_rawValue)) != 0 else {
      return nil
    }

    self._rawValue = _rawValue
  }

  @_transparent
  public init(knownNotNilRawPointer _rawValue: Builtin.RawPointer) {
    self._rawValue = _rawValue
  }
}

extension UnsafeMutablePointer where Pointee: ~Copyable {

  @_transparent
  public init(mutating other: UnsafePointer<Pointee>) {
    self._rawValue = other._rawValue
  }

  @_transparent
  public init?(mutating other: UnsafePointer<Pointee>?) {
    guard let unwrapped = other else { return nil }
    self.init(mutating: unwrapped)
  }
  
  @_transparent		
  public init(_ other: UnsafeMutablePointer<Pointee>) {		
   self._rawValue = other._rawValue		
  }		

  @_transparent		
  public init?(_ other: UnsafeMutablePointer<Pointee>?) {		
   guard let unwrapped = other else { return nil }		
   self.init(unwrapped)		
  }		
}

@available(*, unavailable)
extension UnsafeMutablePointer: Sendable where Pointee: ~Copyable {}

@_preInverseGenerics
extension UnsafeMutablePointer: _Pointer where Pointee: ~Copyable {
  /// A type that represents the distance between two pointers.
  public typealias Distance = Int
}

@_preInverseGenerics
extension UnsafeMutablePointer: Equatable where Pointee: ~Copyable {}

@_preInverseGenerics
extension UnsafeMutablePointer: Hashable where Pointee: ~Copyable {
  // Note: This explicit `hashValue` applies @_preInverseGenerics to emulate the
  // original (pre-6.0) compiler-synthesized version.
  @_preInverseGenerics
  @safe
  public var hashValue: Int {
    unsafe _hashValue(for: self)
  }
}

@_preInverseGenerics
extension UnsafeMutablePointer: Comparable where Pointee: ~Copyable {}

@_preInverseGenerics
extension UnsafeMutablePointer: Strideable where Pointee: ~Copyable {}

extension UnsafeMutablePointer where Pointee: ~Copyable {  

  @inlinable
  public static func allocate(capacity count: Int)
    -> UnsafeMutablePointer<Pointee>? {
    let size = MemoryLayout<Pointee>.stride * count
    // For any alignment <= _minAllocationAlignment, force alignment = 0.
    // This forces the runtime's "aligned" allocation path so that
    // deallocation does not require the original alignment.
    //
    // The runtime guarantees:
    //
    // align == 0 || align > _minAllocationAlignment:
    //   Runtime uses "aligned allocation".
    //
    // 0 < align <= _minAllocationAlignment:
    //   Runtime may use either malloc or "aligned allocation".
    var align = Builtin.alignof(Pointee.self)
    if Int(align) <= _minAllocationAlignment() {
      align = (0)._builtinWordValue
    }
    let rawPtr = Builtin.allocRaw(size._builtinWordValue, align)
    Builtin.bindMemory(rawPtr, count._builtinWordValue, Pointee.self)
    return UnsafeMutablePointer(rawPtr)
  }

  @inlinable
  public func deallocate() {
    // Passing zero alignment to the runtime forces "aligned
    // deallocation". Since allocation via `UnsafeMutable[Raw][Buffer]Pointer`
    // always uses the "aligned allocation" path, this ensures that the
    // runtime's allocation and deallocation paths are compatible.
    Builtin.deallocRaw(_rawValue, (-1 as Int)._builtinWordValue, (0 as Int)._builtinWordValue)
  }

  @inlinable // unsafe-performance
  public var pointee: Pointee {
    @_transparent unsafeAddress {
      return UnsafePointer(knownNotNilRawPointer: self._rawValue)
    }
    @_transparent nonmutating unsafeMutableAddress {
      return self
    }
  }
}

extension UnsafeMutablePointer {
  @inlinable
  public func initialize(repeating repeatedValue: Pointee, count: Int) {
    // FIXME: add tests (since the `count` has been added)
    _debugPrecondition(count >= 0)
    // Must not use `initializeFrom` with a `Collection` as that will introduce
    // a cycle.
    for offset in 0..<count {
      Builtin.initialize(repeatedValue, (self + offset)._rawValue)
    }
  }
}

extension UnsafeMutablePointer where Pointee: ~Copyable {
  
  @inlinable
  public func initialize(to value: consuming Pointee) {
    Builtin.initialize(value, self._rawValue)
  }

  @inlinable
  @_preInverseGenerics
  public func move() -> Pointee {
    return Builtin.take(_rawValue)
  }
}

extension UnsafeMutablePointer {
  @inlinable
  @_silgen_name("$sSp6assign9repeating5countyx_SitF")
  public func update(repeating repeatedValue: Pointee, count: Int) {
    _debugPrecondition(count >= 0)
    for i in 0..<count {
      unsafe self[i] = repeatedValue
    }
  }

  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "update(repeating:count:)")
  @_silgen_name("_swift_se0370_UnsafeMutablePointer_assign_repeating_count")
  public func assign(repeating repeatedValue: Pointee, count: Int) {
    unsafe update(repeating: repeatedValue, count: count)
  }
  
  @inlinable
  @_silgen_name("$sSp6assign4from5countySPyxG_SitF")
  public func update(from source: UnsafePointer<Pointee>, count: Int) {
    _debugPrecondition(
      count >= 0)
    if unsafe UnsafePointer(knownNotNilRawPointer: self._rawValue) < source || UnsafePointer(knownNotNilRawPointer: self._rawValue) >= source + count {
      // assign forward from a disjoint or following overlapping range.
      Builtin.assignCopyArrayFrontToBack(
        Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // for i in 0..<count {
      //   self[i] = source[i]
      // }
    }
    else if unsafe UnsafePointer(self) != source {
      // assign backward from a non-following overlapping range.
      Builtin.assignCopyArrayBackToFront(
        Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // var i = count-1
      // while i >= 0 {
      //   self[i] = source[i]
      //   i -= 1
      // }
    }
  }

  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "update(from:count:)")
  @_silgen_name("_swift_se0370_UnsafeMutablePointer_assign_from_count")
  @unsafe
  public func assign(from source: UnsafePointer<Pointee>, count: Int) {
    unsafe update(from: source, count: count)
  }

}

extension UnsafeMutablePointer where Pointee: ~Copyable {

  @inlinable
  public func moveInitialize(@_nonEphemeral from source: UnsafeMutablePointer, count: Int) {
    _debugPrecondition(
      count >= 0)
    if self < source || self >= source + count {
      // initialize forward from a disjoint or following overlapping range.
      Builtin.takeArrayFrontToBack(
        Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // for i in 0..<count {
      //   (self + i).initialize(to: (source + i).move())
      // }
    }
    else {
      // initialize backward from a non-following overlapping range.
      Builtin.takeArrayBackToFront(
        Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // var src = source + count
      // var dst = self + count
      // while dst != self {
      //   (--dst).initialize(to: (--src).move())
      // }
    }
  }
}

extension UnsafeMutablePointer {
  @inlinable
  public func initialize(from source: UnsafePointer<Pointee>, count: Int) {
    _debugPrecondition(
      count >= 0)
    // _debugPrecondition(
    //   UnsafePointer(self) + count <= source ||
    //   source + count <= UnsafePointer(self))
    Builtin.copyArray(
      Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
    // This builtin is equivalent to:
    // for i in 0..<count {
    //   (self + i).initialize(to: source[i])
    // }
  }
}

extension UnsafeMutablePointer where Pointee: ~Copyable {
  @inlinable
  @_silgen_name("$sSp10moveAssign4from5countySpyxG_SitF")
  @_preInverseGenerics
  public func moveUpdate(
    @_nonEphemeral from source: UnsafeMutablePointer, count: Int
  ) {
    _debugPrecondition(
      count >= 0)
    unsafe _debugPrecondition(
      self + count <= source || source + count <= self)
    Builtin.assignTakeArray(
      Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
    // These builtins are equivalent to:
    // for i in 0..<count {
    //   self[i] = (source + i).move()
    // }
  }
}

extension UnsafeMutablePointer {
  @_alwaysEmitIntoClient
  @available(*, deprecated, renamed: "moveUpdate(from:count:)")
  @_silgen_name("_swift_se0370_UnsafeMutablePointer_moveAssign_from_count")
  public func moveAssign(
    @_nonEphemeral from source: UnsafeMutablePointer, count: Int
  ) {
    unsafe moveUpdate(from: source, count: count)
  }
}

  // @inlinable
  // public func moveAssign(from source: UnsafeMutablePointer, count: Int) {
  //   _debugPrecondition(
  //     count >= 0)
  //   _debugPrecondition(
  //     self + count <= source || source + count <= self)
  //   Builtin.assignTakeArray(
  //     Pointee.self, self._rawValue, source._rawValue, count._builtinWordValue)
  //   // These builtins are equivalent to:
  //   // for i in 0..<count {
  //   //   self[i] = (source + i).move()
  //   // }
  // }
  
extension UnsafeMutablePointer where Pointee: ~Copyable {
  @inlinable
  @discardableResult
  public func deinitialize(count: Int) -> UnsafeMutableRawPointer {
    _debugPrecondition(count >= 0)
    // FIXME: optimization should be implemented, where if the `count` value
    // is 1, the `Builtin.destroy(Pointee.self, _rawValue)` gets called.
    Builtin.destroyArray(Pointee.self, _rawValue, count._builtinWordValue)
    return UnsafeMutableRawPointer(self)
  }

  // @inlinable
  // public func withMemoryRebound<T: ~Copyable, E: Error, Result: ~Copyable>(
  //   to type: T.Type, capacity count: Int,
  //   _ body: (UnsafeMutablePointer<T>?) throws(E) -> Result
  // ) throws(E) -> Result {
  //   Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
  //   defer {
  //     Builtin.bindMemory(_rawValue, count._builtinWordValue, Pointee.self)
  //   }
  //   return try body(UnsafeMutablePointer<T>(_rawValue))
  // }

  @inlinable
  public subscript(i: Int) -> Pointee {
    @_transparent
    unsafeAddress {
      return UnsafePointer(knownNotNilRawPointer: self._rawValue).advanced(by: i)
    }
    @_transparent
    nonmutating unsafeMutableAddress {
      return self + i
    }
  }
}

extension UnsafeMutablePointer where Pointee: ~Copyable {
  @_alwaysEmitIntoClient
  @unsafe
  public func withMemoryRebound<T: ~Copyable, E: Error, Result: ~Copyable>(
    to type: T.Type,
    capacity count: Int,
    _ body: (_ pointer: UnsafeMutablePointer<T>) throws(E) -> Result
  ) throws(E) -> Result {
    unsafe _debugPrecondition(
      Int(bitPattern: .init(_rawValue)) & (MemoryLayout<T>.alignment-1) == 0 &&
      ( count == 1 ||
        ( MemoryLayout<Pointee>.stride > MemoryLayout<T>.stride
          ? MemoryLayout<Pointee>.stride % MemoryLayout<T>.stride == 0
          : MemoryLayout<T>.stride % MemoryLayout<Pointee>.stride == 0
        )
      )
    )
    let binding = Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
    defer { Builtin.rebindMemory(_rawValue, binding) }
    return try unsafe body(.init(knownNotNilRawPointer: _rawValue))
  }

  @inlinable // unsafe-performance
  @_preInverseGenerics
  internal static var _max: UnsafeMutablePointer {
    return unsafe UnsafeMutablePointer(
      bitPattern: 0 as Int &- MemoryLayout<Pointee>.stride
    )._unsafelyUnwrappedUnchecked
  }
}
