//===--- RangeReplaceableCollection.swift ---------------------------------===//
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
// A Collection protocol with replaceSubrange.
//
//===----------------------------------------------------------------------===//

public protocol RangeReplaceableCollection : Collection
  where SubSequence : RangeReplaceableCollection {
  // FIXME: Associated type inference requires this.
  override associatedtype SubSequence

  //===--- Fundamental Requirements ---------------------------------------===//

  init()

  mutating func replaceSubrange<C>(
    _ subrange: Range<Index>,
    with newElements: __owned C
  ) where C : Collection, C.Element == Element

  mutating func reserveCapacity(_ n: Int)

  //===--- Derivable Requirements -----------------------------------------===//

  init(repeating repeatedValue: Element, count: Int)

  init<S : Sequence>(_ elements: S)
    where S.Element == Element

  mutating func append(_ newElement: __owned Element)

  mutating func append<S : Sequence>(contentsOf newElements: __owned S)
    where S.Element == Element
  // FIXME(ABI)#166 (Evolution): Consider replacing .append(contentsOf) with +=
  // suggestion in SE-91

  mutating func insert(_ newElement: __owned Element, at i: Index)

  mutating func insert<S : Collection>(contentsOf newElements: __owned S, at i: Index)
    where S.Element == Element

  @discardableResult
  mutating func remove(at i: Index) -> Element

  mutating func removeSubrange(_ bounds: Range<Index>)

  mutating func _customRemoveLast() -> Element?

  mutating func _customRemoveLast(_ n: Int) -> Bool

  @discardableResult
  mutating func removeFirst() -> Element

  mutating func removeFirst(_ k: Int)

  mutating func removeAll(keepingCapacity keepCapacity: Bool /*= false*/)

  mutating func removeAll(
    where shouldBeRemoved: (Element) throws -> Bool) rethrows

  // FIXME: Associated type inference requires these.
  @_borrowed
  override subscript(bounds: Index) -> Element { get }
  override subscript(bounds: Range<Index>) -> SubSequence { get }
}

//===----------------------------------------------------------------------===//
// Default implementations for RangeReplaceableCollection
//===----------------------------------------------------------------------===//

extension RangeReplaceableCollection {
  @inlinable
  public init(repeating repeatedValue: Element, count: Int) {
    self.init()
    if count != 0 {
      let elements = Repeated(_repeating: repeatedValue, count: count)
      append(contentsOf: elements)
    }
  }

  @inlinable
  public init<S : Sequence>(_ elements: S)
    where S.Element == Element {
    self.init()
    append(contentsOf: elements)
  }

  @inlinable
  public mutating func append(_ newElement: __owned Element) {
    insert(newElement, at: endIndex)
  }

  @inlinable
  public mutating func append<S : Sequence>(contentsOf newElements: __owned S)
    where S.Element == Element {

    let approximateCapacity = self.count +
      numericCast(newElements.underestimatedCount)
    self.reserveCapacity(approximateCapacity)
    for element in newElements {
      append(element)
    }
  }

  @inlinable
  public mutating func insert(
    _ newElement: __owned Element, at i: Index
  ) {
    replaceSubrange(i..<i, with: CollectionOfOne(newElement))
  }

  @inlinable
  public mutating func insert<C : Collection>(
    contentsOf newElements: __owned C, at i: Index
  ) where C.Element == Element {
    replaceSubrange(i..<i, with: newElements)
  }

  @inlinable
  @discardableResult
  public mutating func remove(at position: Index) -> Element {
    _precondition(!isEmpty)
    let result: Element = self[position]
    replaceSubrange(position..<index(after: position), with: EmptyCollection())
    return result
  }

  @inlinable
  public mutating func removeSubrange(_ bounds: Range<Index>) {
    replaceSubrange(bounds, with: EmptyCollection())
  }

  @inlinable
  public mutating func removeFirst(_ k: Int) {
    if k == 0 { return }
    _precondition(k >= 0)
    _precondition(count >= k)
    let end = index(startIndex, offsetBy: k)
    removeSubrange(startIndex..<end)
  }

  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
    _precondition(!isEmpty)
    let firstElement = first!
    removeFirst(1)
    return firstElement
  }

  @inlinable
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    if !keepCapacity {
      self = Self()
    }
    else {
      replaceSubrange(startIndex..<endIndex, with: EmptyCollection())
    }
  }

  @inlinable
  public mutating func reserveCapacity(_ n: Int) {}
}

