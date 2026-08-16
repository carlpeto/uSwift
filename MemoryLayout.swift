//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@frozen // namespace
public enum MemoryLayout<T: ~Copyable & ~Escapable>
: ~BitwiseCopyable, Copyable, Escapable {}

extension MemoryLayout where T: ~Copyable & ~Escapable {
  @_transparent
  @_preInverseGenerics
  public static var size: Int {
    return Int(Builtin.sizeof(T.self))
  }

  @_transparent
  @_preInverseGenerics
  public static var stride: Int {
    return Int(Builtin.strideof(T.self))
  }

  @_transparent
  @_preInverseGenerics
  public static var alignment: Int {
    return Int(Builtin.alignof(T.self))
  }
}

extension MemoryLayout where T: ~Copyable & ~Escapable {
  @_transparent
  @_preInverseGenerics
  public static func size(ofValue value: borrowing T) -> Int {
    return MemoryLayout.size
  }

  @_transparent
  @_preInverseGenerics
  public static func stride(ofValue value: borrowing T) -> Int {
    return MemoryLayout.stride
  }

  @_transparent
  @_preInverseGenerics
  public static func alignment(ofValue value: borrowing T) -> Int {
    return MemoryLayout.alignment
  }
}

extension MemoryLayout {
  // @_transparent
  // public static func offset(of key: PartialKeyPath<T>) -> Int? {
  //   return key._storedInlineOffset
  // }
}

// Not-yet-public alignment conveniences
extension MemoryLayout where T: ~Copyable {
  internal static var _alignmentMask: Int { return alignment - 1 }

  internal static func _roundingUpToAlignment(_ value: Int) -> Int {
    return (value + _alignmentMask) & ~_alignmentMask
  }
  internal static func _roundingDownToAlignment(_ value: Int) -> Int {
    return value & ~_alignmentMask
  }

  internal static func _roundingUpToAlignment(_ value: UInt) -> UInt {
    return (value + UInt(bitPattern: _alignmentMask)) & ~UInt(bitPattern: _alignmentMask)
  }
  internal static func _roundingDownToAlignment(_ value: UInt) -> UInt {
    return value & ~UInt(bitPattern: _alignmentMask)
  }

  internal static func _roundingUpToAlignment(_ value: UnsafeRawPointer) -> UnsafeRawPointer {
    return unsafe UnsafeRawPointer(bitPattern:
     _roundingUpToAlignment(UInt(bitPattern: value))).unsafelyUnwrapped
  }
  internal static func _roundingDownToAlignment(_ value: UnsafeRawPointer) -> UnsafeRawPointer {
    return unsafe UnsafeRawPointer(bitPattern:
     _roundingDownToAlignment(UInt(bitPattern: value))).unsafelyUnwrapped
  }

  internal static func _roundingUpToAlignment(_ value: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
    return unsafe UnsafeMutableRawPointer(bitPattern:
     _roundingUpToAlignment(UInt(bitPattern: value))).unsafelyUnwrapped
  }
  internal static func _roundingDownToAlignment(_ value: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
    return unsafe UnsafeMutableRawPointer(bitPattern:
     _roundingDownToAlignment(UInt(bitPattern: value))).unsafelyUnwrapped
  }

  internal static func _roundingUpBaseToAlignment(_ value: UnsafeRawBufferPointer) -> UnsafeRawBufferPointer {
    let baseAddressBits = Int(bitPattern: value.baseAddress)
    var misalignment = baseAddressBits & _alignmentMask
    if misalignment != 0 {
      misalignment = _alignmentMask & -misalignment
      return unsafe UnsafeRawBufferPointer(
        start: UnsafeRawPointer(bitPattern: baseAddressBits + misalignment),
        count: value.count - misalignment)
    }
    return unsafe value
  }

  internal static func _roundingUpBaseToAlignment(_ value: UnsafeMutableRawBufferPointer) -> UnsafeMutableRawBufferPointer {
    let baseAddressBits = Int(bitPattern: value.baseAddress)
    var misalignment = baseAddressBits & _alignmentMask
    if misalignment != 0 {
      misalignment = _alignmentMask & -misalignment
      return unsafe UnsafeMutableRawBufferPointer(
        start: UnsafeMutableRawPointer(bitPattern: baseAddressBits + misalignment),
        count: value.count - misalignment)
    }
    return unsafe value
  }
}
