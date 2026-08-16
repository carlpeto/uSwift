//===--- SequenceAlgorithms.swift -----------------------------*- swift -*-===//
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

//===----------------------------------------------------------------------===//
// enumerated()
//===----------------------------------------------------------------------===//

extension Sequence {
  @inlinable // protocol-only
  public func enumerated() -> EnumeratedSequence<Self> {
    return EnumeratedSequence(_base: self)
  }
}

//===----------------------------------------------------------------------===//
// min(), max()
//===----------------------------------------------------------------------===//

extension Sequence {
  @inlinable // protocol-only
  @warn_unqualified_access
  public func min(
    by areInIncreasingOrder: (Element, Element) throws -> Bool
  ) rethrows -> Element? {
    var it = makeIterator()
    guard var result = it.next() else { return nil }
    while let e = it.next() {
      if try areInIncreasingOrder(e, result) { result = e }
    }
    return result
  }

  @inlinable // protocol-only
  @warn_unqualified_access
  public func max(
    by areInIncreasingOrder: (Element, Element) throws -> Bool
  ) rethrows -> Element? {
    var it = makeIterator()
    guard var result = it.next() else { return nil }
    while let e = it.next() {
      if try areInIncreasingOrder(result, e) { result = e }
    }
    return result
  }
}

extension Sequence where Element: Comparable {
  @inlinable
  @warn_unqualified_access
  public func min() -> Element? {
    return self.min(by: <)
  }

  @inlinable
  @warn_unqualified_access
  public func max() -> Element? {
    return self.max(by: <)
  }
}

//===----------------------------------------------------------------------===//
// starts(with:)
//===----------------------------------------------------------------------===//

extension Sequence  {
  @inlinable
  public func starts<PossiblePrefix: Sequence>(
    with possiblePrefix: PossiblePrefix,
    by areEquivalent: (Element, PossiblePrefix.Element) throws -> Bool
  ) rethrows -> Bool {
    var possiblePrefixIterator = possiblePrefix.makeIterator()
    for e0 in self {
      if let e1 = possiblePrefixIterator.next() {
        if try !areEquivalent(e0, e1) {
          return false
        }
      }
      else {
        return true
      }
    }
    return possiblePrefixIterator.next() == nil
  }
}

extension Sequence where Element: Equatable {
  @inlinable
  public func starts<PossiblePrefix: Sequence>(
    with possiblePrefix: PossiblePrefix
  ) -> Bool where PossiblePrefix.Element == Element {
    return self.starts(with: possiblePrefix, by: ==)
  }
}

//===----------------------------------------------------------------------===//
// elementsEqual()
//===----------------------------------------------------------------------===//

extension Sequence {
  @inlinable
  public func elementsEqual<OtherSequence: Sequence>(
    _ other: OtherSequence,
    by areEquivalent: (Element, OtherSequence.Element) throws -> Bool
  ) rethrows -> Bool {
    var iter1 = self.makeIterator()
    var iter2 = other.makeIterator()
    while true {
      switch (iter1.next(), iter2.next()) {
      case let (e1?, e2?):
        if try !areEquivalent(e1, e2) {
          return false
        }
      case (_?, nil), (nil, _?): return false
      case (nil, nil):           return true
      }
    }
  }
}

extension Sequence where Element : Equatable {
  @inlinable
  public func elementsEqual<OtherSequence: Sequence>(
    _ other: OtherSequence
  ) -> Bool where OtherSequence.Element == Element {
    return self.elementsEqual(other, by: ==)
  }
}

//===----------------------------------------------------------------------===//
// lexicographicallyPrecedes()
//===----------------------------------------------------------------------===//

extension Sequence {
  @inlinable
  public func lexicographicallyPrecedes<OtherSequence: Sequence>(
    _ other: OtherSequence,
    by areInIncreasingOrder: (Element, Element) throws -> Bool
  ) rethrows -> Bool 
  where OtherSequence.Element == Element {
    var iter1 = self.makeIterator()
    var iter2 = other.makeIterator()
    while true {
      if let e1 = iter1.next() {
        if let e2 = iter2.next() {
          if try areInIncreasingOrder(e1, e2) {
            return true
          }
          if try areInIncreasingOrder(e2, e1) {
            return false
          }
          continue // Equivalent
        }
        return false
      }

      return iter2.next() != nil
    }
  }
}