extension RangeReplaceableCollection where SubSequence == Self {
  @inlinable
  @discardableResult
  public mutating func removeFirst() -> Element {
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

extension RangeReplaceableCollection {
  @inlinable
  public mutating func replaceSubrange<C: Collection, R: RangeExpression>(
    _ subrange: R,
    with newElements: __owned C
  ) where C.Element == Element, R.Bound == Index {
    self.replaceSubrange(subrange.relative(to: self), with: newElements)
  }

  @inlinable
  public mutating func removeSubrange<R: RangeExpression>(
    _ bounds: R
  ) where R.Bound == Index  {
    removeSubrange(bounds.relative(to: self))
  }
}

extension RangeReplaceableCollection {
  @inlinable
  public mutating func _customRemoveLast() -> Element? {
    return nil
  }

  @inlinable
  public mutating func _customRemoveLast(_ n: Int) -> Bool {
    return false
  }
}

extension RangeReplaceableCollection
  where Self : BidirectionalCollection, SubSequence == Self {

  @inlinable
  public mutating func _customRemoveLast() -> Element? {
    let element = last!
    self = self[startIndex..<index(before: endIndex)]
    return element
  }

  @inlinable
  public mutating func _customRemoveLast(_ n: Int) -> Bool {
    self = self[startIndex..<index(endIndex, offsetBy: numericCast(-n))]
    return true
  }
}

extension RangeReplaceableCollection where Self : BidirectionalCollection {
  @inlinable
  public mutating func popLast() -> Element? {
    if isEmpty { return nil }
    // duplicate of removeLast logic below, to avoid redundant precondition
    if let result = _customRemoveLast() { return result }
    return remove(at: index(before: endIndex))
  }

  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    _precondition(!isEmpty)
    // NOTE if you change this implementation, change popLast above as well
    // AND change the tie-breaker implementations in the next extension
    if let result = _customRemoveLast() { return result }
    return remove(at: index(before: endIndex))
  }

  @inlinable
  public mutating func removeLast(_ k: Int) {
    if k == 0 { return }
    _precondition(k >= 0)
    _precondition(count >= k)
    if _customRemoveLast(k) {
      return
    }
    let end = endIndex
    removeSubrange(index(end, offsetBy: -k)..<end)
  }
}

extension RangeReplaceableCollection
where Self : BidirectionalCollection, SubSequence == Self {
  @inlinable
  public mutating func popLast() -> Element? {
    if isEmpty { return nil }
    // duplicate of removeLast logic below, to avoid redundant precondition
    if let result = _customRemoveLast() { return result }
    return remove(at: index(before: endIndex))
  }

  @inlinable
  @discardableResult
  public mutating func removeLast() -> Element {
    _precondition(!isEmpty)
    // NOTE if you change this implementation, change popLast above as well
    if let result = _customRemoveLast() { return result }
    return remove(at: index(before: endIndex))
  }

  @inlinable
  public mutating func removeLast(_ k: Int) {
    if k == 0 { return }
    _precondition(k >= 0)
    _precondition(count >= k)
    if _customRemoveLast(k) {
      return
    }
    let end = endIndex
    removeSubrange(index(end, offsetBy: -k)..<end)
  }
}

extension RangeReplaceableCollection {
  @inlinable
  public static func + <
    Other : Sequence
  >(lhs: Self, rhs: Other) -> Self
  where Element == Other.Element {
    var lhs = lhs
    // FIXME: what if lhs is a reference type?  This will mutate it.
    lhs.append(contentsOf: rhs)
    return lhs
  }

  @inlinable
  public static func + <
    Other : Sequence
  >(lhs: Other, rhs: Self) -> Self
  where Element == Other.Element {
    var result = Self()
    result.reserveCapacity(rhs.count + numericCast(lhs.underestimatedCount))
    result.append(contentsOf: lhs)
    result.append(contentsOf: rhs)
    return result
  }

  @inlinable
  public static func += <
    Other : Sequence
  >(lhs: inout Self, rhs: Other)
  where Element == Other.Element {
    lhs.append(contentsOf: rhs)
  }

  @inlinable
  public static func + <
    Other : RangeReplaceableCollection
  >(lhs: Self, rhs: Other) -> Self
  where Element == Other.Element {
    var lhs = lhs
    // FIXME: what if lhs is a reference type?  This will mutate it.
    lhs.append(contentsOf: rhs)
    return lhs
  }
}

// don't know why this doesn't compile
// don't know where self.lazy is defined, which doesn't help
extension RangeReplaceableCollection {
  @inlinable
  @available(swift, introduced: 4.0)
  public __consuming func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> Self {
    // let i:Int = self.lazy
    // return try Self(self.lazy.filter(isIncluded))
    return self
  }
}

extension RangeReplaceableCollection where Self: MutableCollection {
  @inlinable
  public mutating func removeAll(
    where shouldBeRemoved: (Element) throws -> Bool
  ) rethrows {
    // let suffixStart = try _halfStablePartition(isSuffixElement: shouldBeRemoved)
    // removeSubrange(suffixStart...)
  }
}

// don't know why this doesn't compile
// don't know where self.lazy is defined, which doesn't help
extension RangeReplaceableCollection {
  @inlinable
  public mutating func removeAll(
    where shouldBeRemoved: (Element) throws -> Bool
  ) rethrows {
    // FIXME: Switch to using RRC.filter once stdlib is compiled for 4.0
    // self = try filter { try !predicate($0) }
    // self = try Self(self.lazy.filter { try !shouldBeRemoved($0) })
  }
}
