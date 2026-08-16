//===--- ClosedRange.swift ------------------------------------------------===//
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

// FIXME: swift-3-indexing-model: Generalize all tests to check both
// [Closed]Range.

@frozen
public struct ClosedRange<Bound: Comparable> {
  public let lowerBound: Bound

  public let upperBound: Bound

  @inlinable
  public init(uncheckedBounds bounds: (lower: Bound, upper: Bound)) {
    self.lowerBound = bounds.lower
    self.upperBound = bounds.upper
  }
}

// define isEmpty, which is available even on an uncountable ClosedRange
extension ClosedRange {
  @inlinable
  public var isEmpty: Bool {
    return false
  }
}

extension ClosedRange: RangeExpression {
  @inlinable // trivial-implementation
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return Range(
      uncheckedBounds: (
        lower: lowerBound, upper: collection.index(after: self.upperBound)))
  }

  @inlinable
  public func contains(_ element: Bound) -> Bool {
    return element >= self.lowerBound && element <= self.upperBound
  }
}

extension ClosedRange: Sequence
where Bound: Strideable, Bound.Stride: SignedInteger {
  public typealias Element = Bound
  public typealias Iterator = IndexingIterator<ClosedRange<Bound>>
}

extension ClosedRange where Bound : Strideable, Bound.Stride : SignedInteger {
  @frozen // FIXME(resilience)
  public enum Index {
    case pastEnd
    case inRange(Bound)
  }
}

extension ClosedRange.Index : Comparable {
  @inlinable
  public static func == (
    lhs: ClosedRange<Bound>.Index,
    rhs: ClosedRange<Bound>.Index
  ) -> Bool {
    switch (lhs, rhs) {
    case (.inRange(let l), .inRange(let r)):
      return l == r
    case (.pastEnd, .pastEnd):
      return true
    default:
      return false
    }
  }

  @inlinable
  public static func < (
    lhs: ClosedRange<Bound>.Index,
    rhs: ClosedRange<Bound>.Index
  ) -> Bool {
    switch (lhs, rhs) {
    case (.inRange(let l), .inRange(let r)):
      return l < r
    case (.inRange, .pastEnd):
      return true
    default:
      return false
    }
  }
}

extension ClosedRange.Index: Hashable
where Bound: Strideable, Bound.Stride: SignedInteger, Bound: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .inRange(let value):
      hasher.combine(0 as Int8)
      hasher.combine(value)
    case .pastEnd:
      hasher.combine(1 as Int8)
    }
  }
}

// FIXME: this should only be conformance to RandomAccessCollection but
// the compiler balks without all 3
extension ClosedRange: Collection, BidirectionalCollection, RandomAccessCollection
where Bound : Strideable, Bound.Stride : SignedInteger
{
  // while a ClosedRange can't be empty, a _slice_ of a ClosedRange can,
  // so ClosedRange can't be its own self-slice unlike Range
  public typealias SubSequence = Slice<ClosedRange<Bound>>

  @inlinable
  public var startIndex: Index {
    return .inRange(lowerBound)
  }

  @inlinable
  public var endIndex: Index {
    return .pastEnd
  }

  @inlinable
  public func index(after i: Index) -> Index {
    switch i {
    case .inRange(let x):
      return x == upperBound
        ? .pastEnd
        : .inRange(x.advanced(by: 1))
    case .pastEnd: 
      _precondition(false)
      return endIndex
    }
  }

  @inlinable
  public func index(before i: Index) -> Index {
    switch i {
    case .inRange(let x):
      _precondition(x > lowerBound)
      return .inRange(x.advanced(by: -1))
    case .pastEnd: 
      _precondition(upperBound >= lowerBound)
      return .inRange(upperBound)
    }
  }

  @inlinable
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    switch i {
    case .inRange(let x):
      let d = x.distance(to: upperBound)
      if distance <= d {
        let newPosition = x.advanced(by: numericCast(distance))
        _precondition(newPosition >= lowerBound)
        return .inRange(newPosition)
      }
      if d - -1 == distance { return .pastEnd }
      _precondition(false)
      return endIndex
    case .pastEnd:
      if distance == 0 {
        return i
      } 
      if distance < 0 {
        return index(.inRange(upperBound), offsetBy: numericCast(distance + 1))
      }
      _precondition(false)
      return endIndex
    }
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    switch (start, end) {
    case let (.inRange(left), .inRange(right)):
      // in range <--> in range
      return numericCast(left.distance(to: right))
    case let (.inRange(left), .pastEnd):
      // in range --> end
      return numericCast(1 + left.distance(to: upperBound))
    case let (.pastEnd, .inRange(right)):
      // in range <-- end
      return numericCast(upperBound.distance(to: right) - 1)
    case (.pastEnd, .pastEnd):
      // end <--> end
      return 0
    }
  }

  @inlinable
  public subscript(position: Index) -> Bound {
    // FIXME: swift-3-indexing-model: range checks and tests.
    switch position {
    case .inRange(let x): return x
    case .pastEnd:
      _precondition(false)
      return upperBound
    }
  }

  @inlinable
  public subscript(bounds: Range<Index>)
    -> Slice<ClosedRange<Bound>> {
    return Slice(base: self, bounds: bounds)
  }

  @inlinable
  public func _customContainsEquatableElement(_ element: Bound) -> Bool? {
    return lowerBound <= element && element <= upperBound
  }

  @inlinable
  public func _customIndexOfEquatableElement(_ element: Bound) -> Index?? {
    return lowerBound <= element && element <= upperBound
              ? .inRange(element) : nil
  }

  @inlinable
  public func _customLastIndexOfEquatableElement(_ element: Bound) -> Index?? {
    // The first and last elements are the same because each element is unique.
    return _customIndexOfEquatableElement(element)
  }
}

extension Comparable {  
  @_transparent
  public static func ... (minimum: Self, maximum: Self) -> ClosedRange<Self> {
    // _precondition(
    //   minimum <= maximum)
    return ClosedRange(uncheckedBounds: (lower: minimum, upper: maximum))
  }
}

extension ClosedRange: Equatable {
  @inlinable
  public static func == (
    lhs: ClosedRange<Bound>, rhs: ClosedRange<Bound>
  ) -> Bool {
    return lhs.lowerBound == rhs.lowerBound && lhs.upperBound == rhs.upperBound
  }
}

extension ClosedRange: Hashable where Bound: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(lowerBound)
    hasher.combine(upperBound)
  }
}

extension ClosedRange {
  @inlinable // trivial-implementation
  @inline(__always)
  public func clamped(to limits: ClosedRange) -> ClosedRange {
    let lower =         
      limits.lowerBound > self.lowerBound ? limits.lowerBound
          : limits.upperBound < self.lowerBound ? limits.upperBound
          : self.lowerBound
    let upper =
      limits.upperBound < self.upperBound ? limits.upperBound
          : limits.lowerBound > self.upperBound ? limits.lowerBound
          : self.upperBound
    return ClosedRange(uncheckedBounds: (lower: lower, upper: upper))
  }
}

extension ClosedRange where Bound: Strideable, Bound.Stride : SignedInteger {  
  @inlinable
  public init(_ other: Range<Bound>) {
    _precondition(!other.isEmpty)
    let upperBound = other.upperBound.advanced(by: -1)
    self.init(uncheckedBounds: (lower: other.lowerBound, upper: upperBound))
  }
}

extension ClosedRange {
  @inlinable
  public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
    return self.contains(other.lowerBound) || other.contains(lowerBound)
  }

  @inlinable
  public func overlaps(_ other: Range<Bound>) -> Bool {
    return other.overlaps(self)
  }
}

// Note: this is not for compatibility only, it is considered a useful
// shorthand. TODO: Add documentation
public typealias CountableClosedRange<Bound: Strideable> = ClosedRange<Bound>
  where Bound.Stride : SignedInteger
