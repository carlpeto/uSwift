//===--- Array.swift ------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
//  Three generic, mutable array-like types with value semantics.
//
//  - `Array<Element>` is like `ContiguousArray<Element>` when `Element` is not
//    a reference type or an Objective-C existential.  Otherwise, it may use
//    an `NSArray` bridged from Cocoa for storage.
//
//===----------------------------------------------------------------------===//

//why can't we do this?... @_specialize(exported: true, kind: full, where Element == UInt8)
@frozen
public struct Array<Element>: _DestructorSafeContainer {

#if FORCE_MAIN_SWIFT_ARRAYS
  @usableFromInline
  internal typealias _Buffer = _ContiguousArrayBuffer<Element>
#else
  @usableFromInline
  internal typealias _Buffer = _AVRArrayBuffer<Element>
#endif

  @usableFromInline
  internal var _buffer: _Buffer

  @inlinable
  internal init(_buffer: _Buffer) {
    self._buffer = _buffer
  }
}

//===--- private helpers---------------------------------------------------===//
extension Array {
  @inlinable
  @_semantics("array.props.isNativeTypeChecked")
  public // @testable
  func _hoistableIsNativeTypeChecked() -> Bool {
   return _buffer.arrayPropertyIsNativeTypeChecked
  }

  @inlinable
  @_semantics("array.get_count")
  internal func _getCount() -> Int {
    return _buffer.count
  }

  @inlinable
  @_semantics("array.get_capacity")
  internal func _getCapacity() -> Int {
    return _buffer.capacity
  }

  @inlinable
  @_semantics("array.make_mutable")
  internal mutating func _makeMutableAndUnique() {
    // noop
    // if _slowPath(!_buffer.isMutableAndUniquelyReferenced()) {
    //   _buffer = _Buffer(copying: _buffer)
    // }
  }

  @inlinable
  @inline(__always)
  internal func _checkSubscript_native(_ index: inout Int) {
    _ = _checkSubscript(&index, wasNativeTypeChecked: true)
  }

  @inlinable
  @_semantics("array.check_subscript")
  public // @testable
  func _checkSubscript(
    _ index: inout Int, wasNativeTypeChecked: Bool
  ) -> _DependenceToken {
    _buffer._checkValidSubscript(&index)
    return _DependenceToken()
  }

  /// Check that the given `index` is valid for subscripting, i.e.
  /// `0 ≤ index < count`.
  ///
  /// - Precondition: The buffer must be uniquely referenced and native.
  @_alwaysEmitIntoClient
  @_semantics("array.check_subscript")
  @_effects(notEscaping self.**)
  internal func _checkSubscript_mutating(_ index: inout Int) {
    _buffer._checkValidSubscriptMutating(&index)
  }

  @inlinable
  @_semantics("array.check_index")
  internal func _checkIndex(_ index: inout Int) {
    _precondition(index <= endIndex)
    _precondition(index >= startIndex)
  }

  @_semantics("array.get_element")
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public // @testable
  func _getElement(
    _ index: Int,
    wasNativeTypeChecked: Bool,
    matchingSubscriptCheck: _DependenceToken
  ) -> Element {
    return _buffer.getElement(index)
  }

  @inlinable
  @_semantics("array.get_element_address")
  internal func _getElementAddress(_ index: Int) -> UnsafeMutablePointer<Element> {
    return _buffer.subscriptBaseAddress + index
  }
}

extension Array: _ArrayProtocol {
  @inlinable
  public var capacity: Int {
    return _getCapacity()
  }

  // @inlinable
  // public // @testable
  // var _owner: AnyObject? {
  //   @inlinable // FIXME(inline-always)
  //   @inline(__always)
  //   get {
  //     return _buffer.owner      
  //   }
  // }

  @inlinable
  public var _baseAddressIfContiguous: UnsafeMutablePointer<Element>? {
    @inline(__always) // FIXME(TODO: JIRA): Hack around test failure
    get { return _buffer.firstElementAddressIfContiguous }
  }
}

extension Array: RandomAccessCollection, MutableCollection {
  public typealias Index = Int

  public typealias Indices = Range<Int>

  public typealias Iterator = IndexingIterator<Array>

  @inlinable
  public var startIndex: Int {
    return 0
  }

  @inlinable
  public var endIndex: Int {
    @inlinable
    get {
      return _getCount()
    }
  }

