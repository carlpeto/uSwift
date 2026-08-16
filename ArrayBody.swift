//===--- ArrayBody.swift - Data needed once per array ---------------------===//
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
//  Array storage begins with a Body and ends with a sequence of
//  contiguous Elements.  This struct describes the Body part.
//
//===----------------------------------------------------------------------===//

import uSwiftShims

@frozen
@usableFromInline
internal struct _ArrayBody {
  @usableFromInline
  internal var _storage: _SwiftArrayBodyStorage

  @inlinable
  internal init(
    count: Int, capacity: Int, elementTypeIsBridgedVerbatim: Bool = false
  ) {
    _internalInvariant(count >= 0)
    _internalInvariant(capacity >= 0)
    
    _storage = _SwiftArrayBodyStorage(
      count: count,
      _capacityAndFlags:
        (UInt(truncatingIfNeeded: capacity) &<< 1 |
        (elementTypeIsBridgedVerbatim ? 1 : 0)))
  }

  @inlinable
  internal init() {
    _storage = _SwiftArrayBodyStorage(count: 0, _capacityAndFlags: 0)
  }
  
  @inlinable
  internal var count: Int {
    get {
      return Int(_assumeNonNegative(_storage.count))
    }
    set(newCount) {
      _storage.count = newCount
    }
  }

  @inlinable
  internal var capacity: Int {
    return Int(_capacityAndFlags &>> 1)
  }

  @inlinable
  internal var elementTypeIsBridgedVerbatim: Bool {
    get {
      return (_capacityAndFlags & 0x1) != 0
    }
    set {
      _capacityAndFlags
        = newValue ? _capacityAndFlags | 1 : _capacityAndFlags & ~1
    }
  }

  @inlinable
  internal var _capacityAndFlags: UInt {
    get {
      return UInt(_storage._capacityAndFlags)
    }
    set {
      _storage._capacityAndFlags = newValue
    }
  }
}
