//===--- UnsafeRawPointer.swift -------------------------------*- swift -*-===//
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

@frozen
public struct UnsafeRawPointer: _Pointer {
  
  public typealias Pointee = UInt8
  
  public let _rawValue: Builtin.RawPointer

  @_transparent
  public init?(_ _rawValue: Builtin.RawPointer) {
    guard Int(Builtin.ptrtoint_Word(_rawValue)) != 0 else {
      return nil
    }

    self._rawValue = _rawValue
  }

  @_transparent
  public init(knownNotNilRawPointer _rawValue: Builtin.RawPointer) {
    self._rawValue = _rawValue
  }

  @_transparent
  public init<T: ~Copyable>(_ other: UnsafePointer<T>) {
    _rawValue = other._rawValue
  }

  @_transparent
  public init?<T: ~Copyable>(_ other: UnsafePointer<T>?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  @_transparent
  public init(_ other: UnsafeMutableRawPointer) {
    _rawValue = other._rawValue
  }

  @_transparent
  public init?(_ other: UnsafeMutableRawPointer?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  @_transparent		
  public init<T>(_ other: UnsafeMutablePointer<T>) {		
   _rawValue = other._rawValue		
  }		

  @_transparent		
  public init?<T>(_ other: UnsafeMutablePointer<T>?) {		
   guard let unwrapped = other else { return nil }		
   _rawValue = unwrapped._rawValue		
  }		

  @inlinable
  public func deallocate() {
    // Passing zero alignment to the runtime forces "aligned
    // deallocation". Since allocation via `UnsafeMutable[Raw][Buffer]Pointer`
    // always uses the "aligned allocation" path, this ensures that the
    // runtime's allocation and deallocation paths are compatible.
    Builtin.deallocRaw(_rawValue, (-1 as Int)._builtinWordValue, (0 as Int)._builtinWordValue)
  }

  @_transparent
  @_preInverseGenerics
  @discardableResult
  public func bindMemory<T: ~Copyable>(
    to type: T.Type, capacity count: Int
  ) -> UnsafePointer<T> {
    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    return unsafe UnsafePointer<T>(knownNotNilRawPointer: _rawValue)
  }

  @_transparent
  @_preInverseGenerics
  public func assumingMemoryBound<T: ~Copyable>(
    to: T.Type
  ) -> UnsafePointer<T> {
    return unsafe UnsafePointer<T>(knownNotNilRawPointer: _rawValue)
  }

  @_alwaysEmitIntoClient
  public func withMemoryRebound<T: ~Copyable, E: Error, Result: ~Copyable>(
    to type: T.Type,
    capacity count: Int,
    _ body: (_ pointer: UnsafePointer<T>) throws(E) -> Result
  ) throws(E) -> Result {
    _debugPrecondition(
      Int(bitPattern: self) & (MemoryLayout<T>.alignment-1) == 0
    )
    let binding = Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
    defer { Builtin.rebindMemory(_rawValue, binding) }
    return try unsafe body(.init(knownNotNilRawPointer: _rawValue))
  }

  @inlinable
  public func load<T>(
    fromByteOffset offset: Int = 0,
    as type: T.Type
  ) -> T {
    unsafe _debugPrecondition(0 == (UInt(bitPattern: self + offset)
        & (UInt(MemoryLayout<T>.alignment) - 1)))

    let rawPointer = unsafe (self + offset)._rawValue

#if compiler(>=5.5) && $BuiltinAssumeAlignment
    let alignedPointer =
      Builtin.assumeAlignment(rawPointer,
                              MemoryLayout<T>.alignment._builtinWordValue)
    return Builtin.loadRaw(alignedPointer)
#else
    return Builtin.loadRaw(rawPointer)
#endif
  }

  @inlinable
  @_alwaysEmitIntoClient
  public func loadUnaligned<T: BitwiseCopyable>(
    fromByteOffset offset: Int = 0,
    as type: T.Type
  ) -> T {
    return unsafe Builtin.loadRaw((self + offset)._rawValue)
  }

  // to maintain our semantics where allocations can return
  // nil without crashing a program if heap memory is exhausted
  // this version must return optional
  // however it looks to me like this version is never used by XXSpan
  // so it's not harmful
  @inlinable
  @_alwaysEmitIntoClient
  public func loadUnaligned<T>(
    fromByteOffset offset: Int = 0,
    as type: T.Type
  ) -> T? {
    _debugPrecondition(
      _isPOD(T.self)
    )
    return unsafe _withUnprotectedUnsafeTemporaryAllocation(of: T.self, capacity: 1) {
      let temporary = unsafe $0.baseAddress._unsafelyUnwrappedUnchecked
      // not sure why this must be Int64??
      unsafe Builtin.int_memcpy_RawPointer_RawPointer_Int64(
        temporary._rawValue,
        (self + offset)._rawValue,
        UInt64(MemoryLayout<T>.size)._value,
        /*volatile:*/ false._value
      )
      return unsafe temporary.pointee
    }
  }

  @inlinable
  @_alwaysEmitIntoClient
  public func alignedUp<T: ~Copyable>(for type: T.Type) -> Self {
    let mask = UInt(Builtin.alignof(T.self)) &- 1
    let bits = (UInt(Builtin.ptrtoint_Word(_rawValue)) &+ mask) & ~mask
    _debugPrecondition(bits != 0)
    return .init(knownNotNilRawPointer: Builtin.inttoptr_Word(bits._builtinWordValue))
  }

  @inlinable
  @_alwaysEmitIntoClient
  public func alignedDown<T: ~Copyable>(for type: T.Type) -> Self {
    let mask = UInt(Builtin.alignof(T.self)) &- 1
    let bits = UInt(Builtin.ptrtoint_Word(_rawValue)) & ~mask
    _debugPrecondition(bits != 0)
    return .init(knownNotNilRawPointer:Builtin.inttoptr_Word(bits._builtinWordValue))
  }
}

extension UnsafeRawPointer: Strideable {
  // custom version for raw pointers
  @_transparent
  public func advanced(by n: Int) -> UnsafeRawPointer {
    return UnsafeRawPointer(Builtin.gepRaw_Word(_rawValue, n._builtinWordValue)) ?? self
  }
}



@frozen
@unsafe
public struct UnsafeMutableRawPointer: @unsafe _Pointer, BitwiseCopyable {
  
  public typealias Pointee = UInt8
  
  @safe
  public let _rawValue: Builtin.RawPointer

  @_transparent
  @safe
  public init?(_ _rawValue: Builtin.RawPointer) {
    guard Int(Builtin.ptrtoint_Word(_rawValue)) != 0 else {
      return nil
    }

    self._rawValue = _rawValue
  }

  @_transparent
  public init(knownNotNilRawPointer _rawValue: Builtin.RawPointer) {
    self._rawValue = _rawValue
  }

  @_transparent
  public init<T: ~Copyable>(_ other: UnsafeMutablePointer<T>) {
    _rawValue = other._rawValue
  }

  @_transparent
  public init?<T: ~Copyable>(_ other: UnsafeMutablePointer<T>?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  @_transparent
  public init(mutating other: UnsafeRawPointer) {
    _rawValue = other._rawValue
  }

  @_transparent
  public init?(mutating other: UnsafeRawPointer?) {
    guard let unwrapped = other else { return nil }
    _rawValue = unwrapped._rawValue
  }

  @inlinable
  public static func allocate(
    byteCount: Int, alignment: Int
  ) -> UnsafeMutableRawPointer? {
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
    var alignment = alignment
    if alignment <= _minAllocationAlignment() {
      alignment = 0
    }
    return UnsafeMutableRawPointer(Builtin.allocRaw(
        byteCount._builtinWordValue, alignment._builtinWordValue))
  }

  @inlinable
  public func deallocate() {
    // Passing zero alignment to the runtime forces "aligned
    // deallocation". Since allocation via `UnsafeMutable[Raw][Buffer]Pointer`
    // always uses the "aligned allocation" path, this ensures that the
    // runtime's allocation and deallocation paths are compatible.
    Builtin.deallocRaw(_rawValue, (-1 as Int)._builtinWordValue, (0 as Int)._builtinWordValue)
  }

  @_transparent
  @discardableResult
  public func bindMemory<T: ~Copyable>(
    to type: T.Type, capacity count: Int
  ) -> UnsafeMutablePointer<T> {
    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    return UnsafeMutablePointer<T>(knownNotNilRawPointer: _rawValue)
  }

  @_transparent
  public func assumingMemoryBound<T: ~Copyable>(to: T.Type) -> UnsafeMutablePointer<T> {
    return UnsafeMutablePointer<T>(knownNotNilRawPointer: _rawValue)
  }

  @_alwaysEmitIntoClient
  public func withMemoryRebound<T: ~Copyable, E: Error, Result: ~Copyable>(
    to type: T.Type,
    capacity count: Int,
    _ body: (_ pointer: UnsafeMutablePointer<T>) throws(E) -> Result
  ) throws(E) -> Result {
    _debugPrecondition(
      Int(bitPattern: self) & (MemoryLayout<T>.alignment-1) == 0
    )
    let binding = Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
    defer { Builtin.rebindMemory(_rawValue, binding) }
    return try unsafe body(.init(knownNotNilRawPointer: _rawValue))
  }

  @discardableResult
  @_alwaysEmitIntoClient
  public func initializeMemory<T: ~Copyable>(
    as type: T.Type, to value: consuming T
  ) -> UnsafeMutablePointer<T> {
    Builtin.bindMemory(_rawValue, (1)._builtinWordValue, type)
    Builtin.initialize(consume value, _rawValue)
    return unsafe UnsafeMutablePointer(knownNotNilRawPointer: _rawValue)
  }

  @inlinable
  @discardableResult
  public func initializeMemory<T>(
    as type: T.Type, repeating repeatedValue: T, count: Int
  ) -> UnsafeMutablePointer<T>? {
    _debugPrecondition(count >= 0)

    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    var nextPtr = self
    for _ in 0..<count {
      Builtin.initialize(repeatedValue, nextPtr._rawValue)
      nextPtr += MemoryLayout<T>.stride
    }
    return UnsafeMutablePointer(_rawValue)
  }

  @inlinable
  @discardableResult
  public func initializeMemory<T>(
    as type: T.Type, from source: UnsafePointer<T>, count: Int
  ) -> UnsafeMutablePointer<T>? {
    _debugPrecondition(
      count >= 0)
    _debugPrecondition(
      (UnsafeRawPointer(self + count * MemoryLayout<T>.stride)
        <= UnsafeRawPointer(source))
      || UnsafeRawPointer(source + count) <= UnsafeRawPointer(self))

    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    Builtin.copyArray(
      T.self, self._rawValue, source._rawValue, count._builtinWordValue)
    // This builtin is equivalent to:
    // for i in 0..<count {
    //   (self.assumingMemoryBound(to: T.self) + i).initialize(to: source[i])
    // }
    return UnsafeMutablePointer(_rawValue)
  }

  @inlinable
  @discardableResult
  public func moveInitializeMemory<T: ~Copyable>(
    as type: T.Type, from source: UnsafeMutablePointer<T>, count: Int
  ) -> UnsafeMutablePointer<T>? {
    _debugPrecondition(
      count >= 0)

    Builtin.bindMemory(_rawValue, count._builtinWordValue, type)
    if self < UnsafeMutableRawPointer(source)
       || self >= UnsafeMutableRawPointer(source + count) {
      // initialize forward from a disjoint or following overlapping range.
      Builtin.takeArrayFrontToBack(
        T.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // for i in 0..<count {
      //   (self.assumingMemoryBound(to: T.self) + i)
      //   .initialize(to: (source + i).move())
      // }
    }
    else {
      // initialize backward from a non-following overlapping range.
      Builtin.takeArrayBackToFront(
        T.self, self._rawValue, source._rawValue, count._builtinWordValue)
      // This builtin is equivalent to:
      // var src = source + count
      // var dst = self.assumingMemoryBound(to: T.self) + count
      // while dst != self {
      //   (--dst).initialize(to: (--src).move())
      // }
    }
    return UnsafeMutablePointer(_rawValue)
  }

  @inlinable
  public func load<T>(
    fromByteOffset offset: Int = 0,
    as type: T.Type
  ) -> T {
    unsafe _debugPrecondition(0 == (UInt(bitPattern: self + offset)
        & (UInt(MemoryLayout<T>.alignment) - 1)))

    let rawPointer = unsafe (self + offset)._rawValue

#if compiler(>=5.5) && $BuiltinAssumeAlignment
    let alignedPointer =
      Builtin.assumeAlignment(rawPointer,
                              MemoryLayout<T>.alignment._builtinWordValue)
    return Builtin.loadRaw(alignedPointer)
#else
    return Builtin.loadRaw(rawPointer)
#endif
  }

  @inlinable
  @_alwaysEmitIntoClient
  public func loadUnaligned<T: BitwiseCopyable>(
    fromByteOffset offset: Int = 0,
    as type: T.Type
  ) -> T {
    return unsafe Builtin.loadRaw((self + offset)._rawValue)
  }

  // to maintain our semantics where allocations can return
  // nil without crashing a program if heap memory is exhausted
  // this version must return optional
  // however it looks to me like this version is never used by XXSpan
  // so it's not harmful
  @inlinable
  @_alwaysEmitIntoClient
  public func loadUnaligned<T>(
    fromByteOffset offset: Int = 0,
    as type: T.Type
  ) -> T? {
    _debugPrecondition(
      _isPOD(T.self)
    )
    return unsafe _withUnprotectedUnsafeTemporaryAllocation(of: T.self, capacity: 1) {
      let temporary = unsafe $0.baseAddress._unsafelyUnwrappedUnchecked
      unsafe Builtin.int_memcpy_RawPointer_RawPointer_Int64(
        temporary._rawValue,
        (self + offset)._rawValue,
        UInt64(MemoryLayout<T>.size)._value,
        /*volatile:*/ false._value
      )
      return unsafe temporary.pointee
    }
  }

  @inlinable
  @_alwaysEmitIntoClient
  public func storeBytes<T: BitwiseCopyable>(
    of value: T, toByteOffset offset: Int = 0, as type: T.Type
  ) {
    unsafe Builtin.storeRaw(value, (self + offset)._rawValue)
  }

  @inlinable
  @_alwaysEmitIntoClient
  // This custom silgen name is chosen to not interfere with the old ABI
  @_silgen_name("_swift_se0349_UnsafeMutableRawPointer_storeBytes")
  public func storeBytes<T>(
    of value: T, toByteOffset offset: Int = 0, as type: T.Type
  ) {
    _debugPrecondition(
      _isPOD(T.self)
    )

    unsafe withUnsafePointer(to: value) { source in
      // FIXME: to be replaced by _memcpy when conversions are implemented.
      unsafe Builtin.int_memcpy_RawPointer_RawPointer_Int64(
        (self + offset)._rawValue,
        source._rawValue,
        UInt64(MemoryLayout<T>.size)._value,
        /*volatile:*/ false._value
      )
    }
  }
  
  @inlinable
  public func copyMemory(from source: UnsafeRawPointer, byteCount: Int) {
    _debugPrecondition(
      byteCount >= 0)

    _memmove(dest: self, src: source, size: UInt(byteCount))
  }
}

@available(*, unavailable)
extension UnsafeMutableRawPointer: Sendable {}

extension UnsafeMutableRawPointer: Strideable {
  // custom version for raw pointers
  @_transparent
  public func advanced(by n: Int) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(Builtin.gepRaw_Word(_rawValue, n._builtinWordValue)) ?? self
  }
}

extension UnsafeMutableRawPointer {
  /// Obtain the next pointer properly aligned to store a value of type `T`.
  ///
  /// If `self` is properly aligned for accessing `T`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - type: the type to be stored at the returned address.
  /// - Returns: a pointer properly aligned to store a value of type `T`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedUp<T: ~Copyable>(for type: T.Type) -> Self {
    let mask = UInt(Builtin.alignof(T.self)) &- 1
    let bits = (UInt(Builtin.ptrtoint_Word(_rawValue)) &+ mask) & ~mask
    _debugPrecondition(bits != 0)
    return .init(knownNotNilRawPointer: Builtin.inttoptr_Word(bits._builtinWordValue))
  }

  /// Obtain the preceding pointer properly aligned to store a value of type
  /// `T`.
  ///
  /// If `self` is properly aligned for accessing `T`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - type: the type to be stored at the returned address.
  /// - Returns: a pointer properly aligned to store a value of type `T`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedDown<T: ~Copyable>(for type: T.Type) -> Self {
    let mask = UInt(Builtin.alignof(T.self)) &- 1
    let bits = UInt(Builtin.ptrtoint_Word(_rawValue)) & ~mask
    _debugPrecondition(bits != 0)
    return .init(knownNotNilRawPointer: Builtin.inttoptr_Word(bits._builtinWordValue))
  }

  /// Obtain the next pointer whose bit pattern is a multiple of `alignment`.
  ///
  /// If the bit pattern of `self` is a multiple of `alignment`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - alignment: the alignment of the returned pointer, in bytes.
  ///     `alignment` must be a whole power of 2.
  /// - Returns: a pointer aligned to `alignment`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedUp(toMultipleOf alignment: Int) -> Self {
    let mask = UInt(alignment._builtinWordValue) &- 1
    _debugPrecondition(
      alignment > 0 && UInt(alignment._builtinWordValue) & mask == 0
    )
    let bits = (UInt(Builtin.ptrtoint_Word(_rawValue)) &+ mask) & ~mask
    _debugPrecondition(bits != 0)
    return .init(knownNotNilRawPointer: Builtin.inttoptr_Word(bits._builtinWordValue))
  }