  @inlinable
  public func index(after i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for Array performance.  The optimizer is not
    // capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + 1
  }

  @inlinable
  public func formIndex(after i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for Array performance.  The optimizer is not
    // capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i += 1
  }

  @inlinable
  public func index(before i: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for Array performance.  The optimizer is not
    // capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i - 1
  }

  @inlinable
  public func formIndex(before i: inout Int) {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for Array performance.  The optimizer is not
    // capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    i -= 1
  }

  @inlinable
  public func index(_ i: Int, offsetBy distance: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for Array performance.  The optimizer is not
    // capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return i + distance
  }

  @inlinable
  public func index(
    _ i: Int, offsetBy distance: Int, limitedBy limit: Int
  ) -> Int? {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for Array performance.  The optimizer is not
    // capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    let l = limit - i
    if distance > 0 ? l >= 0 && l < distance : l <= 0 && distance < l {
      return nil
    }
    return i + distance
  }

  @inlinable
  public func distance(from start: Int, to end: Int) -> Int {
    // NOTE: this is a manual specialization of index movement for a Strideable
    // index that is required for Array performance.  The optimizer is not
    // capable of creating partial specializations yet.
    // NOTE: Range checks are not performed here, because it is done later by
    // the subscript function.
    return end - start
  }

  @inlinable
  public func _failEarlyRangeCheck(_ index: Int, bounds: Range<Int>) {
    // NOTE: This method is a no-op for performance reasons.
  }

  @inlinable
  public func _failEarlyRangeCheck(_ range: Range<Int>, bounds: Range<Int>) {
    // NOTE: This method is a no-op for performance reasons.
  }

  @inlinable
  public subscript(index: Int) -> Element {
    get {
      // This call may be hoisted or eliminated by the optimizer.  If
      // there is an inout violation, this value may be stale so needs to be
      // checked again below.
      let wasNativeTypeChecked = _hoistableIsNativeTypeChecked()

      // Make sure the index is in range and wasNativeTypeChecked is
      // still valid.
      var index = index
      let token = _checkSubscript(
        &index, wasNativeTypeChecked: wasNativeTypeChecked)

      return _getElement(
        index, wasNativeTypeChecked: wasNativeTypeChecked,
        matchingSubscriptCheck: token)
    }
    _modify {
      _makeMutableAndUnique() // makes the array native, too
      var index = index
      _checkSubscript_mutating(&index)
      let address = _buffer.subscriptBaseAddress + index
      yield &address.pointee
    }
  }

  @inlinable
  public subscript(bounds: Range<Int>) -> ArraySlice<Element> {
    get {
      var lowerBound = bounds.lowerBound
      var upperBound = bounds.upperBound
      _checkIndex(&lowerBound)
      _checkIndex(&upperBound)
      return ArraySlice(_buffer: _buffer[lowerBound...upperBound])
    }

    @available(*, unavailable, message: "AVR Arrays cannot be set by range, see uSwift documentation")
    set(rhs) {
      // _checkIndex(bounds.lowerBound)
      // _checkIndex(bounds.upperBound)
      // // If the replacement buffer has same identity, and the ranges match,
      // // then this was a pinned in-place modification, nothing further needed.
      // if self[bounds]._buffer.identity != rhs._buffer.identity
      // || bounds != rhs.startIndex..<rhs.endIndex {
      //   self.replaceSubrange(bounds, with: rhs)
      // }
    }
  }
  
  @inlinable
  public var count: Int {
    return _getCount()
  }
}

extension Array: ExpressibleByArrayLiteral {
  // Optimized implementation for Array
  @inlinable
  public init(arrayLiteral elements: Element...) {
    self = elements
  }
}

extension Array {
  @inlinable
  @_semantics("array.init.empty")
  public init() {
    _buffer = _Buffer()
  }

  @available(*, deprecated, message: "AVR Arrays should not be created from a sequence, see uSwift documentation")
  @inlinable
  public init<S: Sequence>(_ s: S) where S.Element == Element {
    self = Array(
      _buffer: _Buffer(
        _buffer: s._copyToContiguousArray()._buffer,
        shiftedToStartIndex: 0))
  }

