import uSwiftShims

public protocol Hashable : Equatable {
  var hashValue: Int { get }

  func hash(into hasher: inout Hasher)

  // Raw top-level hashing interface. Some standard library types (mostly
  // primitives) specialize this to eliminate small resiliency overheads. (This
  // only matters for tiny keys.)
  func _rawHashValue(seed: Int) -> Int
}

extension Hashable {
  @inlinable
  @inline(__always)
  public func _rawHashValue(seed: Int) -> Int {
    var hasher = Hasher(_seed: seed)
    hasher.combine(self)
    return hasher._finalize()
  }
}

// Called by synthesized `hashValue` implementations.
@inlinable
@inline(__always)
public func _hashValue<H: Hashable>(for value: H) -> Int {
  return value._rawHashValue(seed: 0)
}

// Called by the SwiftValue implementation.
@_silgen_name("_swift_stdlib_Hashable_isEqual_indirect")
internal func Hashable_isEqual_indirect<T : Hashable>(
  _ lhs: UnsafePointer<T>,
  _ rhs: UnsafePointer<T>
) -> Bool {
  return lhs.pointee == rhs.pointee
}

// Called by the SwiftValue implementation.
@_silgen_name("_swift_stdlib_Hashable_hashValue_indirect")
internal func Hashable_hashValue_indirect<T : Hashable>(
  _ value: UnsafePointer<T>
) -> Int {
  return value.pointee.hashValue
}

@inline(__always)
internal func _loadPartialUnalignedUInt64LE(
  _ p: UnsafeRawPointer,
  byteCount: Int
) -> UInt64 {
  var result: UInt64 = 0
  switch byteCount {
  case 7:
    result |= UInt64(p.load(fromByteOffset: 6, as: UInt8.self)) &<< 48
    fallthrough
  case 6:
    result |= UInt64(p.load(fromByteOffset: 5, as: UInt8.self)) &<< 40
    fallthrough
  case 5:
    result |= UInt64(p.load(fromByteOffset: 4, as: UInt8.self)) &<< 32
    fallthrough
  case 4:
    result |= UInt64(p.load(fromByteOffset: 3, as: UInt8.self)) &<< 24
    fallthrough
  case 3:
    result |= UInt64(p.load(fromByteOffset: 2, as: UInt8.self)) &<< 16
    fallthrough
  case 2:
    result |= UInt64(p.load(fromByteOffset: 1, as: UInt8.self)) &<< 8
    fallthrough
  case 1:
    result |= UInt64(p.load(fromByteOffset: 0, as: UInt8.self))
    fallthrough
  case 0:
    return result
  default:
    _internalInvariantFailure()
  }
}

extension Hasher {
  // FIXME: Remove @usableFromInline and @frozen once Hasher is resilient.
  // rdar://problem/38549901
  @usableFromInline @frozen
  internal struct _TailBuffer {
    // msb                                                             lsb
    // +---------+-------+-------+-------+-------+-------+-------+-------+
    // |byteCount|                 tail (<= 56 bits)                     |
    // +---------+-------+-------+-------+-------+-------+-------+-------+
    internal var value: UInt64

    @inline(__always)
    internal init() {
      self.value = 0
    }

    @inline(__always)
    internal init(tail: UInt64, byteCount: UInt64) {
      // byteCount can be any value, but we only keep the lower 8 bits.  (The
      // lower three bits specify the count of bytes stored in this buffer.)
      // FIXME: This should be a single expression, but it causes exponential
      // behavior in the expression type checker <rdar://problem/42672946>.
      let shiftedByteCount: UInt64 = ((byteCount & 7) << 3)
      let mask: UInt64 = (1 << shiftedByteCount - 1)
      _internalInvariant(tail & ~mask == 0)
      self.value = (byteCount &<< 56 | tail)
    }

    @inline(__always)
    internal init(tail: UInt64, byteCount: Int) {
      self.init(tail: tail, byteCount: UInt64(truncatingIfNeeded: byteCount))
    }

    internal var tail: UInt64 {
      @inline(__always)
      get { return value & ~(0xFF &<< 56) }
    }

