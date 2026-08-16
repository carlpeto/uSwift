//===--- LazyCollection.swift ---------------------------------*- swift -*-===//
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

public protocol LazyCollectionProtocol: Collection, LazySequenceProtocol 
where Elements : Collection {	}

extension LazyCollectionProtocol {		
   // Lazy things are already lazy		
   @inlinable // protocol-only		
   public var lazy: LazyCollection<Elements> {		
     return elements.lazy		
   }		
 }		
		
 extension LazyCollectionProtocol where Elements: LazyCollectionProtocol {		
   // Lazy things are already lazy		
   @inlinable // protocol-only		
   public var lazy: Elements {		
     return elements		
   }		
 }

public typealias LazyCollection<T: Collection> = LazySequence<T>

extension LazyCollection : Collection {
  public typealias Index = Base.Index
  public typealias Indices = Base.Indices
  public typealias SubSequence = Slice<LazySequence>

  @inlinable
  public var startIndex: Index { return _base.startIndex }

  @inlinable
  public var endIndex: Index { return _base.endIndex }

  @inlinable
  public var indices: Indices { return _base.indices }

  // TODO: swift-3-indexing-model - add docs
  @inlinable
  public func index(after i: Index) -> Index {
    return _base.index(after: i)
  }

  @inlinable
  public subscript(position: Index) -> Element {
    return _base[position]
  }

  @inlinable
  public var isEmpty: Bool {
    return _base.isEmpty
  }

  @inlinable
  public var count: Int {
    return _base.count
  }

  // The following requirement enables dispatching for firstIndex(of:) and
  // lastIndex(of:) when the element type is Equatable.

  @inlinable
  public func _customIndexOfEquatableElement(
    _ element: Element
  ) -> Index?? {
    return _base._customIndexOfEquatableElement(element)
  }

  @inlinable
  public func _customLastIndexOfEquatableElement(
    _ element: Element
  ) -> Index?? {
    return _base._customLastIndexOfEquatableElement(element)
  }

  // TODO: swift-3-indexing-model - add docs
  @inlinable
  public func index(_ i: Index, offsetBy n: Int) -> Index {
    return _base.index(i, offsetBy: n)
  }

  // TODO: swift-3-indexing-model - add docs
  @inlinable
  public func index(
    _ i: Index, offsetBy n: Int, limitedBy limit: Index
  ) -> Index? {
    return _base.index(i, offsetBy: n, limitedBy: limit)
  }

  // TODO: swift-3-indexing-model - add docs
  @inlinable
  public func distance(from start: Index, to end: Index) -> Int {
    return _base.distance(from:start, to: end)
  }
}

extension LazyCollection: LazyCollectionProtocol { }

extension LazyCollection : BidirectionalCollection
  where Base : BidirectionalCollection {
  @inlinable
  public func index(before i: Index) -> Index {
    return _base.index(before: i)
  }
}

extension LazyCollection : RandomAccessCollection
  where Base : RandomAccessCollection {}

extension Slice: LazySequenceProtocol where Base: LazySequenceProtocol { }
extension ReversedCollection: LazySequenceProtocol where Base: LazySequenceProtocol { }