  // @_specialize(kind: full, where Element == UInt8)
  @inlinable
  @inline(__always)
  @_semantics("array.init")
  public init(repeating repeatedValue: Element, count: inout Int) {
    var p: UnsafeMutablePointer<Element>
    (self, p) = Array<Element>._allocateUninitialized(&count)
    for _ in 0..<count {
      p.initialize(to: repeatedValue)
      p += 1
    }
  }

#if !FORCE_MAIN_SWIFT_ARRAYS
  @inlinable
  public mutating func deallocate() {
    _buffer.deallocate()
  }
#endif

  // @_specialize(kind: full, where Element == UInt8)
  // @inline(never)
  @inlinable
  @inline(__always)
  @usableFromInline
  internal static func _allocateBufferUninitialized(
    minimumCapacity: Int
  ) -> _Buffer? {
#if FORCE_MAIN_SWIFT_ARRAYS
    return _ContiguousArrayBuffer<Element>(_uninitializedCount: 0, minimumCapacity: minimumCapacity)
#else    
    return _AVRArrayBuffer<Element>(_uninitializedCount: 0, minimumCapacity: minimumCapacity)
#endif
  }

  // @_specialize(kind: full, where Element == UInt8)
  @inlinable
  @inline(__always)
  internal init(_uninitializedCount count: inout Int) {
    _precondition(count >= 0)
    // Note: Sinking this constructor into an else branch below causes an extra
    // Retain/Release.
    // _buffer = _Buffer()
    if count > 0, let buffer = Array._allocateBufferUninitialized(minimumCapacity: count) {
      // Creating a buffer instead of calling reserveCapacity saves doing an
      // unnecessary uniqueness check. We disable inlining here to curb code
      // growth.
      _buffer = buffer
      _buffer.count = count
    } else {
      // this case is when either count is zero, or we were unable to allocate a buffer
      // we need to zero the count in either case
      _buffer = _Buffer() // we are using a different memory model/no ref count
      _buffer.count = 0
      count = 0
    }
    // Can't store count here because the buffer might be pointing to the
    // shared empty array.
  }

  // @_specialize(kind: full, where Element == UInt8)
  @inlinable
  @inline(__always)
  @_semantics("array.uninitialized")
  internal static func _allocateUninitialized(
    _ count: inout Int
  ) -> (Array, UnsafeMutablePointer<Element>) {
    let result = Array(_uninitializedCount: &count)
    return (result, result._buffer.firstElementAddress)
  }

#if FORCE_MAIN_SWIFT_ARRAYS
  @inlinable
  @_semantics("array.uninitialized")
  @_effects(escaping storage => return.0.value**)
  @_effects(escaping storage.class*.value** => return.0.value**.class*.value**)
  @_effects(escaping storage.class*.value** => return.1.value**)
  internal static func _adoptStorage(
    _ storage: __owned _ContiguousArrayStorage<Element>, count: Int
  ) -> (Array, UnsafeMutablePointer<Element>) {

    let innerBuffer = _ContiguousArrayBuffer<Element>(
      count: count,
      storage: storage)

    return (
      Array(
        _buffer: _Buffer(_buffer: innerBuffer, shiftedToStartIndex: 0)),
        innerBuffer.firstElementAddress)
  }
#else
  @inlinable
  @_semantics("array.uninitialized")
  internal static func _adoptStorage(
    _ storage: __owned UnsafeMutableBufferPointer<Element>, count: Int
  ) -> (Array, UnsafeMutablePointer<Element>) {

    let innerBuffer = _Buffer(
      count: count,
      storage: storage)

    return (
      Array(
        _buffer: _Buffer(_buffer: innerBuffer, shiftedToStartIndex: 0)),
        innerBuffer.firstElementAddress)
  }
#endif

#if FORCE_MAIN_SWIFT_ARRAYS
  /// Entry point for aborting literal construction: deallocates
  /// an Array containing only uninitialized elements.
  @inlinable
  internal mutating func _deallocateUninitialized() {
    // Set the count to zero and just release as normal.
    // Somewhat of a hack.
    _buffer.mutableCount = 0
  }
#else
  // @inlinable
  internal mutating func _deallocateUninitialized() {
    // Set the count to zero and just release as normal.
    // Somewhat of a hack.
    _buffer.count = 0
    _buffer.deallocate()
  }
#endif

