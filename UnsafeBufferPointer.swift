//===--- UnsafeBufferPointer.swift.gyb ------------------------*- swift -*-===//
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


// FIXME: rdar://18157434 - until this is fixed, this has to be fixed layout
// to avoid a hang in Foundation, which has the following setup:
// struct A { struct B { let x: UnsafeMutableBufferPointer<...> } let b: B }
@frozen // unsafe-performance
@unsafe
public struct UnsafeMutableBufferPointer<Element: ~Copyable>: Copyable {

  @usableFromInline
  @_preInverseGenerics
  @safe
  let _position: UnsafeMutablePointer<Element>?

  @_preInverseGenerics
  @safe
  public let count: Int

  @_alwaysEmitIntoClient
  internal init(
    @_nonEphemeral _uncheckedStart start: UnsafeMutablePointer<Element>?,
    count: Int
  ) {
    _position = unsafe start
    self.count = count
  }

  @inlinable // unsafe-performance
  @_preInverseGenerics
  public init(
    @_nonEphemeral start: UnsafeMutablePointer<Element>?, count: Int
  ) {
    _debugPrecondition(
      count >= 0)
    unsafe _debugPrecondition(
      count == 0 || start != nil)
    unsafe self.init(_uncheckedStart: start, count: _assumeNonNegative(count))
  }

}

extension UnsafeMutableBufferPointer {
  public typealias Iterator = UnsafeBufferPointer<Element>.Iterator
}

// FIXME: The ASTPrinter should print this synthesized conformance.
// rdar://140291657
extension UnsafeMutableBufferPointer: BitwiseCopyable where Element: ~Copyable {}

@available(*, unavailable)
extension UnsafeMutableBufferPointer: Sendable where Element: ~Copyable {}


extension UnsafeMutableBufferPointer: @unsafe Sequence {
  @inlinable // unsafe-performance
  public func makeIterator() -> Iterator {
    guard let start = _position else {
      return Iterator(_position: nil, _end: nil)
    }
    return Iterator(_position: start, _end: start + count)
  }

  @inlinable // unsafe-performance
  public func _copyContents(
    initializing destination: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    guard !isEmpty && !destination.isEmpty else { return (makeIterator(), 0) }
    let s = self.baseAddress._unsafelyUnwrappedUnchecked
    let d = destination.baseAddress._unsafelyUnwrappedUnchecked
    let n = Swift.min(destination.count, self.count)
    d.initialize(from: s, count: n)
    return (unsafe Iterator(_position: s + n, _end: s + count), n)
  }

  @inlinable
  @safe
  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try unsafe body(UnsafeBufferPointer(self))
  }
}

