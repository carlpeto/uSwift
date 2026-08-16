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

public protocol MutableCollection: Collection
where SubSequence: MutableCollection
{
  // FIXME: Associated type inference requires these.
  override associatedtype Element
  override associatedtype Index
  override associatedtype SubSequence

  @_borrowed
  override subscript(position: Index) -> Element { get set }

  override subscript(bounds: Range<Index>) -> SubSequence { get set }

  mutating func partition(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Index

  mutating func swapAt(_ i: Index, _ j: Index)
  
  mutating func _withUnsafeMutableBufferPointerIfSupported<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R?

  mutating func withContiguousMutableStorageIfAvailable<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R?
}

// TODO: swift-3-indexing-model - review the following
extension MutableCollection {
  @inlinable
  public mutating func _withUnsafeMutableBufferPointerIfSupported<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return nil
  }

  @inlinable
  public mutating func withContiguousMutableStorageIfAvailable<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return nil
  }

  @inlinable
  public subscript(bounds: Range<Index>) -> Slice<Self> {
    get {
      _failEarlyRangeCheck(bounds, bounds: startIndex..<endIndex)
      return Slice(base: self, bounds: bounds)
    }
    set {
      _writeBackMutableSlice(&self, bounds: bounds, slice: newValue)
    }
  }

  @inlinable
  public mutating func swapAt(_ i: Index, _ j: Index) {
    guard i != j else { return }
    let tmp = self[i]
    self[i] = self[j]
    self[j] = tmp
  }
}

// the legacy swap free function
//
// @inlinable
// public func swap<T>(_ a: inout T, _ b: inout T) {
//   // Semantically equivalent to (a, b) = (b, a).
//   // Microoptimized to avoid retain/release traffic.
//   let p1 = Builtin.addressof(&a)
//   let p2 = Builtin.addressof(&b)
//   _debugPrecondition(
//     p1 != p2)

//   // Take from P1.
//   let tmp: T = Builtin.take(p1)
//   // Transfer P2 into P1.
//   Builtin.initialize(Builtin.take(p2) as T, p1)
//   // Initialize P2.
//   Builtin.initialize(tmp, p2)
// }

@inlinable
@_preInverseGenerics
public func swap<T: ~Copyable>(_ a: inout T, _ b: inout T) {
  let temp = consume a
  a = consume b
  b = consume temp
}

/// Replaces the value of a mutable value with the supplied new value,
/// returning the original.
///
/// - Parameters:
///   - item: A mutable binding.
///   - newValue: The new value of `item`.
/// - Returns: The original value of `item`.
@_alwaysEmitIntoClient
public func exchange<T: ~Copyable>(
  _ item: inout T,
  with newValue: consuming T
) -> T {
  let oldValue = consume item
  item = consume newValue
  return oldValue
}