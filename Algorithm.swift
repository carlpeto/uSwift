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

@inlinable // protocol-only
public func min<T : Comparable>(_ x: T, _ y: T) -> T {
  // In case `x == y` we pick `x`.
  // This preserves any pre-existing order in case `T` has identity,
  // which is important for e.g. the stability of sorting algorithms.
  // `(min(x, y), max(x, y))` should return `(x, y)` in case `x == y`.
  return y < x ? y : x
}

// @inlinable // protocol-only
// public func min<T : Comparable>(_ x: T, _ y: T, _ z: T, _ rest: T...) -> T {
//   var minValue = min(min(x, y), z)
//   // In case `value == minValue`, we pick `minValue`. See min(_:_:).
//   for value in rest where value < minValue {
//     minValue = value
//   }
//   return minValue
// }

@inlinable // protocol-only
public func max<T : Comparable>(_ x: T, _ y: T) -> T {
  // In case `x == y`, we pick `y`. See min(_:_:).
  return y >= x ? y : x
}

// @inlinable // protocol-only
// public func max<T : Comparable>(_ x: T, _ y: T, _ z: T, _ rest: T...) -> T {
//   var maxValue = max(max(x, y), z)
//   // In case `value == maxValue`, we pick `value`. See min(_:_:).
//   for value in rest where value >= maxValue {
//     maxValue = value
//   }
//   return maxValue
// }

@frozen
public struct EnumeratedSequence<Base: Sequence> {
  @usableFromInline
  internal var _base: Base

  @inlinable
  internal init(_base: Base) {
    self._base = _base
  }
}

extension EnumeratedSequence {
  @frozen
  public struct Iterator {
    @usableFromInline
    internal var _base: Base.Iterator
    @usableFromInline
    internal var _count: Int

    @inlinable
    internal init(_base: Base.Iterator) {
      self._base = _base
      self._count = 0
    }
  }
}

extension EnumeratedSequence.Iterator: IteratorProtocol, Sequence {
  public typealias Element = (offset: Int, element: Base.Element)

  @inlinable
  public mutating func next() -> Element? {
    guard let b = _base.next() else { return nil }
    let result = (offset: _count, element: b)
    _count += 1 
    return result
  }
}

extension EnumeratedSequence: Sequence {
  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_base: _base.makeIterator())
  }
}
