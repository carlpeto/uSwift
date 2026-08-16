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
// Unicode.Scalar Type
//===----------------------------------------------------------------------===//

extension Unicode {
  @frozen
  public struct Scalar {
    @inlinable
    internal init(_value: UInt32) {
      self._value = _value
    }

    @usableFromInline
    internal var _value: UInt32
  }
}

extension Unicode.Scalar :
    _ExpressibleByBuiltinUnicodeScalarLiteral,
    ExpressibleByUnicodeScalarLiteral {
  @inlinable
  public var value: UInt32 { return _value }

  @_transparent
  public init(_builtinUnicodeScalarLiteral value: Builtin.Int32) {
    self._value = UInt32(value)
  }

  @_transparent
  public init(unicodeScalarLiteral value: Unicode.Scalar) {
    self = value
  }

  @inlinable
  public init?(_ v: UInt32) {
    // Unicode 6.3.0:
    //
    //     D9.  Unicode codespace: A range of integers from 0 to 10FFFF.
    //
    //     D76. Unicode scalar value: Any Unicode code point except
    //     high-surrogate and low-surrogate code points.
    //
    //     * As a result of this definition, the set of Unicode scalar values
    //     consists of the ranges 0 to D7FF and E000 to 10FFFF, inclusive.
    if (v < 0xD800 || v > 0xDFFF) && v <= 0x10FFFF {
      self._value = v
      return
    }
    // Return nil in case of an invalid unicode scalar value.
    return nil
  }

  @inlinable
  public init?(_ v: UInt16) {
    self.init(UInt32(v))
  }

  @inlinable
  public init(_ v: UInt8) {
    self._value = UInt32(v)
  }

  @inlinable
  public init(_ v: Unicode.Scalar) {
    // This constructor allows one to provide necessary type context to
    // disambiguate between function overloads on 'String' and 'Unicode.Scalar'.
    self = v
  }

  // public func escaped(asASCII forceASCII: Bool) -> String {
  //   func lowNibbleAsHex(_ v: UInt32) -> String {
  //     let nibble = v & 15
  //     if nibble < 10 {
  //       return String(Unicode.Scalar(nibble+48)!)    // 48 = '0'
  //     } else {
  //       return String(Unicode.Scalar(nibble-10+65)!) // 65 = 'A'
  //     }
  //   }

  //   if self == "\\" {
  //     return "\\\\"
  //   } else if self == "\'" {
  //     return "\\\'"
  //   } else if self == "\"" {
  //     return "\\\""
  //   } else if _isPrintableASCII {
  //     return String(self)
  //   } else if self == "\0" {
  //     return "\\0"
  //   } else if self == "\n" {
  //     return "\\n"
  //   } else if self == "\r" {
  //     return "\\r"
  //   } else if self == "\t" {
  //     return "\\t"
  //   } else if UInt32(self) < 128 {
  //     return "\\u{"
  //       + lowNibbleAsHex(UInt32(self) >> 4)
  //       + lowNibbleAsHex(UInt32(self)) + "}"
  //   } else if !forceASCII {
  //     return String(self)
  //   } else if UInt32(self) <= 0xFFFF {
  //     var result = "\\u{"
  //     result += lowNibbleAsHex(UInt32(self) >> 12)
  //     result += lowNibbleAsHex(UInt32(self) >> 8)
  //     result += lowNibbleAsHex(UInt32(self) >> 4)
  //     result += lowNibbleAsHex(UInt32(self))
  //     result += "}"
  //     return result
  //   } else {
  //     // FIXME: Type checker performance prohibits this from being a
  //     // single chained "+".
  //     var result = "\\u{"
  //     result += lowNibbleAsHex(UInt32(self) >> 28)
  //     result += lowNibbleAsHex(UInt32(self) >> 24)
  //     result += lowNibbleAsHex(UInt32(self) >> 20)
  //     result += lowNibbleAsHex(UInt32(self) >> 16)
  //     result += lowNibbleAsHex(UInt32(self) >> 12)
  //     result += lowNibbleAsHex(UInt32(self) >> 8)
  //     result += lowNibbleAsHex(UInt32(self) >> 4)
  //     result += lowNibbleAsHex(UInt32(self))
  //     result += "}"
  //     return result
  //   }
  // }

  @inlinable
  public var isASCII: Bool {
    return value <= 127
  }

  // FIXME: Unicode makes this interesting.
  internal var _isPrintableASCII: Bool {
    return (self >= Unicode.Scalar(0o040) && self <= Unicode.Scalar(0o176))
  }
}

// extension Unicode.Scalar : CustomStringConvertible, CustomDebugStringConvertible {
//   @inlinable
//   public var description: String {
//     return String(self)
//   }

//   public var debugDescription: String {
//     return "\"\(escaped(asASCII: true))\""
//   }
// }