extension UnsafeMutableBufferPointer:
  @unsafe Collection,
  @unsafe MutableCollection,
  @unsafe BidirectionalCollection,
  @unsafe RandomAccessCollection
{
  public typealias Indices = Range<Int>
  public typealias SubSequence = Slice<UnsafeMutableBufferPointer<Element>>
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  public typealias Index = Int

  @_alwaysEmitIntoClient
  @_preInverseGenerics
  @safe
  public var isEmpty: Bool { count == 0 }

  @inlinable // unsafe-performance
  public var startIndex: Int { return 0 }

  @inlinable // unsafe-performance
  public var endIndex: Int { return count }

  @inlinable // unsafe-performance
  public func index(after i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + 1
  }

  @inlinable // unsafe-performance
  public func formIndex(after i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i += 1
  }

  @inlinable // unsafe-performance
  public func index(before i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i - 1
  }

  @inlinable // unsafe-performance
  public func formIndex(before i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i -= 1
  }

  @inlinable // unsafe-performance
  public func index(_ i: Int, offsetBy n: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + n
  }

  @inlinable // unsafe-performance
  public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    let l = limit - i
    if n > 0 ? l >= 0 && l < n : l <= 0 && n < l {
      return nil
    }
    return i + n
  }

  @inlinable // unsafe-performance
  public func distance(from start: Int, to end: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return end - start
  }

  @_alwaysEmitIntoClient
  public subscript(i: Int) -> Element {
    @_transparent
    unsafeAddress {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return unsafe UnsafePointer(_position._unsafelyUnwrappedUnchecked)! + i
    }
    @_transparent
    nonmutating unsafeMutableAddress {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return unsafe _position._unsafelyUnwrappedUnchecked + i
    }
  }

  @_alwaysEmitIntoClient
  internal subscript(_unchecked i: Int) -> Element {
    @_transparent
    unsafeAddress {
      _internalInvariant(i >= 0)
      _internalInvariant(i < endIndex)
      return unsafe UnsafePointer(_position._unsafelyUnwrappedUnchecked)! + i
    }
    nonmutating unsafeMutableAddress {
      _internalInvariant(i >= 0)
      _internalInvariant(i < endIndex)
      return unsafe _position._unsafelyUnwrappedUnchecked + i
    }
  }

  @inlinable // unsafe-performance
  public func swapAt(_ i: Int, _ j: Int) {
    guard i != j else { return }
    _debugPrecondition(i >= 0 && j >= 0)
    _debugPrecondition(i < endIndex && j < endIndex)
    let pi = (_position! + i)
    let pj = (_position! + j)
    let tmp = pi.move()
    pi.moveInitialize(from: pj, count: 1)
    pj.initialize(to: tmp)
  }
}


extension UnsafeMutableBufferPointer {
  @inlinable // unsafe-performance
  public func _failEarlyRangeCheck(_ index: Int, bounds: Range<Int>) {
    // NOTE: In release mode, this method is a no-op for performance reasons.
    _debugPrecondition(index >= bounds.lowerBound)
    _debugPrecondition(index < bounds.upperBound)
  }

  @inlinable // unsafe-performance
  public func _failEarlyRangeCheck(_ range: Range<Int>, bounds: Range<Int>) {
    // NOTE: In release mode, this method is a no-op for performance reasons.
    _debugPrecondition(range.lowerBound >= bounds.lowerBound)
    _debugPrecondition(range.upperBound <= bounds.upperBound)
  }

  @inlinable // unsafe-performance
  public var indices: Indices {
    return startIndex..<endIndex
  }

  @inlinable // unsafe-performance
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position._unsafelyUnwrappedUnchecked[i]
    }

    nonmutating _modify {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      yield &_position._unsafelyUnwrappedUnchecked[i]
    }
  }

  // Skip all debug and runtime checks

  @inlinable // unsafe-performance
  internal subscript(_unchecked i: Int) -> Element {
    get {
      _internalInvariant(i >= 0)
      _internalInvariant(i < endIndex)
      return _position._unsafelyUnwrappedUnchecked[i]
    }

    nonmutating _modify {
      _internalInvariant(i >= 0)
      _internalInvariant(i < endIndex)
      yield &_position._unsafelyUnwrappedUnchecked[i]
    }
  }

  @inlinable // unsafe-performance
  public subscript(bounds: Range<Int>)
    -> Slice<UnsafeMutableBufferPointer<Element>>
  {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(
        base: self, bounds: bounds)
    }

    nonmutating set {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      _debugPrecondition(bounds.count == newValue.count)

      // FIXME: swift-3-indexing-model: tests.
      if !newValue.isEmpty {
        (_position! + bounds.lowerBound).assign(
          from: newValue.base._position! + newValue.startIndex,
          count: newValue.count)
      }
    }
  }
}

extension UnsafeMutableBufferPointer: BitwiseCopyable where Element: ~Copyable {
  // @_alwaysEmitIntoClient
  // @safe
  // public func extracting(_ bounds: Range<Int>) -> Self {
  //   _precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,)
  //   guard let start = self.baseAddress else {
  //     return unsafe Self(start: nil, count: 0)
  //   }
  //   return unsafe Self(start: start + bounds.lowerBound, count: bounds.count)
  // }

