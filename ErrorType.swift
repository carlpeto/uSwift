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
// import uSwiftShims

public protocol Error {
  #if !$Embedded
  // var _domain: String { get }
  var _code: Int { get }

  // Note: _userInfo is always an NSDictionary, but we cannot use that type here
  // because the standard library cannot depend on Foundation. However, the
  // underscore implies that we control all implementations of this requirement.
  var _userInfo: AnyObject? { get }
  #endif
}

@_silgen_name("swift_unexpectedError")
public func _unexpectedError(
  _ error: __owned Error,
  filenameStart: Builtin.RawPointer,
  filenameLength: Builtin.Word,
  filenameIsASCII: Builtin.Int1,
  line: Builtin.Word
) {
  preconditionFailure()
}

@_silgen_name("swift_errorInMain")
public func _errorInMain(_ error: Error) {
  fatalError()
}

@_silgen_name("_swift_stdlib_getDefaultErrorCode")
public func _getDefaultErrorCode<T : Error>(_ error: T) -> Int

extension Error {
  public var _code: Int {
    return _getDefaultErrorCode(self)
  }

  // public var _domain: String {
  //   return String(reflecting: type(of: self))
  // }

  public var _userInfo: AnyObject? {
    return nil
  }
}

extension Error where Self: RawRepresentable, Self.RawValue: FixedWidthInteger {
  // The error code of Error with integral raw values is the raw value.
  public var _code: Int {
    if Self.RawValue.isSigned {
      return numericCast(self.rawValue)
    }

    let uintValue: UInt = numericCast(self.rawValue)
    return Int(bitPattern: uintValue)
  }
}