  /// Obtain the preceding pointer whose bit pattern is a multiple of
  /// `alignment`.
  ///
  /// If the bit pattern of `self` is a multiple of `alignment`,
  /// this function returns `self`.
  ///
  /// - Parameters:
  ///   - alignment: the alignment of the returned pointer, in bytes.
  ///     `alignment` must be a whole power of 2.
  /// - Returns: a pointer aligned to `alignment`.
  @inlinable
  @_alwaysEmitIntoClient
  public func alignedDown(toMultipleOf alignment: Int) -> Self {
    let mask = UInt(alignment._builtinWordValue) &- 1
    _debugPrecondition(
      alignment > 0 && UInt(alignment._builtinWordValue) & mask == 0
    )
    let bits = UInt(Builtin.ptrtoint_Word(_rawValue)) & ~mask
    _debugPrecondition(bits != 0)
    return .init(knownNotNilRawPointer: Builtin.inttoptr_Word(bits._builtinWordValue))
  }
}

extension OpaquePointer {
  @_transparent
  public init(_ from: UnsafeMutableRawPointer) {
    self._rawValue = from._rawValue
  }

  @_transparent
  public init?(_ from: UnsafeMutableRawPointer?) {
    guard let unwrapped = from else { return nil }
    self._rawValue = unwrapped._rawValue
  }

  @_transparent
  public init(_ from: UnsafeRawPointer) {
    self._rawValue = from._rawValue
  }

  @_transparent
  public init?(_ from: UnsafeRawPointer?) {
    guard let unwrapped = from else { return nil }
    self._rawValue = unwrapped._rawValue
  }
}