  // @_alwaysEmitIntoClient
  // @safe
  // public func extracting(_ bounds: some RangeExpression<Int>) -> Self {
  //   extracting(bounds.relative(to: unsafe Range(uncheckedBounds: (0, count))))
  // }

  @unsafe
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public var span: Span<Element> {
    @lifetime(borrow self)
    @_transparent
    get {
      unsafe Span(_unsafeElements: self)
    }
  }

  @unsafe
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public var mutableSpan: MutableSpan<Element> {
    @lifetime(borrow self)
    @_transparent
    get {
      unsafe MutableSpan(_unsafeElements: self)
    }
  }
}

extension UnsafeMutableBufferPointer {
  // @_alwaysEmitIntoClient
  // internal init(
  //   @_nonEphemeral _uncheckedStart start: UnsafeMutablePointer<Element>?,
  //   count: Int
  // ) {
  //   _position = unsafe start
  //   self.count = count
  // }

  // @inlinable // unsafe-performance
  // @_preInverseGenerics
  // public init(@_nonEphemeral start: UnsafeMutablePointer<Element>?, count: Int) {
  //   _precondition(
  //     count >= 0)
  //   _precondition(
  //     count == 0 || start != nil)
  //   _position = start
  //   self.count = count
  // }

  @inlinable // unsafe-performance
  public init(_empty: ()) {
    _position = nil
    count = 0
  }

  @inlinable // unsafe-performance
  public init(mutating other: UnsafeBufferPointer<Element>) {
    _position = UnsafeMutablePointer<Element>(mutating: other._position)
    count = other.count
  }

  @inlinable
  public mutating func _withUnsafeMutableBufferPointerIfSupported<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try body(&self)
  }

  @inlinable
  public mutating func withContiguousMutableStorageIfAvailable<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    let (oldBase, oldCount) = (self.baseAddress, self.count)
    defer { 
      _debugPrecondition((oldBase, oldCount) == (self.baseAddress, self.count))
    } 
    return try body(&self)
  }

  // @inlinable
  // public func withContiguousStorageIfAvailable<R>(
  //   _ body: (UnsafeBufferPointer<Element>) throws -> R
  // ) rethrows -> R? {
  //   return try body(UnsafeBufferPointer(self))
  // }

  @inlinable // unsafe-performance
  public init(rebasing slice: Slice<UnsafeMutableBufferPointer<Element>>) {
    let base = slice.base.baseAddress?.advanced(by: slice.startIndex)
    self.init(start: base, count: slice.count)
  }
  
  @inlinable // unsafe-performance
  public func initialize(repeating repeatedValue: Element) {
    guard let dstBase = _position else {
      return
    }

    dstBase.initialize(repeating: repeatedValue, count: count)
  }
  
  @inlinable // unsafe-performance
  public func assign(repeating repeatedValue: Element) {
    guard let dstBase = _position else {
      return
    }

    dstBase.assign(repeating: repeatedValue, count: count)
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  @inlinable // unsafe-performance
  public func deallocate() {
    _position?.deallocate()
  }

  @inlinable // unsafe-performance
  public static func allocate(capacity count: Int) 
    -> UnsafeMutableBufferPointer<Element>? {
    let size = MemoryLayout<Element>.stride * count
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
    var align = Builtin.alignof(Element.self)
    if Int(align) <= _minAllocationAlignment() {
      align = Int(0)._builtinWordValue
    }

    let raw  = Builtin.allocRaw(size._builtinWordValue, align)

    guard Int(Builtin.ptrtoint_Word(raw)) != 0 else {
      return nil
    }

    Builtin.bindMemory(raw, count._builtinWordValue, Element.self)

    return UnsafeMutableBufferPointer<Element>(
      start: UnsafeMutablePointer(raw), count: count)
  }

  @_transparent // unsafe-performance
  public var baseAddress: UnsafeMutablePointer<Element>? {
    return _position
  }
}