extension Sequence where Element : Comparable {
  @inlinable
  public func lexicographicallyPrecedes<OtherSequence: Sequence>(
    _ other: OtherSequence
  ) -> Bool where OtherSequence.Element == Element {
    return self.lexicographicallyPrecedes(other, by: <)
  }
}

//===----------------------------------------------------------------------===//
// contains()
//===----------------------------------------------------------------------===//

extension Sequence {
  @inlinable
  public func contains(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Bool {
    for e in self {
      if try predicate(e) {
        return true
      }
    }
    return false
  }

  @inlinable
  public func allSatisfy(
    _ predicate: (Element) throws -> Bool
  ) rethrows -> Bool {
    return try !contains { try !predicate($0) }
  }
}

extension Sequence where Element : Equatable {
  @inlinable
  public func contains(_ element: Element) -> Bool {
    if let result = _customContainsEquatableElement(element) {
      return result
    } else {
      return self.contains { $0 == element }
    }
  }
}

//===----------------------------------------------------------------------===//
// reduce()
//===----------------------------------------------------------------------===//

extension Sequence {
  @inlinable
  public func reduce<Result>(
    _ initialResult: Result,
    _ nextPartialResult:
      (_ partialResult: Result, Element) throws -> Result
  ) rethrows -> Result {
    var accumulator = initialResult
    for element in self {
      accumulator = try nextPartialResult(accumulator, element)
    }
    return accumulator
  }
  
  @inlinable
  public func reduce<Result>(
    into initialResult: __owned Result,
    _ updateAccumulatingResult:
      (_ partialResult: inout Result, Element) throws -> ()
  ) rethrows -> Result {
    var accumulator = initialResult
    for element in self {
      try updateAccumulatingResult(&accumulator, element)
    }
    return accumulator
  }
}

//===----------------------------------------------------------------------===//
// reversed()
//===----------------------------------------------------------------------===//

// extension Sequence {
//   @inlinable
//   public __consuming func reversed() -> [Element] {
//     // FIXME(performance): optimize to 1 pass?  But Array(self) can be
//     // optimized to a memcpy() sometimes.  Those cases are usually collections,
//     // though.
//     var result = Array(self)
//     let count = result.count
//     for i in 0..<count/2 {
//       result.swapAt(i, count - ((i + 1) as Int))
//     }
//     return result
//   }
// }

//===----------------------------------------------------------------------===//
// flatMap()
//===----------------------------------------------------------------------===//

// extension Sequence {
//   @inlinable
//   public func flatMap<SegmentOfResult : Sequence>(
//     _ transform: (Element) throws -> SegmentOfResult
//   ) rethrows -> [SegmentOfResult.Element] {
//     var result: [SegmentOfResult.Element] = []
//     for element in self {
//       result.append(contentsOf: try transform(element))
//     }
//     return result
//   }
// }

// extension Sequence {
//   @inlinable // protocol-only
//   public func compactMap<ElementOfResult>(
//     _ transform: (Element) throws -> ElementOfResult?
//   ) rethrows -> [ElementOfResult] {
//     return try _compactMap(transform)
//   }

//   // The implementation of flatMap accepting a closure with an optional result.
//   // Factored out into a separate functions in order to be used in multiple
//   // overloads.
//   @inlinable // protocol-only
//   @inline(__always)
//   public func _compactMap<ElementOfResult>(
//     _ transform: (Element) throws -> ElementOfResult?
//   ) rethrows -> [ElementOfResult] {
//     var result: [ElementOfResult] = []
//     for element in self {
//       if let newElement = try transform(element) {
//         result.append(newElement)
//       }
//     }
//     return result
//   }
// }
