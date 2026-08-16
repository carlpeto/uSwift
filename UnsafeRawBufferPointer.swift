//===--- UnsafeRawBufferPointer.swift.gyb ---------------------*- swift -*-===//
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
public struct UnsafeMutableRawBufferPointer {
  @usableFromInline
  internal let _position, _end: UnsafeMutableRawPointer?
}

extension UnsafeMutableRawBufferPointer {
  public typealias Iterator = UnsafeRawBufferPointer.Iterator
}

extension UnsafeMutableRawBufferPointer: Sequence {
  public typealias SubSequence = Slice<UnsafeMutableRawBufferPointer>

  @inlinable
  public func makeIterator() -> Iterator {
    return Iterator(_position: _position, _end: _end)
  }
}

extension UnsafeMutableRawBufferPointer: MutableCollection {
  // TODO: Specialize `index` and `formIndex` and
  // `_failEarlyRangeCheck` as in `UnsafeBufferPointer`.
  public typealias Element = UInt8
  public typealias Index = Int
  public typealias Indices = Range<Int>

  @inlinable
  public var startIndex: Index {
    return 0
  }

  @inlinable
  public var endIndex: Index {
    return count
  }

  @inlinable
  public var indices: Indices {
    return startIndex..<endIndex
  }

  @inlinable
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position._unsafelyUnwrappedUnchecked.load(fromByteOffset: i, as: UInt8.self)
    }
    nonmutating set {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      _position._unsafelyUnwrappedUnchecked.storeBytes(of: newValue, toByteOffset: i, as: UInt8.self)
    }
  }

  @inlinable
  public subscript(bounds: Range<Int>) -> SubSequence {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(base: self, bounds: bounds)
    }
    nonmutating set {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      _debugPrecondition(bounds.count == newValue.count)

      if !newValue.isEmpty {
        (baseAddress! + bounds.lowerBound).copyMemory(
          from: newValue.base.baseAddress! + newValue.startIndex,
          byteCount: newValue.count)
      }
    }
  }

  @inlinable
  public func swapAt(_ i: Int, _ j: Int) {
    guard i != j else { return }
    _debugPrecondition(i >= 0 && j >= 0)
    _debugPrecondition(i < endIndex && j < endIndex)
    let pi = (_position! + i)
    let pj = (_position! + j)
    let tmp = pi.load(fromByteOffset: 0, as: UInt8.self)
    pi.copyMemory(from: pj, byteCount: MemoryLayout<UInt8>.size)
    pj.storeBytes(of: tmp, toByteOffset: 0, as: UInt8.self)
  }

  @inlinable
  public var count: Int {
    if let pos = _position {
      return _end! - pos
    }
    return 0
  }
}

extension UnsafeMutableRawBufferPointer: RandomAccessCollection { }

extension UnsafeMutableRawBufferPointer {
  @inlinable
  public static func allocate(
    byteCount: Int, alignment: Int
  ) -> UnsafeMutableRawBufferPointer? {
    guard let base = UnsafeMutableRawPointer.allocate(
      byteCount: byteCount, alignment: alignment) else {
      return nil
    }

    return UnsafeMutableRawBufferPointer(start: base, count: byteCount)
  }

  @inlinable
  public func deallocate() {
    _position?.deallocate()
  }

