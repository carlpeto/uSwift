//===--- ManagedBuffer.swift - variable-sized buffer of aligned memory ----===//
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

import uSwiftShims

// @usableFromInline
// internal typealias _HeapObject = uSwiftShims.HeapObject

@usableFromInline
@_silgen_name("swift_bufferAllocate")
internal func _swift_bufferAllocate(
  bufferType type: AnyClass,
  size: Int,
  alignmentMask: Int
) -> AnyObject

// @_fixed_layout
// open class ManagedBuffer<Header, Element> {
//   public final var header: Header

//   // This is really unfortunate. In Swift 5.0, the method descriptor for this
//   // initializer was public and subclasses would "inherit" it, referencing its
//   // method descriptor from their class override table.
//   @usableFromInline
//   internal init(_doNotCallMe: ()) {
//     _internalInvariantFailure()
//   }
// }

// extension ManagedBuffer {
//   @inlinable
//   public final class func create(
//     minimumCapacity: Int,
//     makingHeaderWith factory: (
//       ManagedBuffer<Header, Element>) throws -> Header
//   ) rethrows -> ManagedBuffer<Header, Element> {

//     let p = Builtin.allocWithTailElems_1(
//          self,
//          minimumCapacity._builtinWordValue, Element.self)

//     let initHeaderVal = try factory(p)
//     p.headerAddress.initialize(to: initHeaderVal)
//     // The _fixLifetime is not really needed, because p is used afterwards.
//     // But let's be conservative and fix the lifetime after we use the
//     // headerAddress.
//     _fixLifetime(p)
//     return p
//   }

//   @inlinable
//   public final var capacity: Int {
//     let storageAddr = UnsafeMutableRawPointer(Builtin.bridgeToRawPointer(self))
//     let endAddr = storageAddr + _swift_stdlib_malloc_size(storageAddr)
//     let realCapacity = endAddr.assumingMemoryBound(to: Element.self) -
//       firstElementAddress
//     return realCapacity
//   }

//   @inlinable
//   internal final var firstElementAddress: UnsafeMutablePointer<Element> {
//     return UnsafeMutablePointer(
//       Builtin.projectTailElems(self, Element.self))
//   }

//   @inlinable
//   internal final var headerAddress: UnsafeMutablePointer<Header> {
//     return UnsafeMutablePointer<Header>(Builtin.addressof(&header))
//   }

//   @inlinable
//   public final func withUnsafeMutablePointerToHeader<R>(
//     _ body: (UnsafeMutablePointer<Header>) throws -> R
//   ) rethrows -> R {
//     return try withUnsafeMutablePointers { (v, _) in return try body(v) }
//   }

//   @inlinable
//   public final func withUnsafeMutablePointerToElements<R>(
//     _ body: (UnsafeMutablePointer<Element>) throws -> R
//   ) rethrows -> R {
//     return try withUnsafeMutablePointers { return try body($1) }
//   }

//   @inlinable
//   public final func withUnsafeMutablePointers<R>(
//     _ body: (UnsafeMutablePointer<Header>, UnsafeMutablePointer<Element>) throws -> R
//   ) rethrows -> R {
//     defer { _fixLifetime(self) }
//     return try body(headerAddress, firstElementAddress)
//   }
// }

// @frozen
// public struct ManagedBufferPointer<Header, Element> {

//   @usableFromInline
//   internal var _nativeBuffer: Builtin.NativeObject

//   @inlinable
//   public init(
//     bufferClass: AnyClass,
//     minimumCapacity: Int,
//     makingHeaderWith factory:
//       (_ buffer: AnyObject, _ capacity: (AnyObject) -> Int) throws -> Header
//   ) rethrows {
//     self = ManagedBufferPointer(
//       bufferClass: bufferClass, minimumCapacity: minimumCapacity)