  //===--- basic mutations ------------------------------------------------===//


  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  @_semantics("array.mutate_unknown")
  public mutating func reserveCapacity(_ minimumCapacity: Int) {
    return 
    // if _buffer.requestUniqueMutableBackingBuffer(
    //   minimumCapacity: minimumCapacity) == nil {

    //   let newBuffer = _Buffer<Element>(
    //     _uninitializedCount: count, minimumCapacity: minimumCapacity)

    //   _buffer._copyContents(
    //     subRange: _buffer.indices,
    //     initializing: newBuffer.firstElementAddress)
    //   _buffer = _Buffer(
    //     _buffer: newBuffer, shiftedToStartIndex: _buffer.startIndex)
    // }
    // _internalInvariant(capacity >= minimumCapacity)
  }

  @inline(never)
  @inlinable // @specializable
  internal mutating func _copyToNewBuffer(oldCount: Int) {
    // noop
    // let newCount = oldCount + 1
    // var newBuffer = _buffer._forceCreateUniqueMutableBuffer(
    //   countForNewBuffer: oldCount, minNewCapacity: newCount)
    // _buffer._arrayOutOfPlaceUpdate(&newBuffer, oldCount, 0)
  }

  @inlinable
  @_semantics("array.make_mutable")
  internal mutating func _makeUniqueAndReserveCapacityIfNotUnique() {
    // noop
    // if _slowPath(!_buffer.isMutableAndUniquelyReferenced()) {
    //   _copyToNewBuffer(oldCount: _buffer.count)
    // }
  }

