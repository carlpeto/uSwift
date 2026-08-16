//===--- CollectionOfOne.swift - A Collection with one element ------------===//
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
public struct CollectionOfOne<Element> {
  @usableFromInline // trivial-implementation
  internal var _element: Element

  @inlinable // trivial-implementation
  public init(_ element: Element) {
    self._element = element
  }
}

extension CollectionOfOne {
  @frozen // trivial-implementation
  public struct Iterator {
    @usableFromInline // trivial-implementation
    internal var _elements: Element?

    @inlinable // trivial-implementation
    public // @testable
    init(_elements: Element?) {
      self._elements = _elements
    }
  }
}

extension CollectionOfOne.Iterator: IteratorProtocol {
  @inlinable // trivial-implementation
  public mutating func next() -> Element? {
    let result = _elements
    _elements = nil
    return result
  }
}

extension CollectionOfOne: RandomAccessCollection, MutableCollection {

  public typealias Index = Int
  public typealias Indices = Range<Int>
  public typealias SubSequence = Slice<CollectionOfOne<Element>>

  @inlinable // trivial-implementation
  public var startIndex: Index {
    return 0
  }

  @inlinable // trivial-implementation
  public var endIndex: Index {
    return 1
  }
  
  @inlinable // trivial-implementation
  public func index(after i: Index) -> Index {
    _precondition(i == startIndex)
    return 1
  }

  @inlinable // trivial-implementation
  public func index(before i: Index) -> Index {
    _precondition(i == endIndex)
    return 0
  }

  @inlinable // trivial-implementation
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_elements: _element)
  }

  @inlinable // trivial-implementation
  public subscript(position: Int) -> Element {
    _read {
      _precondition(position == 0)
      yield _element
    }
    _modify {
      _precondition(position == 0)
      yield &_element
    }
  }

  @inlinable // trivial-implementation
  public subscript(bounds: Range<Int>) -> SubSequence {
    get {
      _failEarlyRangeCheck(bounds, bounds: 0..<1)
      return Slice(base: self, bounds: bounds)
    }
    set {
      _failEarlyRangeCheck(bounds, bounds: 0..<1)
      let n = newValue.count
      _precondition(bounds.count == n)
      if n == 1 { self = newValue.base }
    }
  }

  @inlinable // trivial-implementation
  public var count: Int {
    return 1
  }
}

// extension CollectionOfOne : CustomDebugStringConvertible {
//   public var debugDescription: String {
//     return "CollectionOfOne(\(String(reflecting: _element)))"
//   }
// }

// extension CollectionOfOne : CustomReflectable {
//   public var customMirror: Mirror {
//     return Mirror(self, children: ["element": _element])
//   }
// }
