//===----------------------------------------------------------------------===//
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

@_unavailableInEmbedded
public protocol _HasCustomAnyHashableRepresentation {
  __consuming func _toCustomAnyHashable() -> AnyHashable?
}

@_unavailableInEmbedded
@usableFromInline
internal protocol _AnyHashableBox {
  var _canonicalBox: _AnyHashableBox { get }

  func _isEqual(to box: _AnyHashableBox) -> Bool?
  var _hashValue: Int { get }
  func _hash(into hasher: inout Hasher)
  func _rawHashValue(_seed: Int) -> Int

  var _base: Any { get }
  func _unbox<T: Hashable>() -> T?
  func _downCastConditional<T>(into result: UnsafeMutablePointer<T>) -> Bool
}

@_unavailableInEmbedded
extension _AnyHashableBox {
  var _canonicalBox: _AnyHashableBox {
    return self
  }
}

@_unavailableInEmbedded
internal struct _ConcreteHashableBox<Base : Hashable> : _AnyHashableBox {
  internal var _baseHashable: Base

  internal init(_ base: Base) {
    self._baseHashable = base
  }

  internal func _unbox<T : Hashable>() -> T? {
    return (self as _AnyHashableBox as? _ConcreteHashableBox<T>)?._baseHashable
  }

  internal func _isEqual(to rhs: _AnyHashableBox) -> Bool? {
    if let rhs: Base = rhs._unbox() {
      return _baseHashable == rhs
    }
    return nil
  }

  internal var _hashValue: Int {
    return _baseHashable.hashValue
  }

  func _hash(into hasher: inout Hasher) {
    _baseHashable.hash(into: &hasher)
  }

  func _rawHashValue(_seed: Int) -> Int {
    return _baseHashable._rawHashValue(seed: _seed)
  }

  internal var _base: Any {
    return _baseHashable
  }

  internal
  func _downCastConditional<T>(into result: UnsafeMutablePointer<T>) -> Bool {
    guard let value = _baseHashable as? T else { return false }
    result.initialize(to: value)
    return true
  }
}

@_unavailableInEmbedded
@frozen
public struct AnyHashable {
  internal var _box: _AnyHashableBox

  internal init(_box box: _AnyHashableBox) {
    self._box = box
  }

  public init<H : Hashable>(_ base: H) {
    if let custom =
      (base as? _HasCustomAnyHashableRepresentation)?._toCustomAnyHashable() {
      self = custom
      return
    }

    self.init(_box: _ConcreteHashableBox(false)) // Dummy value
    _makeAnyHashableUpcastingToHashableBaseType(
      base,
      storingResultInto: &self)
  }

  internal init<H : Hashable>(_usingDefaultRepresentationOf base: H) {
    self._box = _ConcreteHashableBox(base)
  }

  public var base: Any {
    return _box._base
  }

  internal
  func _downCastConditional<T>(into result: UnsafeMutablePointer<T>) -> Bool {
    // Attempt the downcast.
    if _box._downCastConditional(into: result) { return true }

    #if _runtime(_ObjC)
    // Bridge to Objective-C and then attempt the cast from there.
    // FIXME: This should also work without the Objective-C runtime.
    if let value = _bridgeAnythingToObjectiveC(_box._base) as? T {
      result.initialize(to: value)
      return true
    }
    #endif

    return false
  }
}

@_unavailableInEmbedded
extension AnyHashable : Equatable {
  public static func == (lhs: AnyHashable, rhs: AnyHashable) -> Bool {
    return lhs._box._canonicalBox._isEqual(to: rhs._box._canonicalBox) ?? false
  }
}

@_unavailableInEmbedded
extension AnyHashable : Hashable {
  public var hashValue: Int {
    return _box._canonicalBox._hashValue
  }

  public func hash(into hasher: inout Hasher) {
    _box._canonicalBox._hash(into: &hasher)
  }

  public func _rawHashValue(seed: Int) -> Int {
    return _box._canonicalBox._rawHashValue(_seed: seed)
  }
}

// extension AnyHashable : CustomStringConvertible {
//   public var description: String {
//     return String(describing: base)
//   }
// }

// extension AnyHashable : CustomDebugStringConvertible {
//   public var debugDescription: String {
//     return "AnyHashable(" + String(reflecting: base) + ")"
//   }
// }

// extension AnyHashable : CustomReflectable {
//   public var customMirror: Mirror {
//     return Mirror(
//       self,
//       children: ["value": base])
//   }
// }

@_silgen_name("_swift_makeAnyHashableUsingDefaultRepresentation")
@_unavailableInEmbedded
internal func _makeAnyHashableUsingDefaultRepresentation<H : Hashable>(
  of value: H,
  storingResultInto result: UnsafeMutablePointer<AnyHashable>
) {
  result.pointee = AnyHashable(_usingDefaultRepresentationOf: value)
}

@_silgen_name("_swift_makeAnyHashableUpcastingToHashableBaseType")
@_unavailableInEmbedded
internal func _makeAnyHashableUpcastingToHashableBaseType<H : Hashable>(
  _ value: H,
  storingResultInto result: UnsafeMutablePointer<AnyHashable>
)

@inlinable
@_unavailableInEmbedded
public // COMPILER_INTRINSIC
func _convertToAnyHashable<H : Hashable>(_ value: H) -> AnyHashable {
  return AnyHashable(value)
}

@_silgen_name("_swift_convertToAnyHashableIndirect")
@_unavailableInEmbedded
internal func _convertToAnyHashableIndirect<H : Hashable>(
  _ value: H,
  _ target: UnsafeMutablePointer<AnyHashable>
) {
  target.initialize(to: AnyHashable(value))
}

@_silgen_name("_swift_anyHashableDownCastConditionalIndirect")
@_unavailableInEmbedded
internal func _anyHashableDownCastConditionalIndirect<T>(
  _ value: UnsafePointer<AnyHashable>,
  _ target: UnsafeMutablePointer<T>
) -> Bool {
  return value.pointee._downCastConditional(into: target)
}
