@frozen
public struct IndexingIterator<Elements : Collection> {
  @usableFromInline
  internal let _elements: Elements
  @usableFromInline
  internal var _position: Elements.Index

  @inlinable
  @inline(__always)
  init(_elements: Elements) {
    self._elements = _elements
    self._position = _elements.startIndex
  }

  @inlinable
  @inline(__always)
  init(_elements: Elements, _position: Elements.Index) {
    self._elements = _elements
    self._position = _position
  }
}

extension IndexingIterator: IteratorProtocol, Sequence {
  public typealias Element = Elements.Element
  public typealias Iterator = IndexingIterator<Elements>
  public typealias SubSequence = AnySequence<Element>

  @inlinable
  @inline(__always)
  public mutating func next() -> Elements.Element? {
    if _position == _elements.endIndex { return nil }
    let element = _elements[_position]
    _elements.formIndex(after: &_position)
    return element
  }
}

public protocol Collection<Element>: Sequence {
  // FIXME: ideally this would be in MigrationSupport.swift, but it needs
  // to be on the protocol instead of as an extension
  @available(*, deprecated/*, obsoleted: 5.0*/, message: "all index distances are now of type Int")
  typealias IndexDistance = Int  

  // FIXME: Associated type inference requires this.
  override associatedtype Element

  associatedtype Index : Comparable

  var startIndex: Index { get }
 
  var endIndex: Index { get }

  associatedtype Iterator = IndexingIterator<Self>

  // FIXME: Only needed for associated type inference. Otherwise,
  // we get an `IndexingIterator` rather than properly deducing the
  // Iterator type from makeIterator(). <rdar://problem/21539115>
  override __consuming func makeIterator() -> Iterator

  associatedtype SubSequence: Collection = Slice<Self>
  where SubSequence.Index == Index,
        Element == SubSequence.Element,
        SubSequence.SubSequence == SubSequence

  @_borrowed
  subscript(position: Index) -> Element { get }

  subscript(bounds: Range<Index>) -> SubSequence { get }

  associatedtype Indices : Collection = DefaultIndices<Self>
    where Indices.Element == Index, 
          Indices.Index == Index,
          Indices.SubSequence == Indices
        
  var indices: Indices { get }

  var isEmpty: Bool { get }

  var count: Int { get }
  
  // The following requirements enable dispatching for firstIndex(of:) and
  // lastIndex(of:) when the element type is Equatable.

  func _customIndexOfEquatableElement(_ element: Element) -> Index??

  func _customLastIndexOfEquatableElement(_ element: Element) -> Index??

  func index(_ i: Index, offsetBy distance: Int) -> Index

  func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index?

  func distance(from start: Index, to end: Index) -> Int

  func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>)

  func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>)

  func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>)

  func index(after i: Index) -> Index

  func formIndex(after i: inout Index)
}

extension Collection {
  @inlinable // protocol-only
  @inline(__always)
  public func formIndex(after i: inout Index) {
    i = index(after: i)
  }

  @inlinable
  public func _failEarlyRangeCheck(_ index: Index, bounds: Range<Index>) {
    // FIXME: swift-3-indexing-model: tests.
    // _precondition(
    //   bounds.lowerBound <= index)
    // _precondition(
    //   index < bounds.upperBound)
  }

  @inlinable
  public func _failEarlyRangeCheck(_ index: Index, bounds: ClosedRange<Index>) {
    // FIXME: swift-3-indexing-model: tests.
    // _precondition(
    //   bounds.lowerBound <= index)
    // _precondition(
    //   index <= bounds.upperBound)
  }

  @inlinable
  public func _failEarlyRangeCheck(_ range: Range<Index>, bounds: Range<Index>) {
    // FIXME: swift-3-indexing-model: tests.
    // _precondition(
    //   bounds.lowerBound <= range.lowerBound)
    // _precondition(
    //   range.lowerBound <= bounds.upperBound)
    // _precondition(
    //   bounds.lowerBound <= range.upperBound)
    // _precondition(
    //   range.upperBound <= bounds.upperBound)
  }

