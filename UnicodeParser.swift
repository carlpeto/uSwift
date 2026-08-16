//===--- UnicodeParser.swift ----------------------------------------------===//
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
extension Unicode {
  @frozen
  public enum ParseResult<T> {
  case valid(T)
  
  case emptyInput
  
  case error(length: Int)

    @inlinable
    internal var _valid: T? {
      if case .valid(let result) = self { return result }
      return nil
    }

    @inlinable
    internal var _error: Int? {
      if case .error(let result) = self { return result }
      return nil
    }
  }
}

public protocol _UnicodeParser {
  associatedtype Encoding : _UnicodeEncoding

  init()

  mutating func parseScalar<I : IteratorProtocol>(
    from input: inout I
  ) -> Unicode.ParseResult<Encoding.EncodedScalar>
  where I.Element == Encoding.CodeUnit
}

extension Unicode {
  public typealias Parser = _UnicodeParser
}