    internal var byteCount: UInt64 {
      @inline(__always)
      get { return value &>> 56 }
    }

    @inline(__always)
    internal mutating func append(_ bytes: UInt64) -> UInt64 {
      let c = byteCount & 7
      if c == 0 {
        value = value &+ (8 &<< 56)
        return bytes
      }
      let shift = c &<< 3
      let chunk = tail | (bytes &<< shift)
      value = (((value &>> 56) &+ 8) &<< 56) | (bytes &>> (64 - shift))
      return chunk
    }

    @inline(__always)
    internal
    mutating func append(_ bytes: UInt64, count: UInt64) -> UInt64? {
      _internalInvariant(count >= 0 && count < 8)
      _internalInvariant(bytes & ~((1 &<< (count &<< 3)) &- 1) == 0)
      let c = byteCount & 7
      let shift = c &<< 3
      if c + count < 8 {
        value = (value | (bytes &<< shift)) &+ (count &<< 56)
        return nil
      }
      let chunk = tail | (bytes &<< shift)
      value = ((value &>> 56) &+ count) &<< 56
      if c + count > 8 {
        value |= bytes &>> (64 - shift)
      }
      return chunk
    }
  }
}

extension Hasher {
  // FIXME: Remove @usableFromInline and @frozen once Hasher is resilient.
  // rdar://problem/38549901
  @usableFromInline @frozen
  internal struct _Core {
    private var _buffer: _TailBuffer
    private var _state: Hasher._State

    @inline(__always)
    internal init(state: Hasher._State) {
      self._buffer = _TailBuffer()
      self._state = state
    }

    @inline(__always)
    internal init() {
      self.init(state: _State())
    }

    @inline(__always)
    internal init(seed: Int) {
      self.init(state: _State(seed: seed))
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt) {
#if arch(i386) || arch(arm)
      combine(UInt32(truncatingIfNeeded: value))
#else
      combine(UInt64(truncatingIfNeeded: value))
#endif
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt64) {
      _state.compress(_buffer.append(value))
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt32) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 4) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt16) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 2) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal mutating func combine(_ value: UInt8) {
      let value = UInt64(truncatingIfNeeded: value)
      if let chunk = _buffer.append(value, count: 1) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal mutating func combine(bytes: UInt64, count: Int) {
      _internalInvariant(count >= 0 && count < 8)
      let count = UInt64(truncatingIfNeeded: count)
      if let chunk = _buffer.append(bytes, count: count) {
        _state.compress(chunk)
      }
    }

    @inline(__always)
    internal mutating func combine(bytes: UnsafeRawBufferPointer) {
      var remaining = bytes.count
      guard remaining > 0 else { return }
      var data = bytes.baseAddress!

      // Load first unaligned partial word of data
      do {
        let start = UInt(bitPattern: data)
        let end = _roundUp(start, toAlignment: MemoryLayout<UInt64>.alignment)
        let c = min(remaining, Int(end - start))
        if c > 0 {
          let chunk = _loadPartialUnalignedUInt64LE(data, byteCount: c)
          combine(bytes: chunk, count: c)
          data += c
          remaining -= c
        }
      }
      _internalInvariant(
        remaining == 0 ||
        Int(bitPattern: data) & (MemoryLayout<UInt64>.alignment - 1) == 0)

      // Load as many aligned words as there are in the input buffer
      while remaining >= MemoryLayout<UInt64>.size {
        combine(data.load(as: UInt64.self))
        data += MemoryLayout<UInt64>.size
        remaining -= MemoryLayout<UInt64>.size
      }

      // Load last partial word of data
      _internalInvariant(remaining >= 0 && remaining < 8)
      if remaining > 0 {
        let chunk = _loadPartialUnalignedUInt64LE(data, byteCount: remaining)
        combine(bytes: chunk, count: remaining)
      }
    }

    @inline(__always)
    internal mutating func finalize() -> UInt64 {
      return _state.finalize(tailAndByteCount: _buffer.value)
    }
  }
}

@frozen // FIXME: Should be resilient (rdar://problem/38549901)
public struct Hasher {
  internal var _core: _Core

  @_effects(releasenone)
  public init() {
    self._core = _Core()
  }

  @usableFromInline
  @_effects(releasenone)
  internal init(_seed: Int) {
    self._core = _Core(seed: _seed)
  }

  @usableFromInline // @testable
  @_effects(releasenone)
  internal init(_rawSeed: (UInt64, UInt64)) {
    self._core = _Core(state: _State(rawSeed: _rawSeed))
  }

  @inlinable
  internal static var _isDeterministic: Bool {
    @inline(__always)
    get {
      return _swift_stdlib_Hashing_parameters.deterministic
    }
  }

  @inlinable // @testable
  internal static var _executionSeed: (UInt64, UInt64) {
    @inline(__always)
    get {
      // The seed itself is defined in C++ code so that it is initialized during
      // static construction.  Almost every Swift program uses hash tables, so
      // initializing the seed during the startup seems to be the right
      // trade-off.
      return (
        _swift_stdlib_Hashing_parameters.seed0,
        _swift_stdlib_Hashing_parameters.seed1)
    }
  }

  @inlinable
  @inline(__always)
  public mutating func combine<H: Hashable>(_ value: H) {
    value.hash(into: &self)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func _combine(_ value: UInt) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func _combine(_ value: UInt64) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func _combine(_ value: UInt32) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func _combine(_ value: UInt16) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func _combine(_ value: UInt8) {
    _core.combine(value)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func _combine(bytes value: UInt64, count: Int) {
    _core.combine(bytes: value, count: count)
  }

  @_effects(releasenone)
  public mutating func combine(bytes: UnsafeRawBufferPointer) {
    _core.combine(bytes: bytes)
  }

  @_effects(releasenone)
  @usableFromInline
  internal mutating func _finalize() -> Int {
    return Int(truncatingIfNeeded: _core.finalize())
  }

  @_effects(releasenone)
  public __consuming func finalize() -> Int {
    var core = _core
    return Int(truncatingIfNeeded: core.finalize())
  }

  @_effects(readnone)
  @usableFromInline
  internal static func _hash(seed: Int, _ value: UInt64) -> Int {
    var state = _State(seed: seed)
    state.compress(value)
    let tbc = _TailBuffer(tail: 0, byteCount: Int(8))
    return Int(truncatingIfNeeded: state.finalize(tailAndByteCount: tbc.value))
  }

  @_effects(readnone)
  @usableFromInline
  internal static func _hash(seed: Int, _ value: UInt) -> Int {
    var state = _State(seed: seed)
#if arch(i386) || arch(arm)
    _internalInvariant(UInt.bitWidth < UInt64.bitWidth)
    let tbc = _TailBuffer(
      tail: UInt64(truncatingIfNeeded: value),
      byteCount: UInt.bitWidth &>> 3)
#else
    _internalInvariant(UInt.bitWidth == UInt64.bitWidth)
    state.compress(UInt64(truncatingIfNeeded: value))
    let tbc = _TailBuffer(tail: 0, byteCount: Int(8))
#endif
    return Int(truncatingIfNeeded: state.finalize(tailAndByteCount: tbc.value))
  }

  @_effects(readnone)
  @usableFromInline
  internal static func _hash(
    seed: Int,
    bytes value: UInt64,
    count: Int) -> Int {
    _internalInvariant(count >= 0 && count < 8)
    var state = _State(seed: seed)
    let tbc = _TailBuffer(tail: value, byteCount: count)
    return Int(truncatingIfNeeded: state.finalize(tailAndByteCount: tbc.value))
  }

  @_effects(readnone)
  @usableFromInline
  internal static func _hash(
    seed: Int,
    bytes: UnsafeRawBufferPointer) -> Int {
    var core = _Core(seed: seed)
    core.combine(bytes: bytes)
    return Int(truncatingIfNeeded: core.finalize())
  }
}

// @usableFromInline @_transparent
// internal var _hashContainerDefaultMaxLoadFactorInverse: Float {
//   return 1.0 / 0.75
// }

// internal struct _UnmanagedAnyObjectArray {
//   internal var value: UnsafeMutableRawPointer

//   internal init(_ up: UnsafeMutablePointer<AnyObject>) {
//     self.value = UnsafeMutableRawPointer(up)
//   }

//   internal init?(_ up: UnsafeMutablePointer<AnyObject>?) {
//     guard let unwrapped = up else { return nil }
//     self.init(unwrapped)
//   }

//   internal subscript(i: Int) -> AnyObject {
//     get {
//       let unmanaged = value.load(
//         fromByteOffset: i * MemoryLayout<AnyObject>.stride,
//         as: Unmanaged<AnyObject>.self)
//       return unmanaged.takeUnretainedValue()
//     }
//     nonmutating set(newValue) {
//       let unmanaged = Unmanaged.passUnretained(newValue)
//       value.storeBytes(of: unmanaged,
//         toByteOffset: i * MemoryLayout<AnyObject>.stride,
//         as: Unmanaged<AnyObject>.self)
//     }
//   }
// }

//===----------------------------------------------------------------------===//
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

extension Hasher {
  // FIXME: Remove @usableFromInline and @frozen once Hasher is resilient.
  // rdar://problem/38549901
  @usableFromInline @frozen
  internal struct _State {
    // "somepseudorandomlygeneratedbytes"
    private var v0: UInt64 = 0x736f6d6570736575
    private var v1: UInt64 = 0x646f72616e646f6d
    private var v2: UInt64 = 0x6c7967656e657261
    private var v3: UInt64 = 0x7465646279746573
    // The fields below are reserved for future use. They aren't currently used.
    private var v4: UInt64 = 0
    private var v5: UInt64 = 0
    private var v6: UInt64 = 0
    private var v7: UInt64 = 0

    @inline(__always)
    internal init(rawSeed: (UInt64, UInt64)) {
      v3 ^= rawSeed.1
      v2 ^= rawSeed.0
      v1 ^= rawSeed.1
      v0 ^= rawSeed.0
    }
  }
}

extension Hasher._State {
  @inline(__always)
  private static func _rotateLeft(_ x: UInt64, by amount: UInt64) -> UInt64 {
    return (x &<< amount) | (x &>> (64 - amount))
  }

  @inline(__always)
  private mutating func _round() {
    v0 = v0 &+ v1
    v1 = Hasher._State._rotateLeft(v1, by: 13)
    v1 ^= v0
    v0 = Hasher._State._rotateLeft(v0, by: 32)
    v2 = v2 &+ v3
    v3 = Hasher._State._rotateLeft(v3, by: 16)
    v3 ^= v2
    v0 = v0 &+ v3
    v3 = Hasher._State._rotateLeft(v3, by: 21)
    v3 ^= v0
    v2 = v2 &+ v1
    v1 = Hasher._State._rotateLeft(v1, by: 17)
    v1 ^= v2
    v2 = Hasher._State._rotateLeft(v2, by: 32)
  }

  @inline(__always)
  private func _extract() -> UInt64 {
    return v0 ^ v1 ^ v2 ^ v3
  }
}

extension Hasher._State {
  @inline(__always)
  internal mutating func compress(_ m: UInt64) {
    v3 ^= m
    _round()
    v0 ^= m
  }

  @inline(__always)
  internal mutating func finalize(tailAndByteCount: UInt64) -> UInt64 {
    compress(tailAndByteCount)
    v2 ^= 0xff
    for _ in 0..<3 {
      _round()
    }
    return _extract()
  }
}

extension Hasher._State {
  @inline(__always)
  internal init() {
    self.init(rawSeed: Hasher._executionSeed)
  }

  @inline(__always)
  internal init(seed: Int) {
    let executionSeed = Hasher._executionSeed
    // Prevent sign-extending the supplied seed; this makes testing slightly
    // easier.
    let seed = UInt(bitPattern: seed)
    self.init(rawSeed: (
        executionSeed.0 ^ UInt64(truncatingIfNeeded: seed),
        executionSeed.1))
  }
}
