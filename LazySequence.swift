//===--- LazySequence.swift -----------------------------------------------===//
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

public protocol LazySequenceProtocol : Sequence {
  associatedtype Elements: Sequence = Self where Elements.Element == Element

  var elements: Elements { get }
}

extension LazySequenceProtocol where Elements == Self {
  @inlinable // protocol-only
  public var elements: Self { return self }
}

extension LazySequenceProtocol {
  @inlinable // protocol-only
  public var lazy: LazySequence<Elements> {
    return elements.lazy
  }
}

extension LazySequenceProtocol where Elements: LazySequenceProtocol {
  @inlinable // protocol-only
  public var lazy: Elements {
    return elements
  }
}

@frozen // lazy-performance
public struct LazySequence<Base : Sequence> {
  @usableFromInline
  internal var _base: Base

  @inlinable // lazy-performance
  internal init(_base: Base) {
    self._base = _base
  }
}

extension LazySequence: Sequence {
  public typealias Element = Base.Element
  public typealias Iterator = Base.Iterator

  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return _base.makeIterator()
  }
  
  @inlinable // lazy-performance
  public var underestimatedCount: Int {
    return _base.underestimatedCount
  }

  @inlinable // lazy-performance
  @discardableResult
  public __consuming func _copyContents(
    initializing buf: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator, UnsafeMutableBufferPointer<Element>.Index) {
    return _base._copyContents(initializing: buf)
  }

  @inlinable // lazy-performance
  public func _customContainsEquatableElement(_ element: Element) -> Bool? { 
    return _base._customContainsEquatableElement(element)
  }
  
  @inlinable // generic-performance
  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
    return _base._copyToContiguousArray()
  }
}

extension LazySequence: LazySequenceProtocol {
  public typealias Elements = Base

  @inlinable // lazy-performance
  public var elements: Elements { return _base }
}

extension Sequence {
  @inlinable // protocol-only
  public var lazy: LazySequence<Self> {
    return LazySequence(_base: self)
  }
}
