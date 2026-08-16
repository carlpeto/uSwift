//===--- ArrayBufferProtocol.swift ----------------------------------------===//
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
internal protocol _ArrayBufferProtocol
  : MutableCollection, RandomAccessCollection 
where Indices == Range<Int> {

#if FORCE_MAIN_SWIFT_ARRAYS
  typealias __Buffer = _ContiguousArrayBuffer
#else
  typealias __Buffer = _AVRArrayBuffer
#endif

  init()

  init(_buffer: __Buffer<Element>, shiftedToStartIndex: Int)

  init?(copying buffer: Self)

  @discardableResult
  __consuming func _copyContents(
    subRange bounds: Range<Int>,
    initializing target: UnsafeMutablePointer<Element>
  ) -> UnsafeMutablePointer<Element>

  // mutating func requestUniqueMutableBackingBuffer(
  //   minimumCapacity: Int
  // ) -> __Buffer<Element>?

  mutating func isMutableAndUniquelyReferenced() -> Bool

  func requestNativeBuffer() -> __Buffer<Element>?

  // mutating func replaceSubrange<C>(
  //   _ subrange: Range<Int>,
  //   with newCount: Int,
  //   elementsOf newValues: __owned C
  // ) where C : Collection, C.Element == Element

  subscript(bounds: Range<Int>) -> _SliceBuffer<Element> { get }

  func withUnsafeBufferPointer<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R

  mutating func withUnsafeMutableBufferPointer<R>(
    _ body: (UnsafeMutableBufferPointer<Element>) throws -> R
  ) rethrows -> R

  override var count: Int { get set }

  var capacity: Int { get }

  // var owner: AnyObject { get }

  var firstElementAddress: UnsafeMutablePointer<Element> { get }

  var firstElementAddressIfContiguous: UnsafeMutablePointer<Element>? { get }

  var subscriptBaseAddress: UnsafeMutablePointer<Element> { get }

  var identity: UnsafeRawPointer { get }
}

extension _ArrayBufferProtocol where Indices == Range<Int>{

  @inlinable
  internal var subscriptBaseAddress: UnsafeMutablePointer<Element> {
    return firstElementAddress
  }

  // Make sure the compiler does not inline _copyBuffer to reduce code size.
  @inline(never)
  @inlinable // This code should be specializable such that copying an array is
             // fast and does not end up in an unspecialized entry point.
  internal init?(copying buffer: Self) {
    let newBuffer = __Buffer<Element>(
      _uninitializedCount: buffer.count, minimumCapacity: buffer.count)

#if !FORCE_MAIN_SWIFT_ARRAYS
    guard let newBuffer else {
      return nil
    }
#endif

    buffer._copyContents(
      subRange: buffer.indices,
      initializing: newBuffer.firstElementAddress)
    self = Self( _buffer: newBuffer, shiftedToStartIndex: buffer.startIndex)
  }

  @inlinable
  internal mutating func replaceSubrange<C>(
    _ subrange: Range<Int>,
    with newCount: Int,
    elementsOf newValues: __owned C
  ) where C : Collection, C.Element == Element {
    _internalInvariant(startIndex == 0)
    let oldCount = self.count
    let eraseCount = subrange.count

    let growth = newCount - eraseCount
    self.count = oldCount + growth

    let elements = self.subscriptBaseAddress
    let oldTailIndex = subrange.upperBound
    let oldTailStart = elements + oldTailIndex
    let newTailIndex = oldTailIndex + growth
    let newTailStart = oldTailStart + growth
    let tailCount = oldCount - subrange.upperBound

    if growth > 0 {
      // Slide the tail part of the buffer forwards, in reverse order
      // so as not to self-clobber.
      newTailStart.moveInitialize(from: oldTailStart, count: tailCount)

      // Assign over the original subrange
      var i = newValues.startIndex
      for j in subrange {
        elements[j] = newValues[i]
        newValues.formIndex(after: &i)
      }
      // Initialize the hole left by sliding the tail forward
      for j in oldTailIndex..<newTailIndex {
        (elements + j).initialize(to: newValues[i])
        newValues.formIndex(after: &i)
      }
      _expectEnd(of: newValues, is: i)
    }
    else { // We're not growing the buffer
      // Assign all the new elements into the start of the subrange
      var i = subrange.lowerBound
      var j = newValues.startIndex
      for _ in 0..<newCount {
        elements[i] = newValues[j]
        i += 1
        newValues.formIndex(after: &j)
      }
      _expectEnd(of: newValues, is: j)

      // If the size didn't change, we're done.
      if growth == 0 {
        return
      }

      // Move the tail backward to cover the shrinkage.
      let shrinkage = -growth
      if tailCount > shrinkage {   // If the tail length exceeds the shrinkage

        // Assign over the rest of the replaced range with the first
        // part of the tail.
        newTailStart.moveAssign(from: oldTailStart, count: shrinkage)

        // Slide the rest of the tail back
        oldTailStart.moveInitialize(
          from: oldTailStart + shrinkage, count: tailCount - shrinkage)
      }
      else {                      // Tail fits within erased elements
        // Assign over the start of the replaced range with the tail
        newTailStart.moveAssign(from: oldTailStart, count: tailCount)

        // Destroy elements remaining after the tail in subrange
        (newTailStart + tailCount).deinitialize(
          count: shrinkage - tailCount)
      }
    }
  }
}
