//===--- FlatMap.swift ----------------------------------------------------===//
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

extension LazySequenceProtocol {
  @inlinable // lazy-performance
  public func flatMap<SegmentOfResult>(
    _ transform: @escaping (Elements.Element) -> SegmentOfResult
  ) -> LazySequence<
    FlattenSequence<LazyMapSequence<Elements, SegmentOfResult>>> {
    return self.map(transform).joined()
  }

  @inlinable // lazy-performance
  public func compactMap<ElementOfResult>(
    _ transform: @escaping (Elements.Element) -> ElementOfResult?
  ) -> LazyMapSequence<
    LazyFilterSequence<
      LazyMapSequence<Elements, ElementOfResult?>>,
    ElementOfResult
  > {
    return self.map(transform).filter { $0 != nil }.map { $0! }
  }
}
