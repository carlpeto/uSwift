//===--- UnicodeEncoding.swift --------------------------------------------===//
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

public protocol _UnicodeEncoding {
  associatedtype CodeUnit : UnsignedInteger, FixedWidthInteger
  
  associatedtype EncodedScalar : BidirectionalCollection
    where EncodedScalar.Iterator.Element == CodeUnit

  static var encodedReplacementCharacter : EncodedScalar { get }

  static func decode(_ content: EncodedScalar) -> Unicode.Scalar

  static func encode(_ content: Unicode.Scalar) -> EncodedScalar?

  static func transcode<FromEncoding : Unicode.Encoding>(
    _ content: FromEncoding.EncodedScalar, from _: FromEncoding.Type
  ) -> EncodedScalar?

  associatedtype ForwardParser : Unicode.Parser
    where ForwardParser.Encoding == Self
  
  associatedtype ReverseParser : Unicode.Parser
    where ReverseParser.Encoding == Self

  //===--------------------------------------------------------------------===//
  // FIXME: this requirement shouldn't be here and is mitigated by the default
  // implementation below.  Compiler bugs prevent it from being expressed in an
  // intermediate, underscored protocol.
  static func _isScalar(_ x: CodeUnit) -> Bool
}

extension _UnicodeEncoding {
  // See note on declaration of requirement, above
  @inlinable
  public static func _isScalar(_ x: CodeUnit) -> Bool { return false }

  @inlinable
  public static func transcode<FromEncoding : Unicode.Encoding>(
    _ content: FromEncoding.EncodedScalar, from _: FromEncoding.Type
  ) -> EncodedScalar? {
    return encode(FromEncoding.decode(content))
  }

  @inlinable
  internal static func _encode(_ content: Unicode.Scalar) -> EncodedScalar {
    return encode(content) ?? encodedReplacementCharacter
  }

  @inlinable
  internal static func _transcode<FromEncoding : Unicode.Encoding>(
    _ content: FromEncoding.EncodedScalar, from _: FromEncoding.Type
  ) -> EncodedScalar {
    return transcode(content, from: FromEncoding.self)
      ?? encodedReplacementCharacter
  }

  @inlinable
  internal static func _transcode<
  Source: Sequence, SourceEncoding: Unicode.Encoding>(
    _ source: Source,
    from sourceEncoding: SourceEncoding.Type,
    into processScalar: (EncodedScalar)->Void)
  where Source.Element == SourceEncoding.CodeUnit {
    var p = SourceEncoding.ForwardParser()
    var i = source.makeIterator()
    while true {
      switch p.parseScalar(from: &i) {
      case .valid(let e): processScalar(_transcode(e, from: sourceEncoding))
      case .error(_): processScalar(encodedReplacementCharacter)
      case .emptyInput: return
      }
    }
  }
}

extension Unicode {
  public typealias Encoding = _UnicodeEncoding
}

