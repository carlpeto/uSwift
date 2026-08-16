import uSwiftShims

@inlinable
@inline(__always)
internal func _minAllocationAlignment() -> Int {
  return Int(bitPattern: UInt(_swift_MinAllocationAlignment))
}


@inline(__always)
@inlinable
@_unavailableInEmbedded
public func _bridgeObject(fromNative x: AnyObject) -> Builtin.BridgeObject {
  // _sanityCheck(!_isObjCTaggedPointer(x))
  let object = Builtin.castToBridgeObject(x, Int(0)._builtinWordValue)
  // _sanityCheck(_isNativePointer(object))
  return object
}

// @inline(__always)
// @inlinable
// public func _bridgeObject(
//   fromNonTaggedObjC x: AnyObject
// ) -> Builtin.BridgeObject {
//   // _sanityCheck(!_isObjCTaggedPointer(x))
//   let object = _makeObjCBridgeObject(x)
//   // _sanityCheck(_isNonTaggedObjCPointer(object))
//   return object
// }

@inline(__always)
@inlinable
public func _bridgeObject(fromTagged x: UInt) -> Builtin.BridgeObject {
  // _sanityCheck(x & _objCTaggedPointerBits != 0)
  let object: Builtin.BridgeObject = Builtin.valueToBridgeObject(x._value)
  // _sanityCheck(_isTaggedObject(object))
  return object
}

// @inline(__always)
// @inlinable
// public func _bridgeObject(taggingPayload x: UInt) -> Builtin.BridgeObject {
//   let shifted = x &<< _objectPointerLowSpareBitShift
//   // _sanityCheck(x == (shifted &>> _objectPointerLowSpareBitShift),
//   //   "out-of-range: limited bit range requires some zero top bits")
//   // _sanityCheck(shifted & _objCTaggedPointerBits == 0,
//   //   "out-of-range: post-shift use of tag bits")
//   return _bridgeObject(fromTagged: shifted | _objCTaggedPointerBits)
// }

// BridgeObject -> Values
@inline(__always)
@inlinable
public func _bridgeObject(toNative x: Builtin.BridgeObject) -> AnyObject {
  // _sanityCheck(_isNativePointer(x))
  return Builtin.castReferenceFromBridgeObject(x)
}

@inline(__always)
@inlinable
public func _bridgeObject(
  toNonTaggedObjC x: Builtin.BridgeObject
) -> AnyObject {
  // _sanityCheck(_isNonTaggedObjCPointer(x))
  return Builtin.castReferenceFromBridgeObject(x)
}

@inline(__always)
@inlinable
public func _bridgeObject(toTagged x: Builtin.BridgeObject) -> UInt {
  // _sanityCheck(_isTaggedObject(x))
  let bits = _bitPattern(x)
  // _sanityCheck(bits & _objCTaggedPointerBits != 0)
  return bits
}

// @inline(__always)
// @inlinable
// public func _bridgeObject(toTagPayload x: Builtin.BridgeObject) -> UInt {
//   return _getNonTagBits(x)
// }

@inline(__always)
@inlinable
@_unavailableInEmbedded
public func _bridgeObject(
  fromNativeObject x: Builtin.NativeObject
) -> Builtin.BridgeObject {
  return _bridgeObject(fromNative: _nativeObject(toNative: x))
}

@inline(__always)
@inlinable
@_unavailableInEmbedded
public func _nativeObject(fromNative x: AnyObject) -> Builtin.NativeObject {
  // _sanityCheck(!_isObjCTaggedPointer(x))
  let native = Builtin.unsafeCastToNativeObject(x)
  // _sanityCheck(native == Builtin.castToNativeObject(x))
  return native
}
@inline(__always)
@inlinable
@_unavailableInEmbedded
public func _nativeObject(
  fromBridge x: Builtin.BridgeObject
) -> Builtin.NativeObject {
  return _nativeObject(fromNative: _bridgeObject(toNative: x))
}

@inline(__always)
@inlinable
public func _nativeObject(toNative x: Builtin.NativeObject) -> AnyObject {
  return Builtin.castFromNativeObject(x)
}

@inlinable // FIXME(sil-serialize-all)
@inline(__always)
@_unavailableInEmbedded
internal func _makeNativeBridgeObject(
  _ nativeObject: AnyObject, _ bits: UInt
) -> Builtin.BridgeObject {
  // _sanityCheck(
  //   (bits & _objectPointerIsObjCBit) == 0,
  //   "BridgeObject is treated as non-native when ObjC bit is set"
  // )
  return _makeBridgeObject(nativeObject, bits)
}

// @inlinable // FIXME(sil-serialize-all)
// @inline(__always)
// public // @testable
// func _makeObjCBridgeObject(
//   _ objCObject: AnyObject
// ) -> Builtin.BridgeObject {
//   return _makeBridgeObject(
//     objCObject,
//     _isObjCTaggedPointer(objCObject) ? 0 : _objectPointerIsObjCBit)
// }

@inlinable // FIXME(sil-serialize-all)
@inline(__always)
@_unavailableInEmbedded
internal func _makeBridgeObject(
  _ object: AnyObject, _ bits: UInt
) -> Builtin.BridgeObject {
  // _sanityCheck(!_isObjCTaggedPointer(object) || bits == 0,
  //   "Tagged pointers cannot be combined with bits")

  // _sanityCheck(
  //   _isObjCTaggedPointer(object)
  //   || _usesNativeSwiftReferenceCounting(type(of: object))
  //   || bits == _objectPointerIsObjCBit,
  //   "All spare bits must be set in non-native, non-tagged bridge objects"
  // )

  // _sanityCheck(
  //   bits & _objectPointerSpareBits == bits,
  //   "Can't store non-spare bits into Builtin.BridgeObject")

  return Builtin.castToBridgeObject(
    object, bits._builtinWordValue
  )
}
