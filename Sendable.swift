//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_marker public protocol SendableMetatype: ~Copyable, ~Escapable { }

@_marker public protocol Sendable: SendableMetatype, ~Copyable, ~Escapable { }

@available(*, deprecated, message: "Use @unchecked Sendable instead")
@available(swift, obsoleted: 6.0, message: "Use @unchecked Sendable instead")
@_marker public protocol UnsafeSendable: Sendable { }

// Historical names
@available(*, deprecated, renamed: "Sendable")
@available(swift, obsoleted: 6.0, renamed: "Sendable")
public typealias ConcurrentValue = Sendable

@available(*, deprecated, renamed: "Sendable")
@available(swift, obsoleted: 6.0, renamed: "Sendable")
public typealias UnsafeConcurrentValue = UnsafeSendable
