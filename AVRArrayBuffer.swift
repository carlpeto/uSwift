import uSwiftShims

#if !UNMANAGED_ARRAYS
@usableFromInline
internal class _AVRArrayBufferStorageManager {
  // this is the raw pointer for the internal buffer of the AVR Array Buffer storage
  // we use it here to avoid the complexities/overhead of generic type parameters on this class
  // the deinit will internally destroy this buffer as deallocate() would
  // use of the buffer or array after a manual deallocate will create havoc
  // the microcontroller will probably let you write into random memory... don't do it
  internal var _rawValue: Builtin.RawPointer

  @usableFromInline
  init(_ _rawValue: Builtin.RawPointer) {
    self._rawValue = _rawValue
  }

  deinit {
    // check not already deallocated
    guard Int(Builtin.ptrtoint_Word(_rawValue)) != 0 else {
      return
    }

    Builtin.deallocRaw(_rawValue, (-1 as Int)._builtinWordValue, (0 as Int)._builtinWordValue)
  }
}
#endif

@usableFromInline
@frozen
internal struct _AVRArrayBuffer<Element> : _ArrayBufferProtocol {
  public var _countAndCapacity: _ArrayBody

  @usableFromInline
  internal var _storage: UnsafeMutableBufferPointer<Element>

#if !UNMANAGED_ARRAYS
  @usableFromInline
  internal var _storageSentinel: _AVRArrayBufferStorageManager?
#endif

  @inlinable
  public mutating func deallocate() {
#if UNMANAGED_ARRAYS
    _storage.deallocate()
#else
    _storageSentinel = nil
#endif
  }

  // AVR/uSwift note: if there is no memory available, this initialiser will 'fail'
  // and return nil (because the underlying UnsafeMutableBufferPointer.allocate will return nil)

  // we use a fixed buffer malloced on the heap
  // in later implementation, promote to alloca
  @inlinable
  @inline(__always)
  internal init?(
    _uninitializedCount uninitializedCount: Int,
    minimumCapacity: Int
  ) {
    let realMinimumCapacity = Swift.max(uninitializedCount, minimumCapacity)
    // malloc_size doesn't exist on avr gnu libc and allocations are
    // assumed byte aligned, so assume the allocation matches the request
    let realCapacity = realMinimumCapacity

    guard let buffer = UnsafeMutableBufferPointer<Element>.allocate(capacity: realCapacity) else {
      return nil
    }

    _storage = buffer
#if !UNMANAGED_ARRAYS
    _storageSentinel = _AVRArrayBufferStorageManager(buffer._position!._rawValue)
#endif
    _countAndCapacity = _ArrayBody(
      count: uninitializedCount,
      capacity: realCapacity,
      elementTypeIsBridgedVerbatim: false)
  }

  @inlinable
  internal init(count: Int, storage: UnsafeMutableBufferPointer<Element>) {
    _storage = storage
#if !UNMANAGED_ARRAYS
    _storageSentinel = _AVRArrayBufferStorageManager(storage._position!._rawValue)
#endif
    _countAndCapacity = _ArrayBody(
      count: count,
      capacity: count,
      elementTypeIsBridgedVerbatim: false)
  }

  @inlinable
  internal init(_ storage: UnsafeMutableBufferPointer<Element>) {
    _storage = storage
#if !UNMANAGED_ARRAYS
    _storageSentinel = _AVRArrayBufferStorageManager(storage._position!._rawValue)
#endif
    _countAndCapacity = _ArrayBody(
      count: storage.count,
      capacity: storage.count,
      elementTypeIsBridgedVerbatim: false)
  }

  @inlinable
  internal var arrayPropertyIsNativeTypeChecked: Bool {
    return true
  }

  @inlinable
  internal var firstElementAddress: UnsafeMutablePointer<Element> {
    return _storage._position!
  }

  @inlinable
  internal var firstElementAddressIfContiguous: UnsafeMutablePointer<Element>? {
    return firstElementAddress
  }

