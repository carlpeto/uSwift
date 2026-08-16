//===--- ArrayShared.swift ------------------------------------*- swift -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//

@frozen
public struct _DependenceToken {
  @inlinable
  public init() {
  }
}

// These two functions are used internally to create arrays from array literals.

@inlinable // FIXME(inline-always)
@inline(__always)
@_semantics("array.uninitialized_intrinsic")
public // COMPILER_INTRINSIC
func _allocateUninitializedArray<Element>(_  builtinCount: Builtin.Word)
    -> (Array<Element>, Builtin.RawPointer) {
  var count = Int(builtinCount)
  if count > 0 {
    // Doing the actual buffer allocation outside of the array.uninitialized
    // semantics function enables stack propagation of the buffer.
#if FORCE_MAIN_SWIFT_ARRAYS
    #if !$Embedded
    let bufferObject = Builtin.allocWithTailElems_1(
       getContiguousArrayStorageType(for: Element.self), builtinCount, Element.self)
    #else
    let bufferObject = Builtin.allocWithTailElems_1(
       _ContiguousArrayStorage<Element>.self, builtinCount, Element.self)
    #endif

    let (array, ptr) = Array<Element>._adoptStorage(bufferObject, count: count)
    return (array, ptr._rawValue)
#else
    if let bufferObject = UnsafeMutableBufferPointer<Element>.allocate(capacity: count) {
      let (array, ptr) = Array<Element>._adoptStorage(bufferObject, count: count)
      return (array, ptr._rawValue)      
    }
#endif
  }
  // For an empty array no buffer allocation is needed.
  let (array, ptr) = Array<Element>._allocateUninitialized(&count)
  return (array, ptr._rawValue)
}

// Referenced by the compiler to deallocate array literals on the
// error path.
@inlinable
@_semantics("array.dealloc_uninitialized")
public // COMPILER_INTRINSIC
func _deallocateUninitializedArray<Element>(
  _ array: __owned Array<Element>
) {
  var array = array
  array._deallocateUninitialized()
}

// extension Collection {  
//   // Utility method for collections that wish to implement
//   // CustomStringConvertible and CustomDebugStringConvertible using a bracketed
//   // list of elements, like an array.
//   internal func _makeCollectionDescription(
//     withTypeName type: String? = nil
//   ) -> String {
//     var result = ""
//     if let type = type {
//       result += "\(type)(["
//     } else {
//       result += "["
//     }

//     var first = true
//     for item in self {
//       if first {
//         first = false
//       } else {
//         result += ", "
//       }
//       debugPrint(item, terminator: "", to: &result)
//     }
//     result += type != nil ? "])" : "]"
//     return result
//   }
// }

extension _ArrayBufferProtocol {
  @available(*, unavailable, message: "AVR Arrays are fixed size, replace not supported")
  @inlinable // FIXME @useableFromInline https://bugs.swift.org/browse/SR-7588
  @inline(never)
  internal mutating func _arrayOutOfPlaceReplace<C: Collection>(
    _ bounds: Range<Int>,
    with newValues: __owned C,
    count insertCount: Int
  ) where C.Element == Element {
    return

    // let growth = insertCount - bounds.count
    // let newCount = self.count + growth
    // var newBuffer = _forceCreateUniqueMutableBuffer(
    //   newCount: newCount, requiredCapacity: newCount)

    // _arrayOutOfPlaceUpdate(
    //   &newBuffer, bounds.lowerBound - startIndex, insertCount,
    //   { rawMemory, count in
    //     var p = rawMemory
    //     var q = newValues.startIndex
    //     for _ in 0..<count {
    //       p.initialize(to: newValues[q])
    //       newValues.formIndex(after: &q)
    //       p += 1
    //     }
    //     _expectEnd(of: newValues, is: q)
    //   }
    // )
  }
}

@inlinable
internal func _expectEnd<C: Collection>(of s: C, is i: C.Index) {
  _debugPrecondition(i == s.endIndex)
}

@inlinable
internal func _growArrayCapacity(_ capacity: Int) -> Int {
  return capacity * 2
}

@_alwaysEmitIntoClient
internal func _growArrayCapacity(
  oldCapacity: Int, minimumCapacity: Int, growForAppend: Bool
) -> Int {
  if growForAppend {
    if oldCapacity < minimumCapacity {
      // When appending to an array, grow exponentially.
      return Swift.max(minimumCapacity, _growArrayCapacity(oldCapacity))
    }
    return oldCapacity
  }
  // If not for append, just use the specified capacity, ignoring oldCapacity.
  // This means that we "shrink" the buffer in case minimumCapacity is less
  // than oldCapacity.
  return minimumCapacity
}

//===--- generic helpers --------------------------------------------------===//

extension _ArrayBufferProtocol {
  @inline(never)
  @inlinable // @specializable
  internal func _forceCreateUniqueMutableBuffer(
    newCount: Int, requiredCapacity: Int
  ) -> __Buffer<Element>? {
    return _forceCreateUniqueMutableBufferImpl(
      countForBuffer: newCount, minNewCapacity: newCount,
      requiredCapacity: requiredCapacity)
  }

  @inline(never)
  @inlinable // @specializable
  internal func _forceCreateUniqueMutableBuffer(
    countForNewBuffer: Int, minNewCapacity: Int
  ) -> __Buffer<Element>? {
    return _forceCreateUniqueMutableBufferImpl(
      countForBuffer: countForNewBuffer, minNewCapacity: minNewCapacity,
      requiredCapacity: minNewCapacity)
  }