//     // initialize the header field
//     try withUnsafeMutablePointerToHeader {
//       $0.initialize(to: 
//         try factory(
//           self.buffer,
//           {
//             ManagedBufferPointer(unsafeBufferObject: $0).capacity
//           }))
//     }
//     // FIXME: workaround for <rdar://problem/18619176>.  If we don't
//     // access header somewhere, its addressor gets linked away
//     _ = header
//   }

//   @inlinable
//   public init(unsafeBufferObject buffer: AnyObject) {
//     ManagedBufferPointer._checkValidBufferClass(type(of: buffer))

//     self._nativeBuffer = Builtin.unsafeCastToNativeObject(buffer)
//   }

//   //===--- internal/private API -------------------------------------------===//

//   @inlinable
//   internal init(_uncheckedUnsafeBufferObject buffer: AnyObject) {
//     ManagedBufferPointer._internalInvariantValidBufferClass(type(of: buffer))
//     self._nativeBuffer = Builtin.unsafeCastToNativeObject(buffer)
//   }

//   @inlinable
//   internal init(
//     bufferClass: AnyClass,
//     minimumCapacity: Int
//   ) {
//     ManagedBufferPointer._checkValidBufferClass(bufferClass, creating: true)
//     _precondition(
//       minimumCapacity >= 0)

//     self.init(
//       _uncheckedBufferClass: bufferClass, minimumCapacity: minimumCapacity)
//   }

//   @inlinable
//   internal init(
//     _uncheckedBufferClass: AnyClass,
//     minimumCapacity: Int
//   ) {
//     ManagedBufferPointer._internalInvariantValidBufferClass(_uncheckedBufferClass, creating: true)
//     _internalInvariant(
//       minimumCapacity >= 0)

//     let totalSize = ManagedBufferPointer._elementOffset
//       +  minimumCapacity * MemoryLayout<Element>.stride

//     let newBuffer: AnyObject = _swift_bufferAllocate(
//       bufferType: _uncheckedBufferClass,
//       size: totalSize,
//       alignmentMask: ManagedBufferPointer._alignmentMask)

//     self._nativeBuffer = Builtin.unsafeCastToNativeObject(newBuffer)
//   }

//   @inlinable
//   internal init(_ buffer: ManagedBuffer<Header, Element>) {
//     _nativeBuffer = Builtin.unsafeCastToNativeObject(buffer)
//   }
// }

// extension ManagedBufferPointer {
//   @inlinable
//   public var header: Header {
//     _read {
//       yield _headerPointer.pointee
//     }
//     _modify {
//       yield &_headerPointer.pointee
//     }
//   }

//   @inlinable
//   public var buffer: AnyObject {
//     return Builtin.castFromNativeObject(_nativeBuffer)
//   }

//   @inlinable
//   public var capacity: Int {
//     return (
//       _capacityInBytes &- ManagedBufferPointer._elementOffset
//     ) / MemoryLayout<Element>.stride
//   }

//   @inlinable
//   public func withUnsafeMutablePointerToHeader<R>(
//     _ body: (UnsafeMutablePointer<Header>) throws -> R
//   ) rethrows -> R {
//     return try withUnsafeMutablePointers { (v, _) in return try body(v) }
//   }

//   @inlinable
//   public func withUnsafeMutablePointerToElements<R>(
//     _ body: (UnsafeMutablePointer<Element>) throws -> R
//   ) rethrows -> R {
//     return try withUnsafeMutablePointers { return try body($1) }
//   }

//   @inlinable
//   public func withUnsafeMutablePointers<R>(
//     _ body: (UnsafeMutablePointer<Header>, UnsafeMutablePointer<Element>) throws -> R
//   ) rethrows -> R {
//     defer { _fixLifetime(_nativeBuffer) }
//     return try body(_headerPointer, _elementPointer)
//   }

//   @inlinable
//   public mutating func isUniqueReference() -> Bool {
//     return _isUnique(&_nativeBuffer)
//   }
// }

