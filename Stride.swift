public protocol Strideable : Comparable {
  associatedtype Stride : SignedNumeric

  func distance(to other: Self) -> Stride

  func advanced(by n: Stride) -> Self

  static func _step(
    after current: (index: Int?, value: Self),
    from start: Self, by distance: Self.Stride
  ) -> (index: Int?, value: Self)
}

extension Strideable {
  @inlinable
  public static func < (x: Self, y: Self) -> Bool {
    return x.distance(to: y) > 0
  }

  @inlinable
  public static func == (x: Self, y: Self) -> Bool {
    return x.distance(to: y) == 0
  }
}

extension Strideable {
  @inlinable // protocol-only
  public static func _step(
    after current: (index: Int?, value: Self),
    from start: Self, by distance: Self.Stride
  ) -> (index: Int?, value: Self) {
    return (nil, current.value.advanced(by: distance))
  }
}

// extension Strideable where Stride : FloatingPoint {
//   @inlinable // protocol-only
//   public static func _step(
//     after current: (index: Int?, value: Self),
//     from start: Self, by distance: Self.Stride
//   ) -> (index: Int?, value: Self) {
//     if let i = current.index {
//       // When Stride is a floating-point type, we should avoid accumulating
//       // rounding error from repeated addition.
//       return (i + 1, start.advanced(by: Stride(i + 1) * distance))
//     }
//     return (nil, current.value.advanced(by: distance))
//   }
// }

// extension Strideable where Self : FloatingPoint, Self == Stride {
//   @inlinable // protocol-only
//   public static func _step(
//     after current: (index: Int?, value: Self),
//     from start: Self, by distance: Self.Stride
//   ) -> (index: Int?, value: Self) {
//     if let i = current.index {
//       // When both Self and Stride are the same floating-point type, we should
//       // take advantage of fused multiply-add (where supported) to eliminate
//       // intermediate rounding error.
//       return (i + 1, start.addingProduct(Stride(i + 1), distance))
//     }
//     return (nil, current.value.advanced(by: distance))
//   }
// }

@frozen
public struct StrideToIterator<Element : Strideable> {
  @usableFromInline
  internal let _start: Element

  @usableFromInline
  internal let _end: Element

  @usableFromInline
  internal let _stride: Element.Stride

  @usableFromInline
  internal var _current: (index: Int?, value: Element)

  @inlinable
  internal init(_start: Element, end: Element, stride: Element.Stride) {
    self._start = _start
    _end = end
    _stride = stride
    _current = (0, _start)
  }
}

extension StrideToIterator: IteratorProtocol {
  @inlinable
  public mutating func next() -> Element? {
    let result = _current.value
    if _stride > 0 ? result >= _end : result <= _end {
      return nil
    }
    _current = Element._step(after: _current, from: _start, by: _stride)
    return result
  }
}

// FIXME: should really be a Collection, as it is multipass
@frozen
public struct StrideTo<Element : Strideable> {
  @usableFromInline
  internal let _start: Element

  @usableFromInline
  internal let _end: Element

  @usableFromInline
  internal let _stride: Element.Stride

  @inlinable
  internal init(_start: Element, end: Element, stride: Element.Stride) {
    // _precondition(stride != 0)
    // At start, striding away from end is allowed; it just makes for an
    // already-empty Sequence.
    self._start = _start
    self._end = end
    self._stride = stride
  }
}

extension StrideTo: Sequence {
  @inlinable
  public __consuming func makeIterator() -> StrideToIterator<Element> {
    return StrideToIterator(_start: _start, end: _end, stride: _stride)
  }

  // FIXME(conditional-conformances): this is O(N) instead of O(1), leaving it
  // here until a proper Collection conformance is possible
  @inlinable
  public var underestimatedCount: Int {
    var it = self.makeIterator()
    var count: Int = 0
    while it.next() != nil {
      count += 1
    }
    return count
  }

  @inlinable
  public func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    if element < _start || _end <= element {
      return false
    }
    return nil
  }
}

// extension StrideTo: CustomReflectable {
//   public var customMirror: Mirror {
//     return Mirror(self, children: ["from": _start, "to": _end, "by": _stride])
//   }
// }

@inlinable
public func stride<T>(
  from start: T, to end: T, by stride: T.Stride
) -> StrideTo<T> {
  return StrideTo(_start: start, end: end, stride: stride)
}

@frozen
public struct StrideThroughIterator<Element : Strideable> {
  @usableFromInline
  internal let _start: Element

  @usableFromInline
  internal let _end: Element

  @usableFromInline
  internal let _stride: Element.Stride

  @usableFromInline
  internal var _current: (index: Int?, value: Element)

  @usableFromInline
  internal var _didReturnEnd: Bool = false

  @inlinable
  internal init(_start: Element, end: Element, stride: Element.Stride) {
    self._start = _start
    _end = end
    _stride = stride
    _current = (0, _start)
  }
}

extension StrideThroughIterator: IteratorProtocol {
  @inlinable
  public mutating func next() -> Element? {
    let result = _current.value
    if _stride > 0 ? result >= _end : result <= _end {
      // This check is needed because if we just changed the above operators
      // to > and <, respectively, we might advance current past the end
      // and throw it out of bounds (e.g. above Int.max) unnecessarily.
      if result == _end && !_didReturnEnd {
        _didReturnEnd = true
        return result
      }
      return nil
    }
    _current = Element._step(after: _current, from: _start, by: _stride)
    return result
  }
}

// FIXME: should really be a Collection, as it is multipass
@frozen
public struct StrideThrough<Element: Strideable> {
  @usableFromInline
  internal let _start: Element
  @usableFromInline
  internal let _end: Element
  @usableFromInline
  internal let _stride: Element.Stride
  
  @inlinable
  internal init(_start: Element, end: Element, stride: Element.Stride) {
    _precondition(stride != 0)
    self._start = _start
    self._end = end
    self._stride = stride
  }
}

extension StrideThrough: Sequence {
  @inlinable
  public __consuming func makeIterator() -> StrideThroughIterator<Element> {
    return StrideThroughIterator(_start: _start, end: _end, stride: _stride)
  }

  // FIXME(conditional-conformances): this is O(N) instead of O(1), leaving it
  // here until a proper Collection conformance is possible
  @inlinable
  public var underestimatedCount: Int {
    var it = self.makeIterator()
    var count: Int = 0
    while it.next() != nil {
      count += 1
    }
    return count
  }

  @inlinable
  public func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    if element < _start || _end < element {
      return false
    }
    return nil
  }
}

// extension StrideThrough: CustomReflectable {
//   public var customMirror: Mirror {
//     return Mirror(self,
//       children: ["from": _start, "through": _end, "by": _stride])
//   }
// }

// FIXME(conditional-conformances): This does not yet compile (SR-6474).
#if false
extension StrideThrough : RandomAccessCollection
where Element.Stride : BinaryInteger {
  public typealias Index = ClosedRangeIndex<Int>
  public typealias SubSequence = Slice<StrideThrough<Element>>

  @inlinable
  public var startIndex: Index {
    let distance = _start.distance(to: _end)
    return distance == 0 || (distance < 0) == (_stride < 0)
      ? ClosedRangeIndex(0)
      : ClosedRangeIndex()
  }

  @inlinable
  public var endIndex: Index { return ClosedRangeIndex() }

  @inlinable
  public var count: Int {
    let distance = _start.distance(to: _end)
    guard distance != 0 else { return 1 }
    guard (distance < 0) == (_stride < 0) else { return 0 }
    return Int(distance / _stride) + 1
  }

  public subscript(position: Index) -> Element {
    let offset = Element.Stride(position._dereferenced) * _stride
    return _start.advanced(by: offset)
  }

  public subscript(bounds: Range<Index>) -> Slice<StrideThrough<Element>> {
    return Slice(base: self, bounds: bounds)
  }

  @inlinable
  public func index(before i: Index) -> Index {
    switch i._value {
    case .inRange(let n):
      _precondition(n > 0)
      return ClosedRangeIndex(n - 1)
    case .pastEnd:
      _precondition(_end >= _start)
      return ClosedRangeIndex(count - 1)
    }
  }

  @inlinable
  public func index(after i: Index) -> Index {
    switch i._value {
    case .inRange(let n):
      return n == (count - 1)
        ? ClosedRangeIndex()
        : ClosedRangeIndex(n + 1)
    case .pastEnd:
      _preconditionFailure()
    }
  }
}
#endif

@inlinable
public func stride<T>(
  from start: T, through end: T, by stride: T.Stride
) -> StrideThrough<T> {
  return StrideThrough(_start: start, end: end, stride: stride)
}