  @inlinable
  internal func _forceCreateUniqueMutableBufferImpl(
    countForBuffer: Int, minNewCapacity: Int,
    requiredCapacity: Int
  ) -> __Buffer<Element>? {
    _internalInvariant(countForBuffer >= 0)
    _internalInvariant(requiredCapacity >= countForBuffer)
    _internalInvariant(minNewCapacity >= countForBuffer)

    let minimumCapacity = Swift.max(requiredCapacity,
      minNewCapacity > capacity
         ? _growArrayCapacity(capacity) : capacity)

    return __Buffer(
      _uninitializedCount: countForBuffer, minimumCapacity: minimumCapacity)
  }
}

extension _ArrayBufferProtocol {
  @available(*, unavailable, message: "AVR Arrays are fixed size, replace not supported")
  @inline(never)
  @inlinable // @specializable
  internal mutating func _arrayOutOfPlaceUpdate(
    _ dest: inout __Buffer<Element>,
    _ headCount: Int, // Count of initial source elements to copy/move
    _ newCount: Int,  // Number of new elements to insert
    _ initializeNewElements: 
        ((UnsafeMutablePointer<Element>, _ count: Int) -> ()) = { ptr, count in
      _internalInvariant(count == 0)
    }
  ) {
    return

    // _internalInvariant(headCount >= 0)
    // _internalInvariant(newCount >= 0)

    // // Count of trailing source elements to copy/move
    // let sourceCount = self.count
    // let tailCount = dest.count - headCount - newCount
    // _internalInvariant(headCount + tailCount <= sourceCount)

    // let oldCount = sourceCount - headCount - tailCount
    // let destStart = dest.firstElementAddress
    // let newStart = destStart + headCount
    // let newEnd = newStart + newCount

    // // Check to see if we have storage we can move from
    // if let backing = requestUniqueMutableBackingBuffer(
    //   minimumCapacity: sourceCount) {

    //   let sourceStart = firstElementAddress
    //   let oldStart = sourceStart + headCount

    //   // Destroy any items that may be lurking in a _SliceBuffer before
    //   // its real first element
    //   let backingStart = backing.firstElementAddress
    //   let sourceOffset = sourceStart - backingStart
    //   backingStart.deinitialize(count: sourceOffset)

    //   // Move the head items
    //   destStart.moveInitialize(from: sourceStart, count: headCount)

    //   // Destroy unused source items
    //   oldStart.deinitialize(count: oldCount)

    //   initializeNewElements(newStart, newCount)

    //   // Move the tail items
    //   newEnd.moveInitialize(from: oldStart + oldCount, count: tailCount)

    //   // Destroy any items that may be lurking in a _SliceBuffer after
    //   // its real last element
    //   let backingEnd = backingStart + backing.count
    //   let sourceEnd = sourceStart + sourceCount
    //   sourceEnd.deinitialize(count: backingEnd - sourceEnd)
    //   backing.count = 0
    // }
    // else {
    //   let headStart = startIndex
    //   let headEnd = headStart + headCount
    //   let newStart = _copyContents(
    //     subRange: headStart..<headEnd,
    //     initializing: destStart)
    //   initializeNewElements(newStart, newCount)
    //   let tailStart = headEnd + oldCount
    //   let tailEnd = endIndex
    //   _copyContents(subRange: tailStart..<tailEnd, initializing: newEnd)
    // }
    // self = Self(_buffer: dest, shiftedToStartIndex: startIndex)
  }
}

extension _ArrayBufferProtocol {
  // hopefully this is a noop
  @inline(never)
  @usableFromInline
  internal mutating func _outlinedMakeUniqueBuffer(bufferCount: Int) {
    return

    // if _fastPath(
    //     requestUniqueMutableBackingBuffer(minimumCapacity: bufferCount) != nil) {
    //   return
    // }

    // var newBuffer = _forceCreateUniqueMutableBuffer(
    //   newCount: bufferCount, requiredCapacity: bufferCount)
    // _arrayOutOfPlaceUpdate(&newBuffer, bufferCount, 0)
  }

  @available(*, unavailable, message: "AVR Arrays are fixed size, replace not supported")
  @inlinable
  internal mutating func _arrayAppendSequence<S: Sequence>(
    _ newItems: __owned S
  ) where S.Element == Element {
    
    // // this function is only ever called from append(contentsOf:)
    // // which should always have exhausted its capacity before calling
    // _internalInvariant(count == capacity)
    // var newCount = self.count

    // // there might not be any elements to append remaining,
    // // so check for nil element first, then increase capacity,
    // // then inner-loop to fill that capacity with elements
    // var stream = newItems.makeIterator()
    // var nextItem = stream.next()
    // while nextItem != nil {

    //   // grow capacity, first time around and when filled
    //   var newBuffer = _forceCreateUniqueMutableBuffer(
    //     countForNewBuffer: newCount, 
    //     // minNewCapacity handles the exponential growth, just
    //     // need to request 1 more than current count/capacity
    //     minNewCapacity: newCount + 1)

    //   _arrayOutOfPlaceUpdate(&newBuffer, newCount, 0)

    //   let currentCapacity = self.capacity
    //   let base = self.firstElementAddress

    //   // fill while there is another item and spare capacity
    //   while let next = nextItem, newCount < currentCapacity {
    //     (base + newCount).initialize(to: next)
    //     newCount += 1
    //     nextItem = stream.next()
    //   }
    //   self.count = newCount
    // }
  }
}
