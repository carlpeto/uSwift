//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
///
/// Additions to 'SwiftShims' that can be written in Swift.
///
//===----------------------------------------------------------------------===//

import uSwiftShims

@usableFromInline @_alwaysEmitIntoClient
internal func _mallocSize(ofAllocation ptr: UnsafeRawPointer) -> Int? {
  // hard coded as doesn't exist for AVR platform
  return nil
}
