//===--- CollectionAlgorithms.swift.gyb -----------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// last
//===----------------------------------------------------------------------===//

extension BidirectionalCollection {
  @inlinable
  public var last: Element? {
    return isEmpty ? nil : self[index(before: endIndex)]
  }
}

//===----------------------------------------------------------------------===//
// firstIndex(of:)/firstIndex(where:)
//===----------------------------------------------------------------------===//

extension Collection where Element : Equatable {
  @inlinable
  public func firstIndex(of element: Element) -> Index? {
    if let result = _customIndexOfEquatableElement(element) {
      return result
    }

    var i = self.startIndex
    while i != self.endIndex {
      if self[i] == element {
        return i
      }
      self.formIndex(after: &i)
    }
    return nil
  }
}

extension Collection {
  @inlinable
  public func firstIndex(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Index? {
    var i = self.startIndex
    while i != self.endIndex {
      if try predicate(self[i]) {
        return i
      }
      self.formIndex(after: &i)
    }
    return nil
  }
}

//===----------------------------------------------------------------------===//
// lastIndex(of:)/lastIndex(where:)
//===----------------------------------------------------------------------===//

extension BidirectionalCollection {
  @inlinable
  public func last(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Element? {
    return try lastIndex(where: predicate).map { self[$0] }
  }

  @inlinable
  public func lastIndex(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Index? {
    var i = endIndex
    while i != startIndex {
      formIndex(before: &i)
      if try predicate(self[i]) {
        return i
      }
    }
    return nil
  }
}

extension BidirectionalCollection where Element : Equatable {
  @inlinable
  public func lastIndex(of element: Element) -> Index? {
    if let result = _customLastIndexOfEquatableElement(element) {
      return result
    }
    return lastIndex(where: { $0 == element })
  }
}

//===----------------------------------------------------------------------===//
// partition(by:)
//===----------------------------------------------------------------------===//

extension MutableCollection {
  @inlinable
  public mutating func partition(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Index {
    return try _halfStablePartition(isSuffixElement: belongsInSecondPartition)
  }

  @inlinable
  internal mutating func _halfStablePartition(
    isSuffixElement: (Element) throws -> Bool
  ) rethrows -> Index {
    guard var i = try firstIndex(where: isSuffixElement)
    else { return endIndex }
    
    var j = index(after: i)
    while j != endIndex {
      if try !isSuffixElement(self[j]) { swapAt(i, j); formIndex(after: &i) }
      formIndex(after: &j)
    }
    return i
  }  
}

extension MutableCollection where Self : BidirectionalCollection {
  @inlinable
  public mutating func partition(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Index {
    let maybeOffset = try _withUnsafeMutableBufferPointerIfSupported {
      (bufferPointer) -> Int in
      let unsafeBufferPivot = try bufferPointer._partitionImpl(
        by: belongsInSecondPartition)
      return unsafeBufferPivot - bufferPointer.startIndex
    }
    if let offset = maybeOffset {
      return index(startIndex, offsetBy: offset)
    } else {
      return try _partitionImpl(by: belongsInSecondPartition)
    }
  }
  
  @usableFromInline
  internal mutating func _partitionImpl(
    by belongsInSecondPartition: (Element) throws -> Bool
  ) rethrows -> Index {
    var lo = startIndex
    var hi = endIndex

    // 'Loop' invariants (at start of Loop, all are true):
    // * lo < hi
    // * predicate(self[i]) == false, for i in startIndex ..< lo
    // * predicate(self[i]) == true, for i in hi ..< endIndex

    Loop: while true {
      FindLo: repeat {
        while lo < hi {
          if try belongsInSecondPartition(self[lo]) { break FindLo }
          formIndex(after: &lo)
        }
        break Loop
      } while false

      FindHi: repeat {
        formIndex(before: &hi)
        while lo < hi {
          if try !belongsInSecondPartition(self[hi]) { break FindHi }
          formIndex(before: &hi)
        }
        break Loop
      } while false

      swapAt(lo, hi)
      formIndex(after: &lo)
    }

    return lo
  }
}

//===----------------------------------------------------------------------===//
// shuffled()/shuffle()
//===----------------------------------------------------------------------===//

// extension Sequence {
//   @inlinable
//   public func shuffled<T: RandomNumberGenerator>(
//     using generator: inout T
//   ) -> [Element] {
//     var result = ContiguousArray(self)
//     result.shuffle(using: &generator)
//     return Array(result)
//   }
  
//   @inlinable
//   public func shuffled() -> [Element] {
//     var g = SystemRandomNumberGenerator()
//     return shuffled(using: &g)
//   }
// }

extension MutableCollection where Self : RandomAccessCollection {
  @inlinable
  public mutating func shuffle<T: RandomNumberGenerator>(
    using generator: inout T
  ) {
    guard count > 1 else { return }
    var amount = count
    var currentIndex = startIndex
    while amount > 1 {
      let random = Int.random(in: 0 ..< amount, using: &generator)
      amount -= 1
      swapAt(
        currentIndex,
        index(currentIndex, offsetBy: random)
      )
      formIndex(after: &currentIndex)
    }
  }
  
  @inlinable
  public mutating func shuffle() {
    var g = SystemRandomNumberGenerator()
    shuffle(using: &g)
  }
}