// extension ManagedBufferPointer {
//   @inlinable
//   internal static func _checkValidBufferClass(
//     _ bufferClass: AnyClass, creating: Bool = false
//   ) {
//     _debugPrecondition(
//       _class_getInstancePositiveExtentSize(bufferClass) == MemoryLayout<_HeapObject>.size
//       || (
//         (!creating || bufferClass is ManagedBuffer<Header, Element>.Type)
//         && _class_getInstancePositiveExtentSize(bufferClass)
//           == _headerOffset + MemoryLayout<Header>.size)
//     )
//     _debugPrecondition(
//       _usesNativeSwiftReferenceCounting(bufferClass)
//     )
//   }

//   @inlinable
//   internal static func _internalInvariantValidBufferClass(
//     _ bufferClass: AnyClass, creating: Bool = false
//   ) {
//     _internalInvariant(
//       _class_getInstancePositiveExtentSize(bufferClass) == MemoryLayout<_HeapObject>.size
//       || (
//         (!creating || bufferClass is ManagedBuffer<Header, Element>.Type)
//         && _class_getInstancePositiveExtentSize(bufferClass)
//           == _headerOffset + MemoryLayout<Header>.size)
//     )
//     _internalInvariant(
//       _usesNativeSwiftReferenceCounting(bufferClass)
//     )
//   }
// }

// extension ManagedBufferPointer {
//   @inlinable
//   internal static var _alignmentMask: Int {
//     return max(
//       MemoryLayout<_HeapObject>.alignment,
//       max(MemoryLayout<Header>.alignment, MemoryLayout<Element>.alignment)) &- 1
//   }

//   @inlinable
//   internal var _capacityInBytes: Int {
//     return _swift_stdlib_malloc_size(_address)
//   }

//   @inlinable
//   internal var _address: UnsafeMutableRawPointer {
//     return UnsafeMutableRawPointer(Builtin.bridgeToRawPointer(_nativeBuffer))
//   }

//   @inlinable
//   internal static var _headerOffset: Int {
//     _onFastPath()
//     return _roundUp(
//       MemoryLayout<_HeapObject>.size,
//       toAlignment: MemoryLayout<Header>.alignment)
//   }

//   @inlinable
//   internal var _headerPointer: UnsafeMutablePointer<Header> {
//     _onFastPath()
//     return (_address + ManagedBufferPointer._headerOffset).assumingMemoryBound(
//       to: Header.self)
//   }

//   @inlinable
//   internal var _elementPointer: UnsafeMutablePointer<Element> {
//     _onFastPath()
//     return (_address + ManagedBufferPointer._elementOffset).assumingMemoryBound(
//       to: Element.self)
//   }

//   @inlinable
//   internal static var _elementOffset: Int {
//     _onFastPath()
//     return _roundUp(
//       _headerOffset + MemoryLayout<Header>.size,
//       toAlignment: MemoryLayout<Element>.alignment)
//   }
// }

// extension ManagedBufferPointer: Equatable {
//   @inlinable
//   public static func == (
//     lhs: ManagedBufferPointer,
//     rhs: ManagedBufferPointer
//   ) -> Bool {
//     return lhs._address == rhs._address
//   }
// }

// FIXME: when our calling convention changes to pass self at +0,
// inout should be dropped from the arguments to these functions.
// FIXME(docs): isKnownUniquelyReferenced should check weak/unowned counts too, 
// but currently does not. rdar://problem/29341361

@inlinable
public func isKnownUniquelyReferenced<T : AnyObject>(_ object: inout T) -> Bool
{
  return _isUnique(&object)
}

#if $Embedded
@inlinable
public func isKnownUniquelyReferenced(_ object: inout Builtin.NativeObject) -> Bool
{
  return _isUnique(&object)
}
#endif

@inlinable
public func isKnownUniquelyReferenced<T : AnyObject>(
  _ object: inout T?
) -> Bool {
  return _isUnique(&object)
}
