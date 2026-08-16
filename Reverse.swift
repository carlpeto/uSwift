//===--- Reverse.swift - Sequence and collection reversal -----------------===//
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

extension MutableCollection where Self: BidirectionalCollection {
  @inlinable // protocol-only
  public mutating func reverse() {
    if isEmpty { return }
    var f = startIndex
    var l = index(before: endIndex)
    while f < l {
      swapAt(f, l)
      formIndex(after: &f)
      formIndex(before: &l)
    }
  }
}

@frozen
public struct ReversedCollection<Base: BidirectionalCollection> {
  public let _base: Base

  @inlinable
  internal init(_base: Base) {
    self._base = _base
  }
}

extension ReversedCollection {
  // An iterator that can be much faster than the iterator of a reversed slice.
  @frozen
  public struct Iterator {
    @usableFromInline
    internal let _base: Base
    @usableFromInline
    internal var _position: Base.Index

    @inlinable
    @inline(__always)
    init(_base: Base) {
      self._base = _base
      self._position = _base.endIndex
    }
  }
}

extension ReversedCollection.Iterator: IteratorProtocol, Sequence {
  public typealias Element = Base.Element
  
  @inlinable
  @inline(__always)
  public mutating func next() -> Element? {
    guard _fastPath(_position != _base.startIndex) else { return nil }
    _base.formIndex(before: &_position)
    return _base[_position]
  }
}

extension ReversedCollection: Sequence {
  public typealias Element = Base.Element

  @inlinable
  @inline(__always)
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_base: _base)
  }
}

extension ReversedCollection {
  @frozen
  public struct Index {
    public let base: Base.Index

    @inlinable
    public init(_ base: Base.Index) {
      self.base = base
    }
  }
}

extension ReversedCollection.Index: Comparable {
  @inlinable
  public static func == (
    lhs: ReversedCollection<Base>.Index,
    rhs: ReversedCollection<Base>.Index
  ) -> Bool {
    // Note ReversedIndex has inverted logic compared to base Base.Index
    return lhs.base == rhs.base
  }

  @inlinable
  public static func < (
    lhs: ReversedCollection<Base>.Index,
    rhs: ReversedCollection<Base>.Index
  ) -> Bool {
    // Note ReversedIndex has inverted logic compared to base Base.Index
    return lhs.base > rhs.base
  }
}

extension ReversedCollection.Index: Hashable where Base.Index: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(base)
  }
}

extension ReversedCollection: BidirectionalCollection {  
  @inlinable
  public var startIndex: Index {
    return Index(_base.endIndex)
  }

  @inlinable
  public var endIndex: Index {
    return Index(_base.startIndex)
  }

  @inlinable
  public func index(after i: Index) -> Index {
    return Index(_base.index(before: i.base))
  }

  @inlinable
  public func index(before i: Index) -> Index {
    return Index(_base.index(after: i.base))
  }

  @inlinable
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    // FIXME: swift-3-indexing-model: `-n` can trap on Int.min.
    return Index(_base.index(i.base, offsetBy: -n))
  }

  @inlinable
  public func index(
    _ i: Index, offsetBy n: Int, limitedBy limit: Index
  ) -> Index? {
    // FIXME: swift-3-indexing-model: `-n` can trap on Int.min.
    return _base.index(i.base, offsetBy: -n, limitedBy: limit.base)
                .map(Index.init)
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    return _base.distance(from: end.base, to: start.base)
  }

  @inlinable
  public subscript(position: Index) -> Element {
    return _base[_base.index(before: position.base)]
  }
}

extension ReversedCollection: RandomAccessCollection where Base: RandomAccessCollection { }

extension ReversedCollection {
  @inlinable
  @available(swift, introduced: 4.2)
  public __consuming func reversed() -> Base {
    return _base
  }
}

extension BidirectionalCollection {
  @inlinable
  public __consuming func reversed() -> ReversedCollection<Self> {
    return ReversedCollection(_base: self)
  }
}