extension UnsafeMutableBufferPointer {
  @_alwaysEmitIntoClient
  public func update<S: Sequence>(
    from source: S
  ) -> (unwritten: S.Iterator, index: Index) where S.Element == Element {
    var iterator = source.makeIterator()
    guard !self.isEmpty else { return (iterator, startIndex) }
    _internalInvariant(unsafe _position != nil)
    var index = startIndex
    while index < endIndex {
      guard let element = iterator.next() else { break }
      unsafe _position._unsafelyUnwrappedUnchecked[index] = element
      unsafe formIndex(after: &index)
    }
    return (iterator, index)
  }

  @_alwaysEmitIntoClient
  public func update(
    fromContentsOf source: some Collection<Element>
  ) -> Index {
    let count = source.withContiguousStorageIfAvailable {
      guard let sourceAddress = $0.baseAddress else {
        return 0
      }
      _precondition(
        $0.count <= self.count
      )
      unsafe baseAddress.unsafelyUnwrapped.update(from: sourceAddress, count: $0.count)
      return $0.count
    }
    if let count {
      return startIndex.advanced(by: count)
    }

    if self.isEmpty {
      _precondition(
        source.isEmpty
      )
      return startIndex
    }
    _internalInvariant(unsafe _position != nil)
    var iterator = source.makeIterator()
    var index = startIndex
    while let value = iterator.next() {
      guard index < endIndex else {
        _preconditionFailure()
        break
      }
      unsafe _position._unsafelyUnwrappedUnchecked[index] = value
      unsafe formIndex(after: &index)
    }
    return index
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {

  @_alwaysEmitIntoClient
  public func withMemoryRebound<T: ~Copyable, E: Error, Result: ~Copyable>(
    to type: T.Type,
    _ body: (_ buffer: UnsafeMutableBufferPointer<T>) throws(E) -> Result
  ) throws(E) -> Result {
    guard let base = _position?._rawValue else {
      return try unsafe body(.init(start: nil, count: 0))
    }

    _debugPrecondition(
      unsafe Int(bitPattern: .init(base)) & (MemoryLayout<T>.alignment-1) == 0
    )

    let newCount: Int
    if MemoryLayout<T>.stride == MemoryLayout<Element>.stride {
      newCount = count
    } else {
      newCount = count * MemoryLayout<Element>.stride / MemoryLayout<T>.stride
      _debugPrecondition(
        MemoryLayout<T>.stride > MemoryLayout<Element>.stride
        ? MemoryLayout<T>.stride % MemoryLayout<Element>.stride == 0
        : MemoryLayout<Element>.stride % MemoryLayout<T>.stride == 0
      )
    }
    let binding = Builtin.bindMemory(base, newCount._builtinWordValue, T.self)
    defer { Builtin.rebindMemory(base, binding) }
    return try unsafe body(unsafe .init(start: .init(base), count: newCount))
  }
}

extension UnsafeMutableBufferPointer {
  @_alwaysEmitIntoClient
  public func moveInitialize(fromContentsOf source: Self) -> Index {
    guard let sourceAddress = source.baseAddress, !source.isEmpty else {
      return startIndex
    }
    _precondition(
      source.count <= self.count
    )
    unsafe baseAddress.unsafelyUnwrapped.moveInitialize(
      from: sourceAddress, count: source.count
    )
    return startIndex.advanced(by: source.count)
  }
}

extension UnsafeMutableBufferPointer where Element: ~Copyable {
  public typealias _Index = Int

  @_alwaysEmitIntoClient
  public func moveUpdate(fromContentsOf source: Self) -> _Index { // was -> Index
    guard let sourceAddress = source.baseAddress, !source.isEmpty else {
      return startIndex
    }
    _precondition(
      source.count <= self.count
    )
    unsafe baseAddress.unsafelyUnwrapped.moveUpdate(
      from: sourceAddress, count: source.count
    )
    return startIndex.advanced(by: source.count)
  }

  @discardableResult
  @_alwaysEmitIntoClient
  public func deinitialize() -> UnsafeMutableRawBufferPointer {
    guard let rawValue = baseAddress?._rawValue
      else { return unsafe .init(start: nil, count: 0) }
    Builtin.destroyArray(Element.self, rawValue, count._builtinWordValue)
    return unsafe .init(start: UnsafeMutableRawPointer(rawValue),
                        count: count*MemoryLayout<Element>.stride)
   }

  @_alwaysEmitIntoClient
  public func initializeElement(at index: _Index, to value: consuming Element) {
    _debugPrecondition(startIndex <= index && index < endIndex)
    let p = unsafe baseAddress._unsafelyUnwrappedUnchecked.advanced(by: index)
    unsafe p.initialize(to: value)
  }

  @_alwaysEmitIntoClient
  public func moveElement(from index: _Index) -> Element {
    _debugPrecondition(startIndex <= index && index < endIndex)
    return unsafe baseAddress._unsafelyUnwrappedUnchecked.advanced(by: index).move()
  }

  @_alwaysEmitIntoClient
  public func deinitializeElement(at index: _Index) {
    _debugPrecondition(startIndex <= index && index < endIndex)
    let p = unsafe baseAddress._unsafelyUnwrappedUnchecked.advanced(by: index)
    unsafe p.deinitialize(count: 1)
  }
}

extension UnsafeMutableBufferPointer {
  @_alwaysEmitIntoClient
  public func moveInitialize(fromContentsOf source: Slice<Self>) -> Index {
    return unsafe moveInitialize(fromContentsOf: Self(rebasing: source))
  }

  @_alwaysEmitIntoClient
  public func moveUpdate(fromContentsOf source: Slice<Self>) -> Index {
    return unsafe moveUpdate(fromContentsOf: Self(rebasing: source))
  }
}

// FIXME: rdar://18157434 - until this is fixed, this has to be fixed layout
// to avoid a hang in Foundation, which has the following setup:
// struct A { struct B { let x: UnsafeMutableBufferPointer<...> } let b: B }
@frozen // unsafe-performance
public struct UnsafeBufferPointer<Element: ~Copyable>: Copyable {

  @usableFromInline
  let _position: UnsafePointer<Element>?

  public let count: Int

  @_alwaysEmitIntoClient
  internal init(
    @_nonEphemeral _uncheckedStart start: UnsafePointer<Element>?,
    count: Int
  ) {
    _position = unsafe start
    self.count = count
  }

  @inlinable // unsafe-performance
  public init(start: UnsafePointer<Element>?, count: Int) {
    _precondition(
      count >= 0)
    _precondition(
      count == 0 || start != nil)
    _position = start
    self.count = count
  }

  @inlinable // unsafe-performance
  public init(_empty: ()) {
    _position = nil
    count = 0
  }

  @inlinable // unsafe-performance
  public init(_ other: UnsafeMutableBufferPointer<Element>) {
    _position = unsafe UnsafePointer<Element>(other._position)
    count = other.count
  }
}

// FIXME: The ASTPrinter should print this synthesized conformance.
// rdar://140291657
extension UnsafeBufferPointer: BitwiseCopyable where Element: ~Copyable {}

@available(*, unavailable)
extension UnsafeBufferPointer: Sendable where Element: ~Copyable {}


extension UnsafeBufferPointer {
  @frozen // unsafe-performance
  public struct Iterator {
    @usableFromInline
    internal var _position, _end: UnsafePointer<Element>?

    @inlinable // unsafe-performance
    public init(_position: UnsafePointer<Element>?, _end: UnsafePointer<Element>?) {
        self._position = _position
        self._end = _end
    }
  }
}

@available(*, unavailable)
extension UnsafeBufferPointer.Iterator: Sendable {}

extension UnsafeBufferPointer.Iterator: @unsafe IteratorProtocol {
  @inlinable // unsafe-performance
  public mutating func next() -> Element? {
    guard let start = _position else {
      return nil
    }
    _internalInvariant(_end != nil)

    if start == _end._unsafelyUnwrappedUnchecked { return nil }

    let result = start.pointee
    _position  = start + 1
    return result
  }
}

extension UnsafeBufferPointer: Sequence {
  @inlinable // unsafe-performance
  public func makeIterator() -> Iterator {
    guard let start = _position else {
      return Iterator(_position: nil, _end: nil)
    }
    return Iterator(_position: start, _end: start + count)
  }

  @inlinable // unsafe-performance
  public func _copyContents(
    initializing destination: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    guard !isEmpty && !destination.isEmpty else { return (makeIterator(), 0) }
    let s = self.baseAddress._unsafelyUnwrappedUnchecked
    let d = destination.baseAddress._unsafelyUnwrappedUnchecked
    let n = Swift.min(destination.count, self.count)
    d.initialize(from: s, count: n)
    return (Iterator(_position: s + n, _end: s + count), n)
  }

  // @inlinable
  // @safe
  // public func withContiguousStorageIfAvailable<R>(
  //   _ body: (UnsafeBufferPointer<Element>) throws -> R
  // ) rethrows -> R? {
  //   return try unsafe body(self)
  // }
}

extension UnsafeBufferPointer: Collection, RandomAccessCollection {
  public typealias Indices = Range<Int>
  public typealias SubSequence = Slice<UnsafeBufferPointer<Element>>
}

extension UnsafeBufferPointer where Element: ~Copyable {
  public typealias Index = Int

  @_alwaysEmitIntoClient
  @_preInverseGenerics
  @safe
  public var isEmpty: Bool { count == 0 }

  @inlinable // unsafe-performance
  public var startIndex: Int { return 0 }

  @inlinable // unsafe-performance
  public var endIndex: Int { return count }

  @inlinable // unsafe-performance
  public func index(after i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + 1
  }

  @inlinable // unsafe-performance
  public func formIndex(after i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i += 1
  }

  @inlinable // unsafe-performance
  public func index(before i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i - 1
  }

  @inlinable // unsafe-performance
  public func formIndex(before i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i -= 1
  }

  @inlinable // unsafe-performance
  public func index(_ i: Int, offsetBy n: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + n
  }

  @inlinable // unsafe-performance
  public func index(_ i: Int, offsetBy n: Int, limitedBy limit: Int) -> Int? {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    let l = limit - i
    if n > 0 ? l >= 0 && l < n : l <= 0 && n < l {
      return nil
    }
    return i + n
  }

  @inlinable // unsafe-performance
  public func distance(from start: Int, to end: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for UnsafeBufferPointer performance. The
    // optimizer is not capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return end - start
  }

  @_alwaysEmitIntoClient
  public subscript(i: Int) -> Element {
    @_transparent
    unsafeAddress {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return unsafe UnsafePointer(_position._unsafelyUnwrappedUnchecked)! + i
    }
  }

  @_alwaysEmitIntoClient
  internal subscript(_unchecked i: Int) -> Element {
    @_transparent
    unsafeAddress {
      _internalInvariant(i >= 0)
      _internalInvariant(i < endIndex)
      return unsafe UnsafePointer(_position._unsafelyUnwrappedUnchecked)! + i
    }
  }
}

extension UnsafeBufferPointer {
  @inlinable // unsafe-performance
  public func _failEarlyRangeCheck(_ index: Int, bounds: Range<Int>) {
    // NOTE: In release mode, this method is a no-op for performance reasons.
    _debugPrecondition(index >= bounds.lowerBound)
    _debugPrecondition(index < bounds.upperBound)
  }

  @inlinable // unsafe-performance
  public func _failEarlyRangeCheck(_ range: Range<Int>, bounds: Range<Int>) {
    // NOTE: In release mode, this method is a no-op for performance reasons.
    _debugPrecondition(range.lowerBound >= bounds.lowerBound)
    _debugPrecondition(range.upperBound <= bounds.upperBound)
  }

  @inlinable // unsafe-performance
  public var indices: Indices {
    return startIndex..<endIndex
  }

  @inlinable // unsafe-performance
  public subscript(i: Int) -> Element {
    get {
      _debugPrecondition(i >= 0)
      _debugPrecondition(i < endIndex)
      return _position._unsafelyUnwrappedUnchecked[i]
    }
  }

  // Skip all debug and runtime checks

  @inlinable // unsafe-performance
  internal subscript(_unchecked i: Int) -> Element {
    get {
      _internalInvariant(i >= 0)
      _internalInvariant(i < endIndex)
      return _position._unsafelyUnwrappedUnchecked[i]
    }
  }

  @inlinable // unsafe-performance
  public subscript(bounds: Range<Int>)
    -> Slice<UnsafeBufferPointer<Element>>
  {
    get {
      _debugPrecondition(bounds.lowerBound >= startIndex)
      _debugPrecondition(bounds.upperBound <= endIndex)
      return Slice(
        base: self, bounds: bounds)
    }
  }
}

extension UnsafeBufferPointer: BitwiseCopyable where Element: ~Copyable {
  @_alwaysEmitIntoClient
  @safe
  public func extracting(_ bounds: Range<Int>) -> Self {
    _precondition(bounds.lowerBound >= 0 && bounds.upperBound <= count,)
    guard let start = self.baseAddress else {
      return unsafe Self(start: nil, count: 0)
    }
    return unsafe Self(start: start + bounds.lowerBound, count: bounds.count)
  }

  @_alwaysEmitIntoClient
  @safe
  public func extracting(_ bounds: some RangeExpression<Int>) -> Self {
    extracting(bounds.relative(to: unsafe Range(uncheckedBounds: (0, count))))
  }

  @unsafe
  @available(SwiftStdlib 6.2, *)
  @_alwaysEmitIntoClient
  public var span: Span<Element> {
    @lifetime(borrow self)
    @_transparent
    get {
      unsafe Span(_unsafeElements: self)
    }
  }
}

extension UnsafeBufferPointer where Element: ~Copyable {
  @inlinable
  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try body(self)
  }
}

extension UnsafeBufferPointer {
  @inlinable // unsafe-performance
  public init(rebasing slice: Slice<UnsafeBufferPointer<Element>>) {
    let base = slice.base.baseAddress?.advanced(by: slice.startIndex)
    self.init(start: base, count: slice.count)
  }

