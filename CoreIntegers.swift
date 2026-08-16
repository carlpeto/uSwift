// the protocols for integer types
// signed or unsigned

public protocol SignedInteger : BinaryInteger, SignedNumeric {}

public protocol UnsignedInteger : BinaryInteger {}

extension UnsignedInteger where Self : FixedWidthInteger {
  // @inlinable // FIXME(sil-serialize-all)
  // @_semantics("optimize.sil.specialize.generic.partial.never")
  // @inline(__always)
  // public init<T : BinaryInteger>(_ source: T) {
  //   self.init(truncatingIfNeeded: source)
  // }

  @inlinable // FIXME(inline-always)
  public var magnitude: Self {
    @inline(__always)
    get { return self }
  }

   @_transparent
  public static var isSigned: Bool { return false }
}

extension UnsignedInteger where Self : FixedWidthInteger {
  @_semantics("optimize.sil.specialize.generic.partial.never")
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init<T : BinaryInteger>(_ source: T) {
    // // This check is potentially removable by the optimizer
    // if T.isSigned {
    //   _precondition(source >= (0 as T))
    // }
    // // This check is potentially removable by the optimizer
    // if source.bitWidth >= Self.bitWidth {
    //   _precondition(source <= Self.max)
    // }
    self.init(truncatingIfNeeded: source)
  }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init?<T : BinaryInteger>(exactly source: T) {
    // This check is potentially removable by the optimizer
    if T.isSigned && source < T(0) {
      return nil
    }
    // The width check can be eliminated by the optimizer
    if source.bitWidth >= Self.bitWidth &&
       source > Self.max {
      return nil
    }
    self.init(truncatingIfNeeded: source)
  }

  @_transparent
  public static var max: Self { return ~0 }

  @_transparent
  public static var min: Self { return 0 }
}

extension SignedInteger where Self : FixedWidthInteger {
  // @inlinable // FIXME(sil-serialize-all)
  // @_semantics("optimize.sil.specialize.generic.partial.never")
  // @inline(__always)
  // public init<T : BinaryInteger>(_ source: T) {
  //   self.init(truncatingIfNeeded: source)
  // }

  @_transparent
  public static var isSigned: Bool { return true }
}

extension SignedInteger where Self : FixedWidthInteger {
  @_semantics("optimize.sil.specialize.generic.partial.never")
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init<T : BinaryInteger>(_ source: T) {
    // This check is potentially removable by the optimizer
    // if T.isSigned && source.bitWidth > Self.bitWidth {
    //   _precondition(source >= Self.min)
    // }
    // // This check is potentially removable by the optimizer
    // if (source.bitWidth > Self.bitWidth) ||
    //    (source.bitWidth == Self.bitWidth && !T.isSigned) {
    //   _precondition(source <= Self.max)
    // }
    self.init(truncatingIfNeeded: source)
  }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init?<T : BinaryInteger>(exactly source: T) {
    // This check is potentially removable by the optimizer
    if T.isSigned && source.bitWidth > Self.bitWidth && source < Self.min {
      return nil
    }
    // The width check can be eliminated by the optimizer
    if (source.bitWidth > Self.bitWidth ||
        (source.bitWidth == Self.bitWidth && !T.isSigned)) &&
       source > Self.max {
      return nil
    }
    self.init(truncatingIfNeeded: source)
  }

  @_transparent
  public static var max: Self { return ~min }

  @_transparent
  public static var min: Self {
    return (-1 as Self) &<< Self._highBitIndex
  }

  @inlinable
  public func isMultiple(of other: Self) -> Bool {
    // Nothing but zero is a multiple of zero.
    if other == 0 { return self == 0 }
    // Special case to avoid overflow on .min / -1 for signed types.
    if other == (-1 as Self) { return true }
    // Having handled those special cases, this is safe.
    return self % other == 0
  }
}

@inlinable
public func numericCast<T : BinaryInteger, U : BinaryInteger>(_ x: T) -> U {
  return U(x)
}

@usableFromInline
@_silgen_name("_swift_isClassOrObjCExistentialType")
internal func _swift_isClassOrObjCExistentialType<T>(_ x: T.Type) -> Bool

@inlinable
@inline(__always)
internal func _isClassOrObjCExistential<T>(_ x: T.Type) -> Bool {

  switch _canBeClass(x) {
  // Is not a class.
  case 0:
    return false
  // Is a class.
  case 1:
    return true
  // Maybe a class.
  default:
    return _swift_isClassOrObjCExistentialType(x)
  }
}

@_unavailableInEmbedded
internal struct _IntegerAnyHashableBox<
  Base: FixedWidthInteger
>: _AnyHashableBox {
  internal let _value: Base

  internal init(_ value: Base) {
    self._value = value
  }

  internal var _canonicalBox: _AnyHashableBox {
    // We need to follow NSNumber semantics here; the AnyHashable forms of
    // integer types holding the same mathematical value should compare equal.
    // Sign-extend value to a 64-bit integer. This will generate hash conflicts
    // between, say -1 and UInt.max, but that's fine.
    if _value < 0 {
      return _IntegerAnyHashableBox<Int64>(Int64(truncatingIfNeeded: _value))
    }
    return _IntegerAnyHashableBox<UInt64>(UInt64(truncatingIfNeeded: _value))
  }

  internal func _isEqual(to box: _AnyHashableBox) -> Bool? {
    if Base.self == UInt64.self {
      guard let box = box as? _IntegerAnyHashableBox<UInt64> else { return nil }
      return _value == box._value
    }
    if Base.self == Int64.self {
      guard let box = box as? _IntegerAnyHashableBox<Int64> else { return nil }
      return _value == box._value
    }
    _preconditionFailure()
    return nil
  }

  internal var _hashValue: Int {
    _internalInvariant(Base.self == UInt64.self || Base.self == Int64.self)
    return _value.hashValue
  }

  internal func _hash(into hasher: inout Hasher) {
    _internalInvariant(Base.self == UInt64.self || Base.self == Int64.self)
    _value.hash(into: &hasher)
  }

  internal func _rawHashValue(_seed: Int) -> Int {
    _internalInvariant(Base.self == UInt64.self || Base.self == Int64.self)
    return _value._rawHashValue(seed: _seed)
  }

  internal var _base: Any {
    return _value
  }

  internal func _unbox<T: Hashable>() -> T? {
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