  @inlinable
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    return self._advanceForward(i, by: distance)
  }

  @inlinable
  public func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    return self._advanceForward(i, by: distance, limitedBy: limit)
  }

  @inlinable
  public func formIndex(_ i: inout Index, offsetBy distance: Int) {
    i = index(i, offsetBy: distance)
  }

  @inlinable
  public func formIndex(
    _ i: inout Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Bool {
    if let advancedIndex = index(i, offsetBy: distance, limitedBy: limit) {
      i = advancedIndex
      return true
    }
    i = limit
    return false
  }

  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    // _precondition(start <= end)

    var start = start
    var count: Int = 0
    while start != end {
      count = count + 1
      formIndex(after: &start)
    }
    return count
  }

  @inlinable
  public func randomElement<T: RandomNumberGenerator>(
    using generator: inout T
  ) -> Element? {
    guard !isEmpty else { return nil }
    let random = Int.random(in: 0 ..< count, using: &generator)
    let idx = index(startIndex, offsetBy: random)
    return self[idx]
  }

  @inlinable
  public func randomElement() -> Element? {
    var g = SystemRandomNumberGenerator()
    return randomElement(using: &g)
  }

  @inlinable
  @inline(__always)
  internal func _advanceForward(_ i: Index, by n: Int) -> Index {
    _precondition(n >= 0)

    var i = i
    for _ in stride(from: 0, to: n, by: 1) {
      formIndex(after: &i)
    }
    return i
  }

  @inlinable
  @inline(__always)
  internal func _advanceForward(
    _ i: Index, by n: Int, limitedBy limit: Index
  ) -> Index? {
    _precondition(n >= 0)

    var i = i
    for _ in stride(from: 0, to: n, by: 1) {
      if i == limit {
        return nil
      }
      formIndex(after: &i)
    }
    return i
  }
}

extension Collection where Iterator == IndexingIterator<Self> {
  @inlinable // trivial-implementation
  @inline(__always)
  public __consuming func makeIterator() -> IndexingIterator<Self> {
    return IndexingIterator(_elements: self)
  }
}

extension Collection where SubSequence == Slice<Self> {
  @inlinable
  public subscript(bounds: Range<Index>) -> Slice<Self> {
    _failEarlyRangeCheck(bounds, bounds: startIndex..<endIndex)
    return Slice(base: self, bounds: bounds)
  }
}

extension Collection where SubSequence == Self {
  @inlinable
  public mutating func popFirst() -> Element? {
    // TODO: swift-3-indexing-model - review the following
    guard !isEmpty else { return nil }
    let element = first!
    self = self[index(after: startIndex)..<endIndex]
    return element
  }
}

extension Collection {
  @inlinable
  public var isEmpty: Bool {
    return startIndex == endIndex
  }

  @inlinable
  public var first: Element? {
    let start = startIndex
    if start != endIndex { return self[start] }
    else { return nil }
  }

  @inlinable
  public var underestimatedCount: Int {
    // TODO: swift-3-indexing-model - review the following
    return count
  }

  @inlinable
  public var count: Int {
    return distance(from: startIndex, to: endIndex)
  }

  // TODO: swift-3-indexing-model - rename the following to _customIndexOfEquatable(element)?
  @inlinable
  @inline(__always)
  public // dispatching
  func _customIndexOfEquatableElement(_: Element) -> Index?? {
    return nil
  }

  @inlinable
  @inline(__always)
  public // dispatching
  func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    return nil
  }
}

//===----------------------------------------------------------------------===//
// Default implementations for Collection
//===----------------------------------------------------------------------===//

extension Collection {
  // @inlinable
  // public func map<T>(
  //   _ transform: (Element) throws -> T
  // ) rethrows -> [T] {
  //   // TODO: swift-3-indexing-model - review the following
  //   let n = self.count
  //   if n == 0 {
  //     return []
  //   }

  //   var result = ContiguousArray<T>()
  //   result.reserveCapacity(n)

  //   var i = self.startIndex

  //   for _ in 0..<n {
  //     result.append(try transform(self[i]))
  //     formIndex(after: &i)
  //   }

  //   _expectEnd(of: self, is: i)
  //   return Array(result)
  // }

  @inlinable
  public __consuming func dropFirst(_ k: Int = 1) -> SubSequence {
    _precondition(k >= 0)
    let start = index(startIndex, offsetBy: k, limitedBy: endIndex) ?? endIndex
    return self[start..<endIndex]
  }

