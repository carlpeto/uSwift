//===--- ArrayType.swift - Protocol for Array-like types ------------------===//
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

@usableFromInline
internal protocol _ArrayProtocol
  : Collection, ExpressibleByArrayLiteral
where Indices == Range<Int> {
  var capacity: Int { get }

  // var _owner: AnyObject? { get }

  var _baseAddressIfContiguous: UnsafeMutablePointer<Element>? { get }

  //===--- basic mutations ------------------------------------------------===//

  // override mutating func reserveCapacity(_ minimumCapacity: Int)

  // override mutating func insert(_ newElement: __owned Element, at i: Int)

  // @discardableResult
  // override mutating func remove(at index: Int) -> Element

  //===--- implementation detail  -----------------------------------------===//

  associatedtype _Buffer: _ArrayBufferProtocol where _Buffer.Element == Element
  init(_ buffer: _Buffer)

  // For testing.
  var _buffer: _Buffer { get }
}

extension _ArrayProtocol {
  // Since RangeReplaceableCollection now has a version of filter that is less
  // efficient, we should make the default implementation coming from Sequence
  // preferred.
  @inlinable
  public __consuming func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> [Element] {
    return try _filter(isIncluded)
  }
}