  @inlinable
  internal func withUnsafeBufferPointer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    defer { _fixLifetime(self) }
    return try body(UnsafeBufferPointer(start: firstElementAddress,
      count: count))
  }

  @inlinable
  internal mutating func withUnsafeMutableBufferPointer<R>(
    _ body: (UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R {
    defer { _fixLifetime(self) }
    return try body(
      UnsafeMutableBufferPointer(start: firstElementAddress, count: count))
  }

  //===--- _ArrayBufferProtocol conformance -----------------------------------===//
  // private func dummyNilBuffer() -> UnsafeMutableBufferPointer<Element> {
  //   UnsafeMutableBufferPointer<Element>(start: UnsafeMutablePointer(nil), count: 0)
  // }

  @inlinable
  internal init() {
    // _storage = dummyNilBuffer()
    //UnsafeMutableBufferPointer.allocate(capacity: 0) // dummy buffer
    _storage = UnsafeMutableBufferPointer(_empty: ()) // empty buffer
#if !UNMANAGED_ARRAYS
    _storageSentinel = nil
#endif
    _countAndCapacity = _ArrayBody(
      count: 0,
      capacity: 0,
      elementTypeIsBridgedVerbatim: false)
  }

  @inlinable
  internal init(_buffer buffer: _AVRArrayBuffer, shiftedToStartIndex: Int) {
    _internalInvariant(shiftedToStartIndex == 0)
    self = buffer
  }

  @inlinable
  internal mutating func requestUniqueMutableBackingBuffer(
    minimumCapacity: Int
  ) -> _AVRArrayBuffer<Element>? {
    return self
  }

  @inlinable
  internal mutating func isMutableAndUniquelyReferenced() -> Bool {
    return true
  }

  @inlinable
  internal func requestNativeBuffer() -> _AVRArrayBuffer<Element>? {
    return self
  }

  @inlinable
  @inline(__always)
  internal func getElement(_ i: Int) -> Element {
    _internalInvariant(i >= 0 && i < count)
    return firstElementAddress[i]
  }

  @inlinable
  internal subscript(i: Int) -> Element {
    @inline(__always)
    get {
      return getElement(i)
    }
    @inline(__always)
    nonmutating set {
      _internalInvariant(i >= 0 && i < count)

      // FIXME: Manually swap because it makes the ARC optimizer happy.  See
      // <rdar://problem/16831852> check retain/release order
      // firstElementAddress[i] = newValue
      var nv = newValue
      let tmp = nv
      nv = firstElementAddress[i]
      firstElementAddress[i] = tmp
    }
  }

  @inlinable
  internal var count: Int {
    get {
      return _countAndCapacity.count
    }
    set {
      _internalInvariant(newValue >= 0)

      _internalInvariant(newValue <= capacity)

      _countAndCapacity.count = newValue
    }
  }

  @inlinable
  @inline(__always)
  internal func _checkValidSubscript(_ index : inout Int) {
    if index < 0 || count == 0 {
      // add a weak symbol here that people can link in debugging for OOB checks if they require
      // i.e. add a symbol that has a weak linked variant with the same signature that's a noop
      // so it should get optimised away in normal builds
      _microswift_array_out_of_bounds(&index,count);
    } else if index >= count {
      // add a weak symbol here that people can link in debugging for OOB checks if they require
      // i.e. add a symbol that has a weak linked variant with the same signature that's a noop
      // so it should get optimised away in normal builds
      _microswift_array_out_of_bounds(&index,count);
    }
    _precondition((index >= 0) && (index < count))
  }

  @inlinable
  internal var capacity: Int {
    return _countAndCapacity.capacity
  }

  @inlinable
  @discardableResult
  internal __consuming func _copyContents(
    subRange bounds: Range<Int>,
    initializing target: UnsafeMutablePointer<Element>
  ) -> UnsafeMutablePointer<Element> {
    _internalInvariant(bounds.lowerBound >= 0)
    _internalInvariant(bounds.upperBound >= bounds.lowerBound)
    _internalInvariant(bounds.upperBound <= count)

    let initializedCount = bounds.upperBound - bounds.lowerBound
    target.initialize(
      from: firstElementAddress + bounds.lowerBound, count: initializedCount)
    // _fixLifetime(owner)
    return target + initializedCount
  }

  public __consuming func _copyContents(
    initializing buffer: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index) {
    // This customization point is not implemented for internal types.
    // Accidentally calling it would be a catastrophic performance bug.
    fatalError()
  }

  @inlinable
  internal subscript(bounds: Range<Int>) -> _SliceBuffer<Element> {
    get {
      return _SliceBuffer(
        subscriptBaseAddress: subscriptBaseAddress,
        indices: bounds,
        hasNativeBuffer: true)
    }
    set {
      fatalError()
    }
  }

  @inlinable
  internal mutating func isUniquelyReferenced() -> Bool {
    return true
  }

  // @inlinable
  // internal var owner: AnyObject {
  //   return _storage
  // }

  // @inlinable
  // internal var nativeOwner: AnyObject {
  //   return _storage
  // }

  @inlinable
  internal var identity: UnsafeRawPointer {
    return UnsafeRawPointer(firstElementAddress)
  }

  @inlinable
  func canStoreElements(ofDynamicType proposedElementType: Any.Type) -> Bool {
    return false
  }
}

@available(*, unavailable, message: "AVR Arrays are fixed size")
@inlinable
internal func += <Element, C : Collection>(
  lhs: inout _AVRArrayBuffer<Element>, rhs: __owned C
) where C.Element == Element {
  return

  // let oldCount = lhs.count
  // let newCount = oldCount + numericCast(rhs.count)

  // let buf: UnsafeMutableBufferPointer<Element>

  // if _fastPath(newCount <= lhs.capacity) {
  //   buf = UnsafeMutableBufferPointer(start: lhs.firstElementAddress + oldCount, count: numericCast(rhs.count))
  //   lhs.count = newCount
  // }
  // else {
  //   var newLHS = _ContiguousArrayBuffer<Element>(
  //     _uninitializedCount: newCount,
  //     minimumCapacity: _growArrayCapacity(lhs.capacity))

  //   newLHS.firstElementAddress.moveInitialize(
  //     from: lhs.firstElementAddress, count: oldCount)
  //   lhs.count = 0
  //   (lhs, newLHS) = (newLHS, lhs)
  //   buf = UnsafeMutableBufferPointer(start: lhs.firstElementAddress + oldCount, count: numericCast(rhs.count))
  // }

  // var (remainders,writtenUpTo) = buf.initialize(from: rhs)

  // // ensure that exactly rhs.count elements were written
  // _precondition(remainders.next() == nil)
  // _precondition(writtenUpTo == buf.endIndex)
}

extension _AVRArrayBuffer : RandomAccessCollection {
  @inlinable
  internal var startIndex: Int {
    return 0
  }
  @inlinable
  internal var endIndex: Int {
    return count
  }

  @usableFromInline
  internal typealias Indices = Range<Int>
}

#if !FORCE_MAIN_SWIFT_ARRAYS
extension Sequence {
  @available(*, deprecated, message: "AVR Arrays should not be created from a sequence, see uSwift documentation")
  @inlinable
  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
    return ContiguousArray<Element>()
    // return _copySequenceToContiguousArray(self)
  }
}