  @inlinable
  public func load<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    _debugPrecondition(offset >= 0)
    _debugPrecondition(offset + MemoryLayout<T>.size <= self.count)
    return baseAddress!.load(fromByteOffset: offset, as: T.self)
  }

  @inlinable
  public func storeBytes<T>(
    of value: T, toByteOffset offset: Int = 0, as: T.Type
  ) {
    _debugPrecondition(offset >= 0)
    _debugPrecondition(offset + MemoryLayout<T>.size <= self.count)

    baseAddress!.storeBytes(of: value, toByteOffset: offset, as: T.self)
  }

  @inlinable
  public func copyMemory(from source: UnsafeRawBufferPointer) {
    _debugPrecondition(source.count <= self.count)
    baseAddress?.copyMemory(from: source.baseAddress!, byteCount: source.count)
  }

  @inlinable
  public func copyBytes<C : Collection>(from source: C
  ) where C.Element == UInt8 {
    _debugPrecondition(source.count <= self.count)
    guard let position = _position else {
      return
    }
    for (index, byteValue) in source.enumerated() {
      position.storeBytes(
        of: byteValue, toByteOffset: index, as: UInt8.self)
    }
  }

  @inlinable
  public init(start: UnsafeMutableRawPointer?, count: Int) {
    _precondition(count >= 0)
    _precondition(count == 0 || start != nil)
    _position = start
    _end = start.map { $0 + count }
  }

  @inlinable
  public init(_ bytes: UnsafeMutableRawBufferPointer) {
    self.init(start: bytes.baseAddress, count: bytes.count)
  }

  @inlinable
  public init(mutating bytes: UnsafeRawBufferPointer) {
    self.init(start: UnsafeMutableRawPointer(mutating: bytes.baseAddress),
      count: bytes.count)
  }

  @inlinable
  public init<T>(_ buffer: UnsafeMutableBufferPointer<T>) {
    self.init(start: buffer.baseAddress,
      count: buffer.count * MemoryLayout<T>.stride)
  }



  @inlinable
  public init(rebasing slice: Slice<UnsafeMutableRawBufferPointer>) {
    let base = slice.base.baseAddress?.advanced(by: slice.startIndex)
    self.init(start: base, count: slice.count)
  }

  @inlinable
  public var baseAddress: UnsafeMutableRawPointer? {
    return _position
  }

  
  @inlinable
  @discardableResult
  public func initializeMemory<T>(as type: T.Type, repeating repeatedValue: T)
    -> UnsafeMutableBufferPointer<T> {
    guard let base = _position else {
      return UnsafeMutableBufferPointer<T>(start: nil, count: 0)
    }
    
    let count = (_end! - base) / MemoryLayout<T>.stride
    let typed = base.initializeMemory(
      as: type, repeating: repeatedValue, count: count)
    return UnsafeMutableBufferPointer<T>(start: typed, count: count)
  }

  @inlinable
  public func initializeMemory<S: Sequence>(
    as type: S.Element.Type, from source: S
  ) -> (unwritten: S.Iterator, initialized: UnsafeMutableBufferPointer<S.Element>) {
    // TODO: Optimize where `C` is a `ContiguousArrayBuffer`.

    var it = source.makeIterator()
    var idx = startIndex
    let elementStride = MemoryLayout<S.Element>.stride
    
    // This has to be a debug precondition due to the cost of walking over some collections.
    _debugPrecondition(source.underestimatedCount <= (count / elementStride))
    guard let base = baseAddress else {
      // this can be a precondition since only an invalid argument should be costly
      _precondition(source.underestimatedCount == 0)
      return (it, UnsafeMutableBufferPointer(start: nil, count: 0))
    }  

    for p in stride(from: base, 
      // only advance to as far as the last element that will fit
      to: base + count - elementStride + 1, 
      by: elementStride
    ) {
      // underflow is permitted -- e.g. a sequence into
      // the spare capacity of an Array buffer
      guard let x = it.next() else { break }
      p.initializeMemory(as: S.Element.self, repeating: x, count: 1)
      formIndex(&idx, offsetBy: elementStride)
    }

    return (it, UnsafeMutableBufferPointer(
                  start: base.assumingMemoryBound(to: S.Element.self), 
                  count: idx / elementStride))
  }

  @_transparent
  @discardableResult
  public func bindMemory<T>(
    to type: T.Type
  ) -> UnsafeMutableBufferPointer<T> {
    guard let base = _position else {
      return UnsafeMutableBufferPointer<T>(start: nil, count: 0)
    }

    let capacity = count / MemoryLayout<T>.stride
    Builtin.bindMemory(base._rawValue, capacity._builtinWordValue, type)
    return UnsafeMutableBufferPointer<T>(
      start: UnsafeMutablePointer<T>(base._rawValue), count: capacity)
  }
}

extension UnsafeMutableRawBufferPointer {
  @available(*, unavailable, 
    message: "use 'UnsafeMutableRawBufferPointer(rebasing:)' to convert a slice into a zero-based raw buffer.")
  public subscript(bounds: Range<Int>) -> UnsafeMutableRawBufferPointer {
    get { return UnsafeMutableRawBufferPointer(start: nil, count: 0) }
    nonmutating set {}
  }

  @available(*, unavailable, 
    message: "use 'UnsafeRawBufferPointer(rebasing:)' to convert a slice into a zero-based raw buffer.")
  public subscript(bounds: Range<Int>) -> UnsafeRawBufferPointer {
    get { return UnsafeRawBufferPointer(start: nil, count: 0) }
    nonmutating set {}
  }
}


@frozen
public struct UnsafeRawBufferPointer {
  @usableFromInline
  internal let _position, _end: UnsafeRawPointer?
}

extension UnsafeRawBufferPointer {
  @frozen
  public struct Iterator {
    @usableFromInline
    internal var _position, _end: UnsafeRawPointer?

    @inlinable
    internal init(_position: UnsafeRawPointer?, _end: UnsafeRawPointer?) {
      self._position = _position
      self._end = _end
    }
  }
}

extension UnsafeRawBufferPointer.Iterator: IteratorProtocol, Sequence {
  @inlinable
  public mutating func next() -> UInt8? {
    if _position == _end { return nil }

    let result = _position!.load(as: UInt8.self)
    _position! += 1
    return result
  }
}

extension UnsafeRawBufferPointer: Sequence {
  public typealias SubSequence = Slice<UnsafeRawBufferPointer>

  @inlinable
  public func makeIterator() -> Iterator {
    return Iterator(_position: _position, _end: _end)
  }
}