// extension Unicode.Scalar : LosslessStringConvertible {
//   @inlinable
//   public init?(_ description: String) {
//     let scalars = description.unicodeScalars
//     guard let v = scalars.first, scalars.count == 1 else {
//       return nil
//     }
//     self = v
//   }
// }

extension Unicode.Scalar : Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.value)
  }
}

extension Unicode.Scalar {
  @inlinable
  public init?(_ v: Int) {
    if let us = Unicode.Scalar(UInt32(v)) {
      self = us
    } else {
      return nil
    }
  }
}

extension UInt8 {
  @inlinable
  public init(ascii v: Unicode.Scalar) {
    _precondition(v.value < 128)
    self = UInt8(v.value)
  }
}
extension UInt32 {
  @inlinable
  public init(_ v: Unicode.Scalar) {
    self = v.value
  }
}
extension UInt64 {
  @inlinable
  public init(_ v: Unicode.Scalar) {
    self = UInt64(v.value)
  }
}

extension Unicode.Scalar : Equatable {
  @inlinable
  public static func == (lhs: Unicode.Scalar, rhs: Unicode.Scalar) -> Bool {
    return lhs.value == rhs.value
  }
}

extension Unicode.Scalar : Comparable {
  @inlinable
  public static func < (lhs: Unicode.Scalar, rhs: Unicode.Scalar) -> Bool {
    return lhs.value < rhs.value
  }
}

extension Unicode.Scalar {
  @frozen
  public struct UTF16View {
    @inlinable
    internal init(value: Unicode.Scalar) {
      self.value = value
    }
    @usableFromInline
    internal var value: Unicode.Scalar
  }

  @inlinable
  public var utf16: UTF16View {
    return UTF16View(value: self)
  }
}

extension Unicode.Scalar.UTF16View : RandomAccessCollection {

  public typealias Indices = Range<Int>

  @inlinable
  public var startIndex: Int {
    return 0
  }

  @inlinable
  public var endIndex: Int {
    return 0 + UTF16.width(value)
  }

  @inlinable
  public subscript(position: Int) -> UTF16.CodeUnit {
    if position == 1 { return UTF16.trailSurrogate(value) }
    if endIndex == 1 { return UTF16.CodeUnit(value.value) }
    return UTF16.leadSurrogate(value)
  }
}

extension Unicode.Scalar {
  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  @frozen
  public struct UTF8View {
    @inlinable
    internal init(value: Unicode.Scalar) {
      self.value = value
    }
    @usableFromInline
    internal var value: Unicode.Scalar
  }

  @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
  @inlinable
  public var utf8: UTF8View { return UTF8View(value: self) }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Unicode.Scalar.UTF8View : RandomAccessCollection {
  public typealias Indices = Range<Int>

  @inlinable
  public var startIndex: Int { return 0 }

  @inlinable
  public var endIndex: Int { return 0 + UTF8.width(value) }

  @inlinable
  public subscript(position: Int) -> UTF8.CodeUnit {
    _precondition(position >= startIndex && position < endIndex)
    return value.withUTF8CodeUnits { $0[position] }
  }
}

extension Unicode.Scalar {
  internal static var _replacementCharacter: Unicode.Scalar {
    return Unicode.Scalar(_value: UTF32._replacementCodeUnit)
  }
}

extension Unicode.Scalar {
  @available(*, unavailable, message: "use 'Unicode.Scalar(0)'")
  public init() {
    Builtin.unreachable()
  }
}

// Access the underlying code units
extension Unicode.Scalar {
  // Access the scalar as encoded in UTF-16
  internal func withUTF16CodeUnits<Result>(
    _ body: (UnsafeBufferPointer<UInt16>) throws -> Result
  ) rethrows -> Result {
    var codeUnits: (UInt16, UInt16) = (self.utf16[0], 0)
    let utf16Count = self.utf16.count
    if utf16Count > 1 {
      _internalInvariant(utf16Count == 2)
      codeUnits.1 = self.utf16[1]
    }
    return try Swift.withUnsafePointer(to: &codeUnits) {
      return try $0.withMemoryRebound(to: UInt16.self, capacity: 2) {
        return try body(UnsafeBufferPointer(start: $0, count: utf16Count))
      }
    }
  }

  // Access the scalar as encoded in UTF-8
  @inlinable
  internal func withUTF8CodeUnits<Result>(
    _ body: (UnsafeBufferPointer<UInt8>) throws -> Result
  ) rethrows -> Result {
    let encodedScalar = UTF8.encode(self)!
    var (codeUnits, utf8Count) = encodedScalar._bytes

    // The first code unit is in the least significant byte of codeUnits.
    codeUnits = codeUnits.littleEndian
    return try Swift.withUnsafePointer(to: &codeUnits) {
      return try $0.withMemoryRebound(to: UInt8.self, capacity: 4) {
        return try body(UnsafeBufferPointer(start: $0, count: utf8Count))
      }
    }
  }
}

