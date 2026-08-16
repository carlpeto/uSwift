//===--- EmptyCollection.swift - A collection with no elements ------------===//
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
//  Sometimes an operation is best expressed in terms of some other,
//  larger operation where one of the parameters is an empty
//  collection.  For example, we can erase elements from an Array by
//  replacing a subrange with the empty collection.
//
//===----------------------------------------------------------------------===//

@frozen // trivial-implementation
public struct EmptyCollection<Element> {
  // no properties

  @inlinable // trivial-implementation
  public init() {}
}

extension EmptyCollection {
  @frozen // trivial-implementation
  public struct Iterator {
    // no properties
  
    @inlinable // trivial-implementation
    public init() {}
  }  
}

extension EmptyCollection.Iterator: IteratorProtocol, Sequence {
  @inlinable // trivial-implementation
  public mutating func next() -> Element? {
    return nil
  }
}

extension EmptyCollection: Sequence {
  @inlinable // trivial-implementation
  public func makeIterator() -> Iterator {
    return Iterator()
  }
}

extension EmptyCollection: RandomAccessCollection, MutableCollection {
  public typealias Index = Int
  public typealias Indices = Range<Int>
  public typealias SubSequence = EmptyCollection<Element>

  @inlinable // trivial-implementation
  public var startIndex: Index {
    return 0
  }

  @inlinable // trivial-implementation
  public var endIndex: Index {
    return 0
  }

  @inlinable // trivial-implementation
  public func index(after i: Index) -> Index {
    _precondition(false)
    return 0
  }

  @inlinable // trivial-implementation
  public func index(before i: Index) -> Index {
    _precondition(false)
    return 0
  }

  @inlinable // trivial-implementation
  public subscript(position: Index) -> Element {
    get {
      preconditionFailure()
    }
    set {
      _precondition(false)
    }
  }

  @inlinable // trivial-implementation
  public subscript(bounds: Range<Index>) -> SubSequence {
    get {
      _debugPrecondition(bounds.lowerBound == 0 && bounds.upperBound == 0)
      return self
    }
    set {
      _debugPrecondition(bounds.lowerBound == 0 && bounds.upperBound == 0)
    }
  }

  @inlinable // trivial-implementation
  public var count: Int {
    return 0
  }

  @inlinable // trivial-implementation
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    _debugPrecondition(i == startIndex && n == 0)
    return i
  }

  @inlinable // trivial-implementation
  public func index(
    _ i: Index, offsetBy n: Int, limitedBy limit: Index
  ) -> Index? {
    _debugPrecondition(i == startIndex && limit == startIndex)
    return n == 0 ? i : nil
  }

  @inlinable // trivial-implementation
  public func distance(from start: Index, to end: Index) -> Int {
    _debugPrecondition(start == 0)
    _debugPrecondition(end == 0)
    return 0
  }

  @inlinable // trivial-implementation
  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    _debugPrecondition(index == 0)
    _debugPrecondition(bounds == indices)
  }

  @inlinable // trivial-implementation
  public func _failEarlyRangeCheck(
    _ range: Range<Index>, bounds: Range<Index>
  ) {
    _debugPrecondition(range == indices)
    _debugPrecondition(bounds == indices)
  }
}

extension EmptyCollection : Equatable {
  @inlinable // trivial-implementation
  public static func == (
    lhs: EmptyCollection<Element>, rhs: EmptyCollection<Element>
  ) -> Bool {
    return true
  }
}