extension UnsafeRawBufferPointer: Collection {
  // TODO: Specialize `index` and `formIndex` and
  // `_failEarlyRangeCheck` as in `UnsafeBufferPointer`.
  public typealias Element = UInt8
  public typealias Index = Int
  public typealias Indices = Range<Int>

  @inlinable
  public var startIndex: Index {
    return 0
  }

  @inlinable
  public var endIndex: Index {
    return count
  }

  @inlinable
  public var indices: Indices {
    return startIndex..<endIndex
  }

  @inlinable
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position._unsafelyUnwrappedUnchecked.load(fromByteOffset: i, as: UInt8.self)
    }
  }

  @inlinable
  public subscript(bounds: Range<Int>) -> SubSequence {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(base: self, bounds: bounds)
    }
  }

  @inlinable
  public var count: Int {
    if let pos = _position {
      return _end! - pos
    }
    return 0
  }
}

extension UnsafeRawBufferPointer: RandomAccessCollection { }

extension UnsafeRawBufferPointer {

  @inlinable
  public func deallocate() {
    _position?.deallocate()
  }

  @inlinable
  public func load<T>(fromByteOffset offset: Int = 0, as type: T.Type) -> T {
    _debugPrecondition(offset >= 0)
    _debugPrecondition(offset + MemoryLayout<T>.size <= self.count)
    return baseAddress!.load(fromByteOffset: offset, as: T.self)
  }


  @inlinable
  public init(start: UnsafeRawPointer?, count: Int) {
    _precondition(count >= 0)
    _precondition(count == 0 || start != nil)
    _position = start
    _end = start.map { $0 + count }
  }

  @inlinable
  public init(_ bytes: UnsafeMutableRawBufferPointer) {
    self.init(start: bytes.baseAddress, count: bytes.count)
  }

  @inlinable
  public init(_ bytes: UnsafeRawBufferPointer) {
    self.init(start: bytes.baseAddress, count: bytes.count)
  }

  @inlinable
  public init<T>(_ buffer: UnsafeMutableBufferPointer<T>) {
    self.init(start: buffer.baseAddress,
      count: buffer.count * MemoryLayout<T>.stride)
  }

  @inlinable
  public init<T>(_ buffer: UnsafeBufferPointer<T>) {
    self.init(start: buffer.baseAddress,
      count: buffer.count * MemoryLayout<T>.stride)
  }

  @inlinable
  public init(rebasing slice: Slice<UnsafeRawBufferPointer>) {
    let base = slice.base.baseAddress?.advanced(by: slice.startIndex)
    self.init(start: base, count: slice.count)
  }

  @inlinable
  public init(rebasing slice: Slice<UnsafeMutableRawBufferPointer>) {
    let base = slice.base.baseAddress?.advanced(by: slice.startIndex)
    self.init(start: base, count: slice.count)
  }

  @inlinable
  public var baseAddress: UnsafeRawPointer? {
    return _position
  }


  @_transparent
  @discardableResult
  public func bindMemory<T>(
    to type: T.Type
  ) -> UnsafeBufferPointer<T> {
    guard let base = _position else {
      return UnsafeBufferPointer<T>(start: nil, count: 0)
    }

    let capacity = count / MemoryLayout<T>.stride
    Builtin.bindMemory(base._rawValue, capacity._builtinWordValue, type)
    return UnsafeBufferPointer<T>(
      start: UnsafePointer<T>(base._rawValue), count: capacity)
  }
}

extension UnsafeRawBufferPointer {
  @available(*, unavailable, 
    message: "use 'UnsafeRawBufferPointer(rebasing:)' to convert a slice into a zero-based raw buffer.")
  public subscript(bounds: Range<Int>) -> UnsafeRawBufferPointer {
    get { return UnsafeRawBufferPointer(start: nil, count: 0) }
  }

}


@inlinable
public func withUnsafeMutableBytes<T, Result>(
  of value: inout T,
  _ body: (UnsafeMutableRawBufferPointer) throws -> Result
) rethrows -> Result
{
  return try withUnsafeMutablePointer(to: &value) {
    return try body(UnsafeMutableRawBufferPointer(
        start: $0, count: MemoryLayout<T>.size))
  }
}

@inlinable
public func withUnsafeBytes<T, Result>(
  of value: inout T,
  _ body: (UnsafeRawBufferPointer) throws -> Result
) rethrows -> Result
{
  return try withUnsafePointer(to: &value) {
    try body(UnsafeRawBufferPointer(start: $0, count: MemoryLayout<T>.size))
  }
}

@inlinable
public func withUnsafeBytes<T, Result>(
  of value: T,
  _ body: (UnsafeRawBufferPointer) throws -> Result
) rethrows -> Result {
  let addr = UnsafeRawPointer(Builtin.addressOfBorrow(value))
  let buffer = UnsafeRawBufferPointer(start: addr, count: MemoryLayout<T>.size)
  return try body(buffer)
}

// Local Variables:
// eval: (read-only-mode 1)
// End:
