public protocol RangeExpression<Bound> {
  associatedtype Bound: Comparable

  func relative<C: Collection>(
    to collection: C
  ) -> Range<Bound> where C.Index == Bound

  func contains(_ element: Bound) -> Bool
}

extension RangeExpression {
  @inlinable
  public static func ~= (pattern: Self, value: Bound) -> Bool {
    return pattern.contains(value)
  }
}






@frozen
public struct Range<Bound : Comparable> {
  public let lowerBound: Bound

  public let upperBound: Bound

  @inlinable
  public init(uncheckedBounds bounds: (lower: Bound, upper: Bound)) {
    self.lowerBound = bounds.lower
    self.upperBound = bounds.upper
  }

  @inlinable
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element && element < upperBound
  }

  @inlinable
  public var isEmpty: Bool {
    return lowerBound == upperBound
  }
}

extension Range: Sequence
where Bound: Strideable, Bound.Stride : SignedInteger {
  public typealias Element = Bound
  public typealias Iterator = IndexingIterator<Range<Bound>>
}

extension Range: Collection, BidirectionalCollection, RandomAccessCollection
where Bound : Strideable, Bound.Stride : SignedInteger
{
  public typealias Index = Bound
  public typealias Indices = Range<Bound>
  public typealias SubSequence = Range<Bound>

  @inlinable
  public var startIndex: Index { return lowerBound }

  @inlinable
  public var endIndex: Index { return upperBound }

  @inlinable
  public func index(after i: Index) -> Index {
    _failEarlyRangeCheck(i, bounds: startIndex..<endIndex)

    return i.advanced(by: 1)
  }

  @inlinable
  public func index(before i: Index) -> Index {
    _precondition(i > lowerBound)
    _precondition(i <= upperBound)

    return i.advanced(by: -1)
  }

  @inlinable
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    let r = i.advanced(by: numericCast(n))
    _precondition(r >= lowerBound)
    _precondition(r <= upperBound)
    return r
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    return numericCast(start.distance(to: end))
  }

  @inlinable
  public subscript(bounds: Range<Index>) -> Range<Bound> {
    return bounds
  }

  @inlinable
  public var indices: Indices {
    return self
  }

  @inlinable
  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return lowerBound <= element && element < upperBound
  }

  @inlinable
  public func _customIndexOfEquatableElement(_ element: Bound) -> Index?? {
    return lowerBound <= element && element < upperBound ? element : nil
  }

  @inlinable
  public func _customLastIndexOfEquatableElement(_ element: Bound) -> Index?? {
    // The first and last elements are the same because each element is unique.
    return _customIndexOfEquatableElement(element)
  }

  @inlinable
  public subscript(position: Index) -> Element {
    // FIXME: swift-3-indexing-model: tests for the range check.
    return position
  }
}

extension Range where Bound: Strideable, Bound.Stride : SignedInteger {
  public init(_ other: ClosedRange<Bound>) {
    let upperBound = other.upperBound.advanced(by: 1)
    self.init(uncheckedBounds: (lower: other.lowerBound, upper: upperBound))
  }
}

extension Range: RangeExpression {
  @inlinable // trivial-implementation
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return Range(uncheckedBounds: (lower: lowerBound, upper: upperBound))
  }
}

extension Range {
  @inlinable // trivial-implementation
  @inline(__always)
  public func clamped(to limits: Range) -> Range {
    let lower =
      limits.lowerBound > self.lowerBound ? limits.lowerBound
          : limits.upperBound < self.lowerBound ? limits.upperBound
          : self.lowerBound
    let upper =
      limits.upperBound < self.upperBound ? limits.upperBound
          : limits.lowerBound > self.upperBound ? limits.lowerBound
          : self.upperBound
    return Range(uncheckedBounds: (lower: lower, upper: upper))
  }
}


// extension Range : CustomReflectable {
//   public var customMirror: Mirror {
//     return Mirror(
//       self, children: ["lowerBound": lowerBound, "upperBound": upperBound])
//   }
// }

extension Range: Equatable {
  @inlinable
  public static func == (lhs: Range<Bound>, rhs: Range<Bound>) -> Bool {
    return
      lhs.lowerBound == rhs.lowerBound &&
      lhs.upperBound == rhs.upperBound
  }
}

extension Range: Hashable where Bound: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(lowerBound)
    hasher.combine(upperBound)
  }
}

extension Range {
  @inlinable
  public func overlaps(_ other: Range<Bound>) -> Bool {
    return (!other.isEmpty && self.contains(other.lowerBound))
        || (!self.isEmpty && other.contains(self.lowerBound))
  }

  @inlinable
  public func overlaps(_ other: ClosedRange<Bound>) -> Bool {
    return self.contains(other.lowerBound)
        || (!self.isEmpty && other.contains(self.lowerBound))
  }
}

@frozen
public struct PartialRangeUpTo<Bound: Comparable> {
  public let upperBound: Bound

  @inlinable // trivial-implementation
  public init(_ upperBound: Bound) { self.upperBound = upperBound }
}

extension PartialRangeUpTo: RangeExpression {
  @_transparent
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return collection.startIndex..<self.upperBound
  }

  @_transparent
  public func contains(_ element: Bound) -> Bool {
    return element < upperBound
  }
}

// extension PartialRangeUpTo: Decodable where Bound: Decodable {
//   public init(from decoder: Decoder) throws {
//     var container = try decoder.unkeyedContainer()
//     try self.init(container.decode(Bound.self))
//   }
// }

// extension PartialRangeUpTo: Encodable where Bound: Encodable {
//   public func encode(to encoder: Encoder) throws {
//     var container = encoder.unkeyedContainer()
//     try container.encode(self.upperBound)
//   }
// }

@frozen
public struct PartialRangeThrough<Bound: Comparable> {
  public let upperBound: Bound

  @inlinable // trivial-implementation
  public init(_ upperBound: Bound) { self.upperBound = upperBound }
}

extension PartialRangeThrough: RangeExpression {
  @_transparent
  public func relative<C: Collection>(to collection: C) -> Range<Bound>
  where C.Index == Bound {
    return collection.startIndex..<collection.index(after: self.upperBound)
  }
  @_transparent
  public func contains(_ element: Bound) -> Bool {
    return element <= upperBound
  }
}

// extension PartialRangeThrough: Decodable where Bound: Decodable {
//   public init(from decoder: Decoder) throws {
//     var container = try decoder.unkeyedContainer()
//     try self.init(container.decode(Bound.self))
//   }
// }

// extension PartialRangeThrough: Encodable where Bound: Encodable {
//   public func encode(to encoder: Encoder) throws {
//     var container = encoder.unkeyedContainer()
//     try container.encode(self.upperBound)
//   }
// }

@frozen
public struct PartialRangeFrom<Bound: Comparable> {
  public let lowerBound: Bound

  @inlinable // trivial-implementation
  public init(_ lowerBound: Bound) { self.lowerBound = lowerBound }
}

extension PartialRangeFrom: RangeExpression {
  @_transparent
  public func relative<C: Collection>(
    to collection: C
  ) -> Range<Bound> where C.Index == Bound {
    return self.lowerBound..<collection.endIndex
  }
  @inlinable // trivial-implementation
  public func contains(_ element: Bound) -> Bool {
    return lowerBound <= element
  }
}

extension PartialRangeFrom: Sequence
  where Bound : Strideable, Bound.Stride : SignedInteger
{
  public typealias Element = Bound

  @frozen
  public struct Iterator: IteratorProtocol {
    @usableFromInline
    internal var _current: Bound
    @inlinable
    public init(_current: Bound) { self._current = _current }

    @inlinable
    public mutating func next() -> Bound? {
      defer { _current = _current.advanced(by: 1) }
      return _current
    }
  }

  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_current: lowerBound)
  }
}

// extension PartialRangeFrom: Decodable where Bound: Decodable {
//   public init(from decoder: Decoder) throws {
//     var container = try decoder.unkeyedContainer()
//     try self.init(container.decode(Bound.self))
//   }
// }

// extension PartialRangeFrom: Encodable where Bound: Encodable {
//   public func encode(to encoder: Encoder) throws {
//     var container = encoder.unkeyedContainer()
//     try container.encode(self.lowerBound)
//   }
// }

extension Comparable {
  @_transparent
  public static func ..< (minimum: Self, maximum: Self) -> Range<Self> {
    // _precondition(minimum <= maximum)
    return Range(uncheckedBounds: (lower: minimum, upper: maximum))
  }

  @_transparent
  public static prefix func ..< (maximum: Self) -> PartialRangeUpTo<Self> {
    return PartialRangeUpTo(maximum)
  }

  @_transparent
  public static prefix func ... (maximum: Self) -> PartialRangeThrough<Self> {
    return PartialRangeThrough(maximum)
  }

  @_transparent
  public static postfix func ... (minimum: Self) -> PartialRangeFrom<Self> {
    return PartialRangeFrom(minimum)
  }
}

@frozen // namespace
public enum UnboundedRange_ {
  // FIXME: replace this with a computed var named `...` when the language makes
  // that possible.

  public static postfix func ... (_: UnboundedRange_) -> () {
    // This function is uncallable
  }
}

public typealias UnboundedRange = (UnboundedRange_)->()

extension Collection {
  @inlinable
  public subscript<R: RangeExpression>(r: R)
  -> SubSequence where R.Bound == Index {
    return self[r.relative(to: self)]
  }

  @inlinable
  public subscript(x: UnboundedRange) -> SubSequence {
    return self[startIndex...]
  }
}

extension MutableCollection {
  @inlinable
  public subscript<R: RangeExpression>(r: R) -> SubSequence
  where R.Bound == Index {
    get {
      return self[r.relative(to: self)]
    }
    set {
      self[r.relative(to: self)] = newValue
    }
  }

  @inlinable
  public subscript(x: UnboundedRange) -> SubSequence {
    get {
      return self[startIndex...]
    }
    @available(*, unavailable, message: "AVR collections cannot have unbounded set")
    set {
      // self[startIndex...] = newValue
    }
  }
}
