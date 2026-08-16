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

public protocol RandomAccessCollection: BidirectionalCollection
where SubSequence: RandomAccessCollection, Indices: RandomAccessCollection
{
  // FIXME: Associated type inference requires these.
  override associatedtype Element
  override associatedtype Index
  override associatedtype SubSequence
  override associatedtype Indices

  override var indices: Indices { get }

  override subscript(bounds: Range<Index>) -> SubSequence { get }

  // FIXME: Associated type inference requires these.
  @_borrowed
  override subscript(position: Index) -> Element { get }
  override var startIndex: Index { get }
  override var endIndex: Index { get }

  override func index(before i: Index) -> Index

  override func formIndex(before i: inout Index)

  override func index(after i: Index) -> Index

  override func formIndex(after i: inout Index)

  @_nonoverride func index(_ i: Index, offsetBy distance: Int) -> Index

  @_nonoverride func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index?

  @_nonoverride func distance(from start: Index, to end: Index) -> Int
}

// TODO: swift-3-indexing-model - (By creating an ambiguity?), try to
// make sure RandomAccessCollection models implement
// index(_:offsetBy:) and distance(from:to:), or they will get the
// wrong complexity.

extension RandomAccessCollection {
  @inlinable
  public func index(
    _ i: Index, offsetBy distance: Int, limitedBy limit: Index
  ) -> Index? {
    // FIXME: swift-3-indexing-model: tests.
    let l = self.distance(from: i, to: limit)
    if distance > 0 ? l >= 0 && l < distance : l <= 0 && distance < l {
      return nil
    }
    return index(i, offsetBy: distance)
  }
}

// Provides an alternative default associated type witness for Indices
// for random access collections with strideable indices.
extension RandomAccessCollection where Index : Strideable, Index.Stride == Int {
  @_implements(Collection, Indices)
  public typealias _Default_Indices = Range<Index>
}

extension RandomAccessCollection
where Index : Strideable, 
      Index.Stride == Int,
      Indices == Range<Index> {

  @inlinable
  public var indices: Range<Index> {
    return startIndex..<endIndex
  }

  @inlinable
  public func index(after i: Index) -> Index {
    // FIXME: swift-3-indexing-model: tests for the trap.
    _failEarlyRangeCheck(
      i, bounds: Range(uncheckedBounds: (startIndex, endIndex)))
    return i.advanced(by: 1)
  }

  @inlinable // protocol-only
  public func index(before i: Index) -> Index {
    let result = i.advanced(by: -1)
    // FIXME: swift-3-indexing-model: tests for the trap.
    _failEarlyRangeCheck(
      result, bounds: Range(uncheckedBounds: (startIndex, endIndex)))
    return result
  }

  @inlinable
  public func index(_ i: Index, offsetBy distance: Index.Stride) -> Index {
    let result = i.advanced(by: distance)
    // This range check is not precise, tighter bounds exist based on `n`.
    // Unfortunately, we would need to perform index manipulation to
    // compute those bounds, which is probably too slow in the general
    // case.
    // FIXME: swift-3-indexing-model: tests for the trap.
    _failEarlyRangeCheck(
      result, bounds: ClosedRange(uncheckedBounds: (startIndex, endIndex)))
    return result
  }
  
  @inlinable
  public func distance(from start: Index, to end: Index) -> Index.Stride {
    // FIXME: swift-3-indexing-model: tests for traps.
    _failEarlyRangeCheck(
      start, bounds: ClosedRange(uncheckedBounds: (startIndex, endIndex)))
    _failEarlyRangeCheck(
      end, bounds: ClosedRange(uncheckedBounds: (startIndex, endIndex)))
    return start.distance(to: end)
  }
}