  @inlinable
  public __consuming func dropLast(_ k: Int = 1) -> SubSequence {
    _precondition(
      k >= 0)
    let amount = Swift.max(0, count - k)
    let end = index(startIndex,
      offsetBy: amount, limitedBy: endIndex) ?? endIndex
    return self[startIndex..<end]
  }
    
  @inlinable
  public __consuming func drop(
    while predicate: (Element) throws -> Bool
  ) rethrows -> SubSequence {
    var start = startIndex
    while try start != endIndex && predicate(self[start]) {
      formIndex(after: &start)
    } 
    return self[start..<endIndex]
  }

  @inlinable
  public __consuming func prefix(_ maxLength: Int) -> SubSequence {
    _precondition(
      maxLength >= 0)
    let end = index(startIndex,
      offsetBy: maxLength, limitedBy: endIndex) ?? endIndex
    return self[startIndex..<end]
  }
  
  @inlinable
  public __consuming func prefix(
    while predicate: (Element) throws -> Bool
  ) rethrows -> SubSequence {
    var end = startIndex
    while try end != endIndex && predicate(self[end]) {
      formIndex(after: &end)
    }
    return self[startIndex..<end]
  }

  @inlinable
  public __consuming func suffix(_ maxLength: Int) -> SubSequence {
    _precondition(
      maxLength >= 0)
    let amount = Swift.max(0, count - maxLength)
    let start = index(startIndex,
      offsetBy: amount, limitedBy: endIndex) ?? endIndex
    return self[start..<endIndex]
  }

  @inlinable
  public __consuming func prefix(upTo end: Index) -> SubSequence {
    return self[startIndex..<end]
  }

  @inlinable
  public __consuming func suffix(from start: Index) -> SubSequence {
    return self[start..<endIndex]
  }

  @inlinable
  public __consuming func prefix(through position: Index) -> SubSequence {
    return prefix(upTo: index(after: position))
  }

  // @inlinable
  // public __consuming func split(
  //   maxSplits: Int = Int.max,
  //   omittingEmptySubsequences: Bool = true,
  //   whereSeparator isSeparator: (Element) throws -> Bool
  // ) rethrows -> [SubSequence] {
  //   // TODO: swift-3-indexing-model - review the following
  //   _precondition(maxSplits >= 0)

  //   var result: [SubSequence] = []
  //   var subSequenceStart: Index = startIndex

  //   func appendSubsequence(end: Index) -> Bool {
  //     if subSequenceStart == end && omittingEmptySubsequences {
  //       return false
  //     }
  //     result.append(self[subSequenceStart..<end])
  //     return true
  //   }

  //   if maxSplits == 0 || isEmpty {
  //     _ = appendSubsequence(end: endIndex)
  //     return result
  //   }

  //   var subSequenceEnd = subSequenceStart
  //   let cachedEndIndex = endIndex
  //   while subSequenceEnd != cachedEndIndex {
  //     if try isSeparator(self[subSequenceEnd]) {
  //       let didAppend = appendSubsequence(end: subSequenceEnd)
  //       formIndex(after: &subSequenceEnd)
  //       subSequenceStart = subSequenceEnd
  //       if didAppend && result.count == maxSplits {
  //         break
  //       }
  //       continue
  //     }
  //     formIndex(after: &subSequenceEnd)
  //   }

  //   if subSequenceStart != cachedEndIndex || !omittingEmptySubsequences {
  //     result.append(self[subSequenceStart..<cachedEndIndex])
  //   }

  //   return result
  // }
}

extension Collection where Element : Equatable {
  // @inlinable
  // public __consuming func split(
  //   separator: Element,
  //   maxSplits: Int = Int.max,
  //   omittingEmptySubsequences: Bool = true
  // ) -> [SubSequence] {
  //   // TODO: swift-3-indexing-model - review the following
  //   return split(
  //     maxSplits: maxSplits,
  //     omittingEmptySubsequences: omittingEmptySubsequences,
  //     whereSeparator: { $0 == separator })
  // }
}

extension Collection where SubSequence == Self {
  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
    // TODO: swift-3-indexing-model - review the following
    _precondition(!isEmpty)
    let element = first!
    self = self[index(after: startIndex)..<endIndex]
    return element
  }

  @inlinable
  public mutating func removeFirst(_ k: Int) {
    if k == 0 { return }
    _precondition(k >= 0)
    _precondition(count >= k)
    self = self[index(startIndex, offsetBy: k)..<endIndex]
  }
}