// we only support create/copy from collection, because we need a fixed size
// buffer and sequence sizes are not definitively known
@available(*, unavailable, message: "AVR Arrays cannot be created from a sequence, use a collection instead")
@inlinable
internal func _copySequenceToContiguousArray<
  S : Sequence
>(_ source: S) -> ContiguousArray<S.Element> {

  // dummy
  return Array<S.Element>()

  // let initialCapacity = source.underestimatedCount
  // var builder =
  //   _UnsafePartiallyInitializedContiguousArrayBuffer<S.Element>(
  //     initialCapacity: initialCapacity)

  // var iterator = source.makeIterator()

  // // FIXME(performance): use _copyContents(initializing:).

  // // Add elements up to the initial capacity without checking for regrowth.
  // for _ in 0..<initialCapacity {
  //   builder.addWithExistingCapacity(iterator.next()!)
  // }

  // // Add remaining elements, if any.
  // while let element = iterator.next() {
  //   builder.add(element)
  // }

  // return builder.finish()
}
#endif













extension Collection {
  @inlinable
  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element>? {
    return _copyCollectionToContiguousArray(self)
  }
}

extension _AVRArrayBuffer {
  @inlinable
  internal __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
    return ContiguousArray(_buffer: self)
  }
}

@inlinable
internal func _copyCollectionToContiguousArray<
  C : Collection
>(_ source: C) -> ContiguousArray<C.Element>?
{
  let count: Int = numericCast(source.count)
  if count == 0 {
    return ContiguousArray()
  }

  guard let result = _AVRArrayBuffer<C.Element>(
    _uninitializedCount: count,
    minimumCapacity: 0) else {
    return nil
  }

  let p = UnsafeMutableBufferPointer(start: result.firstElementAddress, count: count)
  var (itr, end) = source._copyContents(initializing: p)

  _debugPrecondition(itr.next() == nil)
  // We also have to check the evil shrink case in release builds, because
  // it can result in uninitialized array elements and therefore undefined
  // behavior.
  _precondition(end == p.endIndex)

  return ContiguousArray(_buffer: result)
}

// @available(*, unavailable, message: "AVR Arrays are fixed size")
// @usableFromInline
// @frozen
// internal struct _UnsafePartiallyInitializedContiguousArrayBuffer<Element> {
//   @usableFromInline
//   internal var result: _ContiguousArrayBuffer<Element>
//   @usableFromInline
//   internal var p: UnsafeMutablePointer<Element>
//   @usableFromInline
//   internal var remainingCapacity: Int

//   @inlinable
//   @inline(__always) // For performance reasons.
//   internal init(initialCapacity: Int) {
//     if initialCapacity == 0 {
//       result = _ContiguousArrayBuffer()
//     } else {
//       result = _ContiguousArrayBuffer(
//         _uninitializedCount: initialCapacity,
//         minimumCapacity: 0)
//     }

//     p = result.firstElementAddress
//     remainingCapacity = result.capacity
//   }

//   @inlinable
//   @inline(__always) // For performance reasons.
//   internal mutating func add(_ element: Element) {
//     if remainingCapacity == 0 {
//       // Reallocate.
//       let newCapacity = max(_growArrayCapacity(result.capacity), 1)
//       var newResult = _ContiguousArrayBuffer<Element>(
//         _uninitializedCount: newCapacity, minimumCapacity: 0)
//       p = newResult.firstElementAddress + result.capacity
//       remainingCapacity = newResult.capacity - result.capacity
//       if !result.isEmpty {
//         // This check prevents a data race writting to _swiftEmptyArrayStorage
//         // Since count is always 0 there, this code does nothing anyway
//         newResult.firstElementAddress.moveInitialize(
//           from: result.firstElementAddress, count: result.capacity)
//         result.count = 0
//       }
//       (result, newResult) = (newResult, result)
//     }
//     addWithExistingCapacity(element)
//   }

//   @inlinable
//   @inline(__always) // For performance reasons.
//   internal mutating func addWithExistingCapacity(_ element: Element) {
//     _internalInvariant(remainingCapacity > 0)
//     remainingCapacity -= 1

//     p.initialize(to: element)
//     p += 1
//   }

//   @inlinable
//   @inline(__always) // For performance reasons.
//   internal mutating func finish() -> ContiguousArray<Element> {
//     // Adjust the initialized count of the buffer.
//     result.count = result.capacity - remainingCapacity

//     return finishWithOriginalCount()
//   }

//   @inlinable
//   @inline(__always) // For performance reasons.
//   internal mutating func finishWithOriginalCount() -> ContiguousArray<Element> {
//     _internalInvariant(remainingCapacity == result.capacity - result.count)
//     var finalResult = _ContiguousArrayBuffer<Element>()
//     (finalResult, result) = (result, finalResult)
//     remainingCapacity = 0
//     return ContiguousArray(_buffer: finalResult)
//   }
// }