  //TODO: - this breaks...
  @inlinable // unsafe-performance
  public init(rebasing slice: Slice<UnsafeMutableBufferPointer<Element>>) {
    let base = slice.base.baseAddress?.advanced(by: slice.startIndex)
    self.init(start: base, count: slice.count)
  }
}

extension UnsafeBufferPointer where Element: ~Copyable {
  @inlinable // unsafe-performance
  public func deallocate() {
    _position?.deallocate()
  }

  @inlinable // unsafe-performance
  public func withMemoryRebound<T, Result>(
    to type: T.Type, _ body: (UnsafeBufferPointer<T>) throws -> Result
  ) rethrows -> Result {
    if let base = _position {
      _debugPrecondition(MemoryLayout<Element>.stride == MemoryLayout<T>.stride)
      Builtin.bindMemory(base._rawValue, count._builtinWordValue, T.self)
      defer {
        Builtin.bindMemory(base._rawValue, count._builtinWordValue, Element.self)
      }

      return try body(UnsafeBufferPointer<T>(
        start: UnsafePointer<T>(base._rawValue), count: count))
    }
    else {
      return try body(UnsafeBufferPointer<T>(start: nil, count: 0))
    }
  }

  @_transparent // unsafe-performance
  public var baseAddress: UnsafePointer<Element>? {
    return _position
  }
}

extension UnsafeMutableBufferPointer {
  @inlinable // unsafe-performance
  public func initialize<S: Sequence>(from source: S) -> (S.Iterator, Index)
    where S.Element == Element {
    return source._copyContents(initializing: self)
  }
}

// Local Variables:
// eval: (read-only-mode 1)
// End:
