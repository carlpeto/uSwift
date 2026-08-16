public protocol IteratorProtocol<Element> {
  associatedtype Element

  mutating func next() -> Element?
}

public protocol Sequence<Element> {
  associatedtype Element

  associatedtype Iterator : IteratorProtocol where Iterator.Element == Element

  // associatedtype SubSequence : Sequence = AnySequence<Element>
  //   where Element == SubSequence.Element,
  //         SubSequence.SubSequence == SubSequence
  // typealias SubSequence = AnySequence<Element>

  __consuming func makeIterator() -> Iterator

  var underestimatedCount: Int { get }

  func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool?

  __consuming func _copyToContiguousArray() -> ContiguousArray<Element>

  __consuming func _copyContents(
    initializing ptr: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index)
  
  func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R?  
}

// Provides a default associated type witness for Iterator when the
// Self type is both a Sequence and an Iterator.
extension Sequence where Self: IteratorProtocol {
  // @_implements(Sequence, Iterator)
  public typealias _Default_Iterator = Self
}

extension Sequence where Self.Iterator == Self {
  @inlinable
  public __consuming func makeIterator() -> Self {
    return self
  }
}

@frozen
public struct DropFirstSequence<Base: Sequence> {
  @usableFromInline
  internal let _base: Base
  @usableFromInline
  internal let _limit: Int
  
  @inlinable 
  public init(_ base: Base, dropping limit: Int) {
    _precondition(limit >= 0)
    _base = base
    _limit = limit
  }
}

extension DropFirstSequence: Sequence {
  public typealias Element = Base.Element
  public typealias Iterator = Base.Iterator
  public typealias SubSequence = AnySequence<Element>
  
  @inlinable
  public __consuming func makeIterator() -> Iterator {
    var it = _base.makeIterator()
    var dropped = 0
    while dropped < _limit, it.next() != nil { dropped &+= 1 }
    return it
  }

  @inlinable
  public __consuming func dropFirst(_ k: Int) -> DropFirstSequence<Base> {
    // If this is already a _DropFirstSequence, we need to fold in
    // the current drop count and drop limit so no data is lost.
    //
    // i.e. [1,2,3,4].dropFirst(1).dropFirst(1) should be equivalent to
    // [1,2,3,4].dropFirst(2).
    return DropFirstSequence(_base, dropping: _limit + k)
  }
}

@frozen
public struct PrefixSequence<Base: Sequence> {
  @usableFromInline
  internal var _base: Base
  @usableFromInline
  internal let _maxLength: Int

  @inlinable
  public init(_ base: Base, maxLength: Int) {
    _precondition(maxLength >= 0)
    _base = base
    _maxLength = maxLength
  }
}

extension PrefixSequence {
  @frozen
  public struct Iterator {
    @usableFromInline
    internal var _base: Base.Iterator
    @usableFromInline
    internal var _remaining: Int
    
    @inlinable
    internal init(_ base: Base.Iterator, maxLength: Int) {
      _base = base
      _remaining = maxLength
    }
  }  
}

extension PrefixSequence.Iterator: IteratorProtocol {
  public typealias Element = Base.Element
  
  @inlinable
  public mutating func next() -> Element? {
    if _remaining != 0 {
      _remaining &-= 1
      return _base.next()
    } else {
      return nil
    }
  }  
}

extension PrefixSequence: Sequence {
  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return Iterator(_base.makeIterator(), maxLength: _maxLength)
  }

  @inlinable
  public __consuming func prefix(_ maxLength: Int) -> PrefixSequence<Base> {
    let length = Swift.min(maxLength, self._maxLength)
    return PrefixSequence(_base, maxLength: length)
  }
}


@frozen
public struct DropWhileSequence<Base: Sequence> {
  public typealias Element = Base.Element
  
  @usableFromInline
  internal var _iterator: Base.Iterator
  @usableFromInline
  internal var _nextElement: Element?
  
  @inlinable
  internal init(iterator: Base.Iterator, predicate: (Element) throws -> Bool) rethrows {
    _iterator = iterator
    _nextElement = _iterator.next()
    
    while let x = _nextElement, try predicate(x) {
      _nextElement = _iterator.next()
    }
  }
  
  @inlinable
  internal init(_ base: Base, predicate: (Element) throws -> Bool) rethrows {
    self = try DropWhileSequence(iterator: base.makeIterator(), predicate: predicate)
  }
}

extension DropWhileSequence {
  @frozen
  public struct Iterator {
    @usableFromInline
    internal var _iterator: Base.Iterator
    @usableFromInline
    internal var _nextElement: Element?
    
    @inlinable
    internal init(_ iterator: Base.Iterator, nextElement: Element?) {
      _iterator = iterator
      _nextElement = nextElement
    }
  }
}

extension DropWhileSequence.Iterator: IteratorProtocol {
  public typealias Element = Base.Element
  
  @inlinable
  public mutating func next() -> Element? {
    guard let next = _nextElement else { return nil }
    _nextElement = _iterator.next()
    return next
  }
}

extension DropWhileSequence: Sequence {
  @inlinable
  public func makeIterator() -> Iterator {
    return Iterator(_iterator, nextElement: _nextElement)
  }
  
  @inlinable
  public __consuming func drop(
    while predicate: (Element) throws -> Bool
  ) rethrows -> DropWhileSequence<Base> {
    guard let x = _nextElement, try predicate(x) else { return self }
    return try DropWhileSequence(iterator: _iterator, predicate: predicate)
  }
}

//===----------------------------------------------------------------------===//
// Default implementations for Sequence
//===----------------------------------------------------------------------===//

extension Sequence {
  @available(*, deprecated, message: "map on sequence not recommended, consider lazyMap instead, see uSwift documentation")
  @inlinable
  public func map<T>(
    _ transform: (Element) throws -> T
  ) rethrows -> [T] {
    var initialCapacity = underestimatedCount
    var result = Array<T>(_uninitializedCount: &initialCapacity)

    var iterator = self.makeIterator()

    // Add elements up to the initial capacity without checking for regrowth.
    for i: Int in (0 as Int)..<initialCapacity {
      result[i] = try transform(iterator.next()!)
    }

    // remaining elements are ignored as arrays are fixed size
    return result
  }

  @available(*, deprecated, message: "filter on sequence not recommended, consider lazyFilter instead, see uSwift documentation")
  @inlinable
  public __consuming func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> [Element] {
    return try _filter(isIncluded)
  }

  @_transparent
  public func _filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> [Element] {

    var initialCapacity = underestimatedCount
    var result = Array<Element>(_uninitializedCount: &initialCapacity)

    var iterator = self.makeIterator()

    var i: Int = 0
    while let element = iterator.next() {
      if try isIncluded(element) {
        result[i] = element
        i += 1
      }
    }

    // extra buffer space for filtered out elements is wasted
    result._buffer.count = i

    return result
  }

  @inlinable
  public var underestimatedCount: Int {
    return 0
  }

  @inlinable
  @inline(__always)
  public func _customContainsEquatableElement(
    _ element: Iterator.Element
  ) -> Bool? {
    return nil
  }

  @inlinable
  public func forEach(
    _ body: (Element) throws -> Void
  ) rethrows {
    for element in self {
      try body(element)
    }
  }
}


extension Sequence {
  @inlinable
  public func first(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Element? {
    for element in self  {
      if try predicate(element) {
        return element
      }
    }
    return nil
  }
}

extension Sequence where Element : Equatable {
  @inlinable
  public __consuming func split(
    separator: Element,
    maxSplits: Int = Int.max,
    omittingEmptySubsequences: Bool = true
  ) -> [ArraySlice<Element>] {
    return split(
      maxSplits: maxSplits,
      omittingEmptySubsequences: omittingEmptySubsequences,
      whereSeparator: { $0 == separator })
  }
}

extension Sequence {

  @available(*, deprecated, message: "Split sequence may create partial results, see uSwift documentation")
  @inlinable
  public __consuming func split(
    maxSplits: Int = Int.max,
    omittingEmptySubsequences: Bool = true,
    whereSeparator isSeparator: (Element) throws -> Bool
  ) rethrows -> [ArraySlice<Element>] {
    _precondition(maxSplits >= 0)
    let whole = Array(self)
    return try whole.split(
                  maxSplits: maxSplits, 
                  omittingEmptySubsequences: omittingEmptySubsequences, 
                  whereSeparator: isSeparator)
  }

  @inlinable
  public __consuming func suffix(_ maxLength: Int) -> [Element] {
    _precondition(maxLength >= 0)
    guard maxLength != 0 else { return [] }

    // FIXME: <rdar://problem/21885650> Create reusable RingBuffer<T>
    // Put incoming elements into a ring buffer to save space. Once all
    // elements are consumed, reorder the ring buffer into a copy and return it.
    // This saves memory for sequences particularly longer than `maxLength`.
    var ringBufferCapacity = Swift.min(maxLength, underestimatedCount)
    var ringBuffer = Array<Element>(_uninitializedCount: &ringBufferCapacity)

    var i: Int = 0
    var ringBufferCount: Int = 0

    for element in self {
      if ringBufferCount < maxLength {
        ringBuffer[ringBufferCount] = element
        ringBufferCount += 1
      } else {
        ringBuffer[i] = element
        i = (i + 1) % maxLength
      }
    }

    if i != ringBuffer.startIndex {
      var rotatedIndex: Int = 0
      var rotated = Array<Element>(_uninitializedCount: &ringBufferCapacity)
      for j in i..<ringBuffer.endIndex {
        rotated[rotatedIndex] = ringBuffer[j]
        rotatedIndex += 1
      }
      for j in (0 as Int)..<i {
        rotated[rotatedIndex] = ringBuffer[j]
        rotatedIndex += 1
      }
      return rotated
    } else {
      return ringBuffer
    }
  }

  @inlinable
  public __consuming func dropFirst(_ k: Int = 1) -> DropFirstSequence<Self> {
    return DropFirstSequence(self, dropping: k)
  }

  @inlinable
  public __consuming func dropLast(_ k: Int = 1) -> [Element] {
    var k = k
    _precondition(k >= 0)
    guard k != 0 else { return Array(self) }

    // FIXME: <rdar://problem/21885650> Create reusable RingBuffer<T>
    // Put incoming elements from this sequence in a holding tank, a ring buffer
    // of size <= k. If more elements keep coming in, pull them out of the
    // holding tank into the result, an `Array`. This saves
    // `k` * sizeof(Element) of memory, because slices keep the entire
    // memory of an `Array` alive.
    if underestimatedCount <= k {
      return Array<Element>() // we can't be sure there are enough elements
    }

    var resultBufferCapacity = underestimatedCount - k
    var result = Array<Element>(_uninitializedCount: &resultBufferCapacity)
    var ringBuffer = Array<Element>(_uninitializedCount: &k)
    var i = ringBuffer.startIndex
    var ringBufferCount: Int = 0
    var resultCount: Int = 0

    for element in self {
      if ringBufferCount < k {
        ringBuffer[ringBufferCount] = element
        ringBufferCount += 1
      } else if resultCount < resultBufferCapacity {
        result[resultCount] = ringBuffer[i]
        resultCount += 1
        ringBuffer[i] = element
        i = (i + 1) % k
      }
    }
    return result
  }

  @inlinable
  public __consuming func drop(
    while predicate: (Element) throws -> Bool
  ) rethrows -> DropWhileSequence<Self> {
    return try DropWhileSequence(self, predicate: predicate)
  }

  @inlinable
  public __consuming func prefix(_ maxLength: Int) -> PrefixSequence<Self> {
    return PrefixSequence(self, maxLength: maxLength)
  }

  @available(*, unavailable, message: "cannot build arbitrary sized arrays with prefix(while:), see uSwift documentation")
  @inlinable
  public __consuming func prefix(
    while predicate: (Element) throws -> Bool
  ) rethrows -> [Element] {
    return Array<Element>()
    // var result = Array<Element>()

    // for element in self {
    //   guard try predicate(element) else {
    //     break
    //   }
    //   result.append(element)
    // }
    // return Array(result)
  }
}

extension Sequence {
  @inlinable
  public __consuming func _copyContents(
    initializing buffer: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index) {
    var it = self.makeIterator()
    guard var ptr = buffer.baseAddress else { return (it,buffer.startIndex) }
    for idx in buffer.startIndex..<buffer.count {
      guard let x = it.next() else {
        return (it, idx)
      }
      ptr.initialize(to: x)
      ptr += 1
    }
    return (it,buffer.endIndex)
  }
    
  @inlinable
  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return nil
  }  
}

// FIXME(ABI)#182
// Pending <rdar://problem/14011860> and <rdar://problem/14396120>,
// pass an IteratorProtocol through IteratorSequence to give it "Sequence-ness"
@frozen
public struct IteratorSequence<Base : IteratorProtocol> {
  @usableFromInline
  internal var _base: Base

  @inlinable
  public init(_ base: Base) {
    _base = base
  }
}

extension IteratorSequence: IteratorProtocol, Sequence {
  @inlinable
  public mutating func next() -> Base.Element? {
    return _base.next()
  }
}
