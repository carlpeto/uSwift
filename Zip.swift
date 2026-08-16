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

@inlinable // generic-performance
public func zip<Sequence1, Sequence2>(
  _ sequence1: Sequence1, _ sequence2: Sequence2
) -> Zip2Sequence<Sequence1, Sequence2> {
  return Zip2Sequence(sequence1, sequence2)
}

@frozen // generic-performance
public struct Zip2Sequence<Sequence1 : Sequence, Sequence2 : Sequence> {
  @usableFromInline // generic-performance
  internal let _sequence1: Sequence1
  @usableFromInline // generic-performance
  internal let _sequence2: Sequence2

  @inlinable // generic-performance
  internal init(_ sequence1: Sequence1, _ sequence2: Sequence2) {
    (_sequence1, _sequence2) = (sequence1, sequence2)
  }
}

extension Zip2Sequence {
  @frozen // generic-performance
  public struct Iterator {
    @usableFromInline // generic-performance
    internal var _baseStream1: Sequence1.Iterator
    @usableFromInline // generic-performance
    internal var _baseStream2: Sequence2.Iterator
    @usableFromInline // generic-performance
    internal var _reachedEnd: Bool = false

    @inlinable // generic-performance
    internal init(
    _ iterator1: Sequence1.Iterator, 
    _ iterator2: Sequence2.Iterator
    ) {
      (_baseStream1, _baseStream2) = (iterator1, iterator2)
    }
  }
}

extension Zip2Sequence.Iterator: IteratorProtocol {
  public typealias Element = (Sequence1.Element, Sequence2.Element)

  @inlinable // generic-performance
  public mutating func next() -> Element? {
    // The next() function needs to track if it has reached the end.  If we
    // didn't, and the first sequence is longer than the second, then when we
    // have already exhausted the second sequence, on every subsequent call to
    // next() we would consume and discard one additional element from the
    // first sequence, even though next() had already returned nil.

    if _reachedEnd {
      return nil
    }

    guard let element1 = _baseStream1.next(),
          let element2 = _baseStream2.next() else {
      _reachedEnd = true
      return nil
    }

    return (element1, element2)
  }
}

extension Zip2Sequence: Sequence {
  public typealias Element = (Sequence1.Element, Sequence2.Element)

  @inlinable // generic-performance
  public __consuming func makeIterator() -> Iterator {
    return Iterator(
      _sequence1.makeIterator(),
      _sequence2.makeIterator())
  }

  @inlinable // generic-performance
  public var underestimatedCount: Int {
    return Swift.min(
      _sequence1.underestimatedCount,
      _sequence2.underestimatedCount
    )
  }
}
