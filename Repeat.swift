//===--- Repeat.swift - A Collection that repeats a value N times ---------===//
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

@frozen
public struct Repeated<Element> {
  public let count: Int

  public let repeatedValue: Element
}

extension Repeated: RandomAccessCollection {
  public typealias Indices = Range<Int>

  public typealias Index = Int

  @inlinable // trivial-implementation
  internal init(_repeating repeatedValue: Element, count: Int) {
    _precondition(count >= 0)
    self.count = count
    self.repeatedValue = repeatedValue
  }
  
  @inlinable // trivial-implementation
  public var startIndex: Index {
    return 0
  }

  @inlinable // trivial-implementation
  public var endIndex: Index {
    return count
  }

  @inlinable // trivial-implementation
  public subscript(position: Int) -> Element {
    // _precondition(position >= 0 && position < count)
    return repeatedValue
  }
}

@inlinable // trivial-implementation
public func repeatElement<T>(_ element: T, count n: Int) -> Repeated<T> {
  return Repeated(_repeating: element, count: n)
}
