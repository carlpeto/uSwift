//===--- Random.swift -----------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import uSwiftShims

public protocol RandomNumberGenerator {
  mutating func next() -> UInt32
}

extension RandomNumberGenerator {
  @inlinable
  public mutating func next<T: FixedWidthInteger & UnsignedInteger>() -> T {
    return T._random(using: &self)
  }

  @inlinable
  public mutating func next<T: FixedWidthInteger & UnsignedInteger>(
    upperBound: T
  ) -> T {
    _precondition(upperBound != 0)
    var random: T = next()
    var m = random.multipliedFullWidth(by: upperBound)
    if m.low < upperBound {
      let t = (0 &- upperBound) % upperBound
      while m.low < t {
        random = next()
        m = random.multipliedFullWidth(by: upperBound)
      }
    }
    return m.high
  }
}

@frozen
public struct SystemRandomNumberGenerator : RandomNumberGenerator {
  @inlinable
  public init() { }

  @inlinable
  public mutating func next() -> UInt32 {
    // from the AVR Library
    return UInt32(_longRandom())
    // var random: UInt32 = 0
    // swift_stdlib_random(&random, UInt16(MemoryLayout<UInt32>.size))
    // return random
  }
}