  @inlinable
  @_semantics("array.mutate_unknown")
  internal mutating func _reserveCapacityAssumingUniqueBuffer(oldCount: Int) {
    // This is a performance optimization. This code used to be in an ||
    // statement in the _internalInvariant below.
    //
    //   _internalInvariant(_buffer.capacity == 0 ||
    //                _buffer.isMutableAndUniquelyReferenced())
    //
    // SR-6437
    let capacity = _buffer.capacity == 0

    // Due to make_mutable hoisting the situation can arise where we hoist
    // _makeMutableAndUnique out of loop and use it to replace
    // _makeUniqueAndReserveCapacityIfNotUnique that preceeds this call. If the
    // array was empty _makeMutableAndUnique does not replace the empty array
    // buffer by a unique buffer (it just replaces it by the empty array
    // singleton).
    // This specific case is okay because we will make the buffer unique in this
    // function because we request a capacity > 0 and therefore _copyToNewBuffer
    // will be called creating a new buffer.
    _internalInvariant(capacity ||
                 _buffer.isMutableAndUniquelyReferenced())

    if _slowPath(oldCount + 1 > _buffer.capacity) {
      _copyToNewBuffer(oldCount: oldCount)
    }
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  @_semantics("array.mutate_unknown")
  internal mutating func _appendElementAssumeUniqueAndCapacity(
    _ oldCount: Int,
    newElement: __owned Element
  ) {
    _internalInvariant(_buffer.isMutableAndUniquelyReferenced())
    _internalInvariant(_buffer.capacity >= _buffer.count + 1)

    _buffer.count = oldCount + 1
    (_buffer.firstElementAddress + oldCount).initialize(to: newElement)
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  @_semantics("array.append_element")
  public mutating func append(_ newElement: __owned Element) {
    // _makeUniqueAndReserveCapacityIfNotUnique()
    // let oldCount = _getCount()
    // _reserveCapacityAssumingUniqueBuffer(oldCount: oldCount)
    // _appendElementAssumeUniqueAndCapacity(oldCount, newElement: newElement)
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  @_semantics("array.append_contentsOf")
  public mutating func append<S: Sequence>(contentsOf newElements: __owned S)
    where S.Element == Element {

    // let newElementsCount = newElements.underestimatedCount
    // reserveCapacityForAppend(newElementsCount: newElementsCount)

    // let oldCount = self.count
    // let startNewElements = _buffer.firstElementAddress + oldCount
    // let buf = UnsafeMutableBufferPointer(
    //             start: startNewElements, 
    //             count: self.capacity - oldCount)

    // let (remainder,writtenUpTo) = buf.initialize(from: newElements)
    
    // // trap on underflow from the sequence's underestimate:
    // let writtenCount = buf.distance(from: buf.startIndex, to: writtenUpTo)
    // _precondition(newElementsCount <= writtenCount)
    // // can't check for overflow as sequences can underestimate

    // // This check prevents a data race writting to _swiftEmptyArrayStorage
    // if writtenCount > 0 {
    //   _buffer.count += writtenCount
    // }

    // if writtenUpTo == buf.endIndex {
    //   // there may be elements that didn't fit in the existing buffer,
    //   // append them in slow sequence-only mode
    //   _buffer._arrayAppendSequence(IteratorSequence(remainder))
    // }
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  @_semantics("array.reserve_capacity_for_append")
  internal mutating func reserveCapacityForAppend(newElementsCount: Int) {
    // let oldCount = self.count
    // let oldCapacity = self.capacity
    // let newCount = oldCount + newElementsCount

    // // Ensure uniqueness, mutability, and sufficient storage.  Note that
    // // for consistency, we need unique self even if newElements is empty.
    // self.reserveCapacity(
    //   newCount > oldCapacity ?
    //   Swift.max(newCount, _growArrayCapacity(oldCapacity))
    //   : newCount)
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  public mutating func _customRemoveLast() -> Element? {
    let newCount = _getCount() - 1
    _precondition(newCount >= 0)
    _makeUniqueAndReserveCapacityIfNotUnique()
    let pointer = (_buffer.firstElementAddress + newCount)
    let element = pointer.move()
    _buffer.count = newCount
    return element
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  @discardableResult
  public mutating func remove(at index: Int) -> Element {
    _precondition(index < endIndex)
    _precondition(index >= startIndex)
    _makeUniqueAndReserveCapacityIfNotUnique()
    let newCount = _getCount() - 1
    let pointer = (_buffer.firstElementAddress + index)
    let result = pointer.move()
    pointer.moveInitialize(from: pointer + 1, count: newCount - index)
    _buffer.count = newCount
    return result
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  public mutating func insert(_ newElement: __owned Element, at i: Int) {
    // _checkIndex(i)
    // self.replaceSubrange(i..<i, with: CollectionOfOne(newElement))
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  public mutating func removeAll(keepingCapacity keepCapacity: Bool = false) {
    // if !keepCapacity {
    //   _buffer = _Buffer()
    // }
    // else {
    //   self.replaceSubrange(indices, with: EmptyCollection())
    // }
  }

  //===--- algorithms -----------------------------------------------------===//

  @inlinable
  public mutating func _withUnsafeMutableBufferPointerIfSupported<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try withUnsafeMutableBufferPointer {
      (bufferPointer) -> R in
      return try body(&bufferPointer)
    }
  }

  @inlinable
  public mutating func withContiguousMutableStorageIfAvailable<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try withUnsafeMutableBufferPointer {
      (bufferPointer) -> R in
      return try body(&bufferPointer)
    }
  }

  @inlinable
  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try withUnsafeBufferPointer {
      (bufferPointer) -> R in
      return try body(bufferPointer)
    }
  }

  @inlinable
  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element>? {
    if let n = _buffer.requestNativeBuffer() {
      return ContiguousArray(_buffer: n)
    }
    return _copyCollectionToContiguousArray(self)
  }
}

// Implementations of + and += for same-type arrays. This combined
// with the operator declarations for these operators designating this
// type as a place to prefer this operator help the expression type
// checker speed up cases where there is a large number of uses of the
// operator in the same expression.
extension Array {
  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  public static func + (lhs: Array, rhs: Array) -> Array {
    var lhs = lhs
    // lhs.append(contentsOf: rhs)
    return lhs
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size")
  @inlinable
  public static func += (lhs: inout Array, rhs: Array) {
    // lhs.append(contentsOf: rhs)
  }
}

// extension Array: CustomReflectable {
//   public var customMirror: Mirror {
//     return Mirror(
//       self,
//       unlabeledChildren: self,
//       displayStyle: .collection)
//   }
// }

// extension Array: CustomStringConvertible, CustomDebugStringConvertible {
//   public var description: String {
//     return _makeCollectionDescription()
//   }

//   public var debugDescription: String {
//     // Always show sugared representation for Arrays.
//     return _makeCollectionDescription()
//   }
// }

extension Array {
  @usableFromInline @_transparent
  internal func _cPointerArgs() -> (AnyObject?, UnsafeRawPointer?) {
    let p = _baseAddressIfContiguous
    if _fastPath(p != nil || isEmpty) {
      return (nil, UnsafeRawPointer(p))
    }
    let n = ContiguousArray(self._buffer)._buffer
    return (nil, UnsafeRawPointer(n.firstElementAddress))
  }
}

extension Array {
  @inlinable
  internal init(
    _unsafeUninitializedCapacity: inout Int,
    initializingWith initializer: (
      _ buffer: inout UnsafeMutableBufferPointer<Element>,
      _ initializedCount: inout Int) throws -> Void
  ) rethrows {
    var firstElementAddress: UnsafeMutablePointer<Element>
    (self, firstElementAddress) =
      Array._allocateUninitialized(&_unsafeUninitializedCapacity)

    var initializedCount: Int = 0
    var buffer = UnsafeMutableBufferPointer<Element>(
      start: firstElementAddress, count: _unsafeUninitializedCapacity)
    defer {
      // Update self.count even if initializer throws an error.
      _precondition(
        initializedCount <= _unsafeUninitializedCapacity
      )
      _precondition(
        buffer.baseAddress == firstElementAddress
      )
      self._buffer.count = initializedCount
    }
    try initializer(&buffer, &initializedCount)
  }

  @_alwaysEmitIntoClient @inlinable
  public init(
    unsafeUninitializedCapacity: inout Int,
    initializingWith initializer: (
      _ buffer: inout UnsafeMutableBufferPointer<Element>,
      _ initializedCount: inout Int) throws -> Void
  ) rethrows {
    self = try Array(
      _unsafeUninitializedCapacity: &unsafeUninitializedCapacity,
      initializingWith: initializer)
  }

  @inlinable
  public func withUnsafeBufferPointer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    return try _buffer.withUnsafeBufferPointer(body)
  }

  @_semantics("array.withUnsafeMutableBufferPointer")
  @inlinable // FIXME(inline-always)
  @inline(__always) // Performance: This method should get inlined into the
  // caller such that we can combine the partial apply with the apply in this
  // function saving on allocating a closure context. This becomes unnecessary
  // once we allocate noescape closures on the stack.
  public mutating func withUnsafeMutableBufferPointer<R>(
    _ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    let count = self.count
    // Ensure unique storage
    _buffer._outlinedMakeUniqueBuffer(bufferCount: count)

    // Ensure that body can't invalidate the storage or its bounds by
    // moving self into a temporary working array.
    // NOTE: The stack promotion optimization that keys of the
    // "array.withUnsafeMutableBufferPointer" semantics annotation relies on the
    // array buffer not being able to escape in the closure. It can do this
    // because we swap the array buffer in self with an empty buffer here. Any
    // escape via the address of self in the closure will therefore escape the
    // empty array.

    var work = Array()
    (work, self) = (self, work)

    // Create an UnsafeBufferPointer over work that we can pass to body
    let pointer = work._buffer.firstElementAddress
    var inoutBufferPointer = UnsafeMutableBufferPointer(
      start: pointer, count: count)

    // Put the working array back before returning.
    defer {
      _precondition(
        inoutBufferPointer.baseAddress == pointer &&
        inoutBufferPointer.count == count)

      (work, self) = (self, work)
    }

    // Invoke the body.
    return try body(&inoutBufferPointer)
  }

  @inlinable
  public __consuming func _copyContents(
    initializing buffer: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index) {

    guard !self.isEmpty else { return (makeIterator(),buffer.startIndex) }

    // It is not OK for there to be no pointer/not enough space, as this is
    // a precondition and Array never lies about its count.
    guard var p = buffer.baseAddress
      else {
        _preconditionFailure()
        return (makeIterator(),buffer.startIndex)
      }
    _precondition(self.count <= buffer.count)

    if let s = _baseAddressIfContiguous {
      p.initialize(from: s, count: self.count)
      // Need a _fixLifetime bracketing the _baseAddressIfContiguous getter
      // and all uses of the pointer it returns:
      // _fixLifetime(self._owner)
    } else {
      for x in self {
        p.initialize(to: x)
        p += 1
      }
    }

    var it = IndexingIterator(_elements: self)
    it._position = endIndex
    return (it,buffer.index(buffer.startIndex, offsetBy: self.count))
  }
}

extension Array {
  @available(*, unavailable, message: "AVR Arrays are fixed size so replace subrange is not allowed as it might change size or layout")
  @inlinable
  @_semantics("array.mutate_unknown")
  public mutating func replaceSubrange<C>(
    _ subrange: Range<Int>,
    with newElements: __owned C
  ) where C: Collection, C.Element == Element {
    // _precondition(subrange.lowerBound >= self._buffer.startIndex)
    // _precondition(subrange.upperBound <= _buffer.endIndex)

    // let oldCount = _buffer.count
    // let eraseCount = subrange.count
    // let insertCount = newElements.count
    // let growth = insertCount - eraseCount

    // if _buffer.requestUniqueMutableBackingBuffer(
    //   minimumCapacity: oldCount + growth) != nil {

    //   _buffer.replaceSubrange(
    //     subrange, with: insertCount, elementsOf: newElements)
    // } else {
    //   _buffer._arrayOutOfPlaceReplace(subrange, with: newElements, count: insertCount)
    // }
  }
}

extension Array: Equatable where Element: Equatable {
  @inlinable
  public static func ==(lhs: Array<Element>, rhs: Array<Element>) -> Bool {
    let lhsCount = lhs.count
    if lhsCount != rhs.count {
      return false
    }

    // Test referential equality.
    if lhsCount == 0 || lhs._buffer.identity == rhs._buffer.identity {
      return true
    }


    _internalInvariant(lhs.startIndex == 0 && rhs.startIndex == 0)
    _internalInvariant(lhs.endIndex == lhsCount && rhs.endIndex == lhsCount)

    // We know that lhs.count == rhs.count, compare element wise.
    for idx in 0..<lhsCount {
      if lhs[idx] != rhs[idx] {
        return false
      }
    }

    return true
  }
}

extension Array: Hashable where Element: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(count) // discriminator
    for element in self {
      hasher.combine(element)
    }
  }
}

extension Array {
  @inlinable
  public mutating func withUnsafeMutableBytes<R>(
    _ body: (UnsafeMutableRawBufferPointer) throws -> R
  ) rethrows -> R {
    return try self.withUnsafeMutableBufferPointer {
      return try body(UnsafeMutableRawBufferPointer($0))
    }
  }

  @inlinable
  public func withUnsafeBytes<R>(
    _ body: (UnsafeRawBufferPointer) throws -> R
  ) rethrows -> R {
    return try self.withUnsafeBufferPointer {
      try body(UnsafeRawBufferPointer($0))
    }
  }
}

@_unavailableInEmbedded
extension Array: _HasCustomAnyHashableRepresentation
  where Element: Hashable {
  public __consuming func _toCustomAnyHashable() -> AnyHashable? {
    return AnyHashable(_box: _ArrayAnyHashableBox(self))
  }
}

@_unavailableInEmbedded
internal protocol _ArrayAnyHashableProtocol: _AnyHashableBox {
  var count: Int { get }
  subscript(index: Int) -> AnyHashable { get }
}

@_unavailableInEmbedded
internal struct _ArrayAnyHashableBox<Element: Hashable>
  : _ArrayAnyHashableProtocol {
  internal let _value: [Element]

  internal init(_ value: [Element]) {
    self._value = value
  }

  internal var _base: Any {
    return _value
  }

  internal var count: Int {
    return _value.count
  }

  internal subscript(index: Int) -> AnyHashable {
    return _value[index] as AnyHashable
  }

  func _isEqual(to other: _AnyHashableBox) -> Bool? {
    guard let other = other as? _ArrayAnyHashableProtocol else { return nil }
    guard _value.count == other.count else { return false }
    for i in 0 ..< _value.count {
      if self[i] != other[i] { return false }
    }
    return true
  }

  var _hashValue: Int {
    var hasher = Hasher()
    _hash(into: &hasher)
    return hasher.finalize()
  }

  func _hash(into hasher: inout Hasher) {
    hasher.combine(_value.count) // discriminator
    for i in 0 ..< _value.count {
      hasher.combine(self[i])
    }
  }

  func _rawHashValue(_seed: Int) -> Int {
    var hasher = Hasher(_seed: _seed)
    self._hash(into: &hasher)
    return hasher._finalize()
  }

  internal func _unbox<T : Hashable>() -> T? {
    return _value as? T
  }

  internal func _downCastConditional<T>(
    into result: UnsafeMutablePointer<T>
  ) -> Bool {
    guard let value = _value as? T else { return false }
    result.initialize(to: value)
    return true
  }
}
