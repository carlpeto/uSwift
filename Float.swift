import uSwiftShims

@frozen
public struct Float : ExpressibleByFloatLiteral, _ExpressibleByBuiltinFloatLiteral {
  public // @testable
  var _value: Builtin.FPIEEE32

  @_transparent
  public init() {
    let zero: Int32 = 0
    self._value = Builtin.sitofp_Int32_FPIEEE32(zero._value)
  }

  @_transparent
  public // @testable
  init(_ _value: Builtin.FPIEEE32) {
    self._value = _value
  }

  @_transparent
  public
  init(_builtinFloatLiteral value: _MaxBuiltinFloatType) {
    self = Float(Builtin.fptrunc_FPIEEE64_FPIEEE32(value))
  }

  @_transparent
  public init(floatLiteral value: Float) {
    self = value
  }
}

extension Float: BinaryFloatingPoint {
  public typealias Magnitude = Float
  public typealias Exponent = Int
  public typealias RawSignificand = UInt32
 
  @inlinable
  public static var exponentBitCount: Int {
    return 8
  }

  @inlinable
  public static var significandBitCount: Int {
    return 23
  }

  @inlinable
  public var bitPattern: UInt32 {
    return UInt32(Builtin.bitcast_FPIEEE32_Int32(_value))
  }

  @inlinable
  public init(bitPattern: UInt32) {
    self.init(Builtin.bitcast_Int32_FPIEEE32(bitPattern._value))
  }

  @inlinable
  public var sign: FloatingPointSign {
    let shift = Float.significandBitCount + Float.exponentBitCount
    return FloatingPointSign(rawValue: Int(bitPattern &>> UInt32(shift)))!
  }

  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _infinityExponent: UInt {
    @inline(__always) get { return 1 &<< UInt(exponentBitCount) - 1 }
  }

  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _exponentBias: UInt {
    @inline(__always) get { return _infinityExponent &>> 1 }
  }

  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _significandMask: UInt32 {
    @inline(__always) get {
      return 1 &<< UInt32(significandBitCount) - 1
    }
  }

  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _quietNaNMask: UInt32 {
    @inline(__always) get {
      return 1 &<< UInt32(significandBitCount - 1)
    }
  }

  @inlinable
  public var exponentBitPattern: UInt {
    return UInt(bitPattern &>> UInt32(Float.significandBitCount)) &
      Float._infinityExponent
  }

  @inlinable
  public var significandBitPattern: UInt32 {
    return UInt32(bitPattern) & Float._significandMask
  }

  @inlinable
  public init(sign: FloatingPointSign,
              exponentBitPattern: UInt,
              significandBitPattern: UInt32) {
    let signShift = Float.significandBitCount + Float.exponentBitCount
    let sign = UInt32(sign == .minus ? 1 : 0)
    let exponent = UInt32(
      exponentBitPattern & Float._infinityExponent)
    let significand = UInt32(
      significandBitPattern & Float._significandMask)
    self.init(bitPattern:
      sign &<< UInt32(signShift) |
      exponent &<< UInt32(Float.significandBitCount) |
      significand)
  }

  @inlinable
  public var isCanonical: Bool {
    return true
  }

  @inlinable
  public static var infinity: Float {
    return Float(bitPattern: 0b0_11111111_00000000000000000000000)
  }

  @inlinable
  public static var nan: Float {
    return Float(bitPattern: 0b0_11111111_10000000000000000000000)
  }

  @inlinable
  public static var signalingNaN: Float {
    return Float(nan: 0, signaling: true)
  }

  @available(*, unavailable, renamed: "nan")
  public static var quietNaN: Float { Builtin.unreachable() }

  @inlinable
  public static var greatestFiniteMagnitude: Float {
    return 0x1.fffffep127
  }

  @inlinable
  public static var pi: Float {
    return 0x1.921fb4p1
  }

  @inlinable
  public var ulp: Float {
    guard _fastPath(isFinite) else { return .nan }
    if _fastPath(isNormal) {
      let bitPattern_ = bitPattern & Float.infinity.bitPattern
      return Float(bitPattern: bitPattern_) * 0x1p-23
    }
    // On arm, flush subnormal values to 0.
    return .leastNormalMagnitude * 0x1p-23
  }

  @inlinable
  public static var leastNormalMagnitude: Float {
    return 0x1p-126
  }

  @inlinable
  public static var leastNonzeroMagnitude: Float {
    return 0x1p-149
  }

  @inlinable
  public static var ulpOfOne: Float {
    return 0x1p-23
  }

  @inlinable
  public var exponent: Int {
    if !isFinite { return .max }
    if isZero { return .min }
    let provisional = Int(exponentBitPattern) - Int(Float._exponentBias)
    if isNormal { return provisional }
    let shift =
      Float.significandBitCount - significandBitPattern._binaryLogarithm()
    return provisional + 1 - shift
  }

  @inlinable
  public var significand: Float {
    if isNaN { return self }
    if isNormal {
      return Float(sign: .plus,
        exponentBitPattern: Float._exponentBias,
        significandBitPattern: significandBitPattern)
    }
    if isSubnormal {
      let shift =
        Float.significandBitCount - significandBitPattern._binaryLogarithm()
      return Float(sign: .plus,
        exponentBitPattern: Float._exponentBias,
        significandBitPattern: significandBitPattern &<< shift)
    }
    // zero or infinity.
    return Float(sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: 0)
  }

  @inlinable
  public init(sign: FloatingPointSign, exponent: Int, significand: Float) {
    var result = significand
    if sign == .minus { result = -result }
    if significand.isFinite && !significand.isZero {
      var clamped = exponent
      let leastNormalExponent = 1 - Int(Float._exponentBias)
      let greatestFiniteExponent = Int(Float._exponentBias)
      if clamped < leastNormalExponent {
        clamped = max(clamped, 3*leastNormalExponent)
        while clamped < leastNormalExponent {
          result  *= Float.leastNormalMagnitude
          clamped -= leastNormalExponent
        }
      }
      else if clamped > greatestFiniteExponent {
        clamped = min(clamped, 3*greatestFiniteExponent)
        let step = Float(sign: .plus,
          exponentBitPattern: Float._infinityExponent - 1,
          significandBitPattern: 0)
        while clamped > greatestFiniteExponent {
          result  *= step
          clamped -= greatestFiniteExponent
        }
      }
      let scale = Float(sign: .plus,
        exponentBitPattern: UInt(Int(Float._exponentBias) + clamped),
        significandBitPattern: 0)
      result = result * scale
    }
    self = result
  }

  @inlinable
  public init(nan payload: RawSignificand, signaling: Bool) {
    // We use significandBitCount - 2 bits for NaN payload.
    _precondition(payload < (Float._quietNaNMask &>> 1))
    var significand = payload
    significand |= Float._quietNaNMask &>> (signaling ? 1 : 0)
    self.init(sign: .plus,
              exponentBitPattern: Float._infinityExponent,
              significandBitPattern: significand)
  }

  @inlinable
  public var nextUp: Float {
    // Silence signaling NaNs, map -0 to +0.
    let x = self + 0

    if _fastPath(x < .infinity) {
      let increment = Int32(bitPattern: x.bitPattern) &>> 31 | 1
      let bitPattern_ = x.bitPattern &+ UInt32(bitPattern: increment)
      return Float(bitPattern: bitPattern_)
    }
    return x
  }

  @_transparent
  public mutating func round(_ rule: FloatingPointRoundingRule) {
    switch rule {
    case .toNearestOrAwayFromZero:
      _value = Builtin.int_round_FPIEEE32(_value)
    case .toNearestOrEven:
      _value = Builtin.int_rint_FPIEEE32(_value)
    case .towardZero:
      _value = Builtin.int_trunc_FPIEEE32(_value)
    case .awayFromZero:
      if sign == .minus {
        _value = Builtin.int_floor_FPIEEE32(_value)
      }
      else {
        _value = Builtin.int_ceil_FPIEEE32(_value)
      }
    case .up:
      _value = Builtin.int_ceil_FPIEEE32(_value)
    case .down:
      _value = Builtin.int_floor_FPIEEE32(_value)
    @unknown default:
      self._roundSlowPath(rule)
    }
  }
  
  // Slow path for new cases that might have been inlined into an old
  // ABI-stable version of round(_:) called from a newer version. If this is
  // the case, this non-inlinable function will call into the _newer_ version
  // which _will_ support this rounding rule.
  @usableFromInline
  internal mutating func _roundSlowPath(_ rule: FloatingPointRoundingRule) {
    self.round(rule)
  }

  @_transparent
  public func isEqual(to other: Float) -> Bool {
    return Bool(Builtin.fcmp_oeq_FPIEEE32(self._value, other._value))
  }

  @_transparent
  public func isLess(than other: Float) -> Bool {
    return Bool(Builtin.fcmp_olt_FPIEEE32(self._value, other._value))
  }

  @_transparent
  public func isLessThanOrEqualTo(_ other: Float) -> Bool {
    return Bool(Builtin.fcmp_ole_FPIEEE32(self._value, other._value))
  }

  @inlinable // FIXME(inline-always)
  public var isNormal: Bool {
    @inline(__always)
    get {
      return exponentBitPattern > 0 && isFinite
    }
  }

  @inlinable // FIXME(inline-always)
  public var isFinite: Bool {
    @inline(__always)
    get {
      return exponentBitPattern < Float._infinityExponent
    }
  }

  @inlinable // FIXME(inline-always)
  public var isZero: Bool {
    @inline(__always)
    get {
      return exponentBitPattern == 0 && significandBitPattern == 0
    }
  }

  @inlinable // FIXME(inline-always)
  public var isSubnormal:  Bool {
    @inline(__always)
    get {
      return exponentBitPattern == 0 && significandBitPattern != 0
    }
  }

  @inlinable // FIXME(inline-always)
  public var isInfinite:  Bool {
    @inline(__always)
    get {
      return !isFinite && significandBitPattern == 0
    }
  }

  @inlinable // FIXME(inline-always)
  public var isNaN:  Bool {
    @inline(__always)
    get {
      return !isFinite && significandBitPattern != 0
    }
  }

  @inlinable // FIXME(inline-always)
  public var isSignalingNaN: Bool {
    @inline(__always)
    get {
      return isNaN && (significandBitPattern & Float._quietNaNMask) == 0
    }
  }

  @inlinable
  public var binade: Float {
    guard _fastPath(isFinite) else { return .nan }
    return Float(bitPattern: bitPattern & (-Float.infinity).bitPattern)
  }

  @inlinable
  public var significandWidth: Int {
    let trailingZeroBits = significandBitPattern.trailingZeroBitCount
    if isNormal {
      guard significandBitPattern != 0 else { return 0 }
      return Float.significandBitCount &- trailingZeroBits
    }
    if isSubnormal {
      let leadingZeroBits = significandBitPattern.leadingZeroBitCount
      return UInt32.bitWidth &- (trailingZeroBits &+ leadingZeroBits &+ 1)
    }
    return -1
  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public mutating func formRemainder(dividingBy other: Float) {
    self = _stdlib_remainderf(self, other)
  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public mutating func formTruncatingRemainder(dividingBy other: Float) {
    _value = Builtin.frem_FPIEEE32(self._value, other._value)
  }

  @_transparent
  public mutating func formSquareRoot( ) {
    self = _stdlib_squareRootf(self)
  }

  @_transparent
  public mutating func addProduct(_ lhs: Float, _ rhs: Float) {
    _value = Builtin.int_fma_FPIEEE32(lhs._value, rhs._value, _value)
  }

  @_transparent
  public mutating func negate() {
    _value = Builtin.fneg_FPIEEE32(self._value)
  }

  @_transparent
  public static func +=(lhs: inout Float, rhs: Float) {
    lhs._value = Builtin.fadd_FPIEEE32(lhs._value, rhs._value)
  }

  @_transparent
  public static func -=(lhs: inout Float, rhs: Float) {
    lhs._value = Builtin.fsub_FPIEEE32(lhs._value, rhs._value)
  }

  @_transparent
  public static func *=(lhs: inout Float, rhs: Float) {
    lhs._value = Builtin.fmul_FPIEEE32(lhs._value, rhs._value)
  }

  @_transparent
  public static func /=(lhs: inout Float, rhs: Float) {
    lhs._value = Builtin.fdiv_FPIEEE32(lhs._value, rhs._value)
  }


  // the implementation of the _convert workaround, in the longer run this
  // will no longer be needed and we will be able to restore the _convert
  // static function on the protocol extension on the BinaryFloatingPoint protocol

  public static func _convertFloat(
    from source: Float
  ) -> (value: Self, exact: Bool) {
    return (source, true)
  }

  public static func _convertFloat16(
    from source: Float16
  ) -> (value: Self, exact: Bool) {
        return (Float(Builtin.fpext_FPIEEE16_FPIEEE32(source._value)), true)

// alternative implementation
    // return (Float(sign: source.sign,
    //  exponentBitPattern: source.exponentBitPattern,
    //   significandBitPattern: UInt32(source.significandBitPattern)), true)
  }
}

extension Float : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral {
  @_transparent
  public
  init(_builtinIntegerLiteral value: Builtin.IntLiteral){
    self = Float(Builtin.itofp_with_overflow_IntLiteral_FPIEEE32(value))
  }

  @_transparent
  public init(integerLiteral value: Int64) {
    self = Float(Builtin.sitofp_Int64_FPIEEE32(value._value))
  }
}

extension Float : Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    var v = self
    if isZero {
      // To satisfy the axiom that equality implies hash equality, we need to
      // finesse the hash value of -0.0 to match +0.0.
      v = 0
    }
    hasher.combine(v.bitPattern)
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    // To satisfy the axiom that equality implies hash equality, we need to
    // finesse the hash value of -0.0 to match +0.0.
    let v = isZero ? 0 : self
    return Hasher._hash(seed: seed, bytes: UInt64(v.bitPattern), count: 4)
  }
}

@_unavailableInEmbedded
extension Float: _HasCustomAnyHashableRepresentation {
  // Not @inlinable
  @_unavailableInEmbedded
  public func _toCustomAnyHashable() -> AnyHashable? {
    return AnyHashable(_box: _FloatAnyHashableBox(self))
  }
}

extension Float {
  @inlinable // FIXME(inline-always)
  public var magnitude: Float {
    @inline(__always)
    get {
      return Float(Builtin.int_fabs_FPIEEE32(_value))
    }
  }
}

extension Float {
  @_transparent
  public static prefix func - (x: Float) -> Float {
    return Float(Builtin.fneg_FPIEEE32(x._value))
  }
}

extension Float {
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init(_ other: Float) {
    _value = other._value
  }
}

extension Float {
  @_transparent
  public static func + (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func - (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func * (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func / (lhs: Float, rhs: Float) -> Float {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }
}

extension Float : Strideable {
  @_transparent
  public func distance(to other: Float) -> Float {
    return other - self
  }

  @_transparent
  public func advanced(by amount: Float) -> Float {
    return self + amount
  }
}

@_unavailableInEmbedded
internal struct _FloatAnyHashableBox: _AnyHashableBox {
  internal typealias Base = Float
  internal let _value: Base

  internal init(_ value: Base) {
    self._value = value
  }

  internal var _canonicalBox: _AnyHashableBox {
    // Float and Double are bridged with NSNumber, so we have to follow
    // NSNumber's rules for equality.  I.e., we need to make sure equal
    // numerical values end up in identical boxes after canonicalization, so
    // that _isEqual will consider them equal and they're hashed the same way.
    //
    // Note that these AnyHashable boxes don't currently feed discriminator bits
    // to the hasher, so we allow repeatable collisions. E.g., -1 will always
    // collide with UInt64.max.
    if _value < 0 {
      if let i = Int64(exactly: _value) {
        return _IntegerAnyHashableBox(i)
      }
    } else {
      if let i = UInt64(exactly: _value) {
        return _IntegerAnyHashableBox(i)
      }
    }
    // if let d = Double(exactly: _value) {
    //   return _DoubleAnyHashableBox(d)
    // }
    // If a value can't be represented by a Double, keep it in its original
    // representation so that it won't compare equal to approximations. (So that
    // we don't round off Float80 values.)
    return self
  }

  internal func _isEqual(to box: _AnyHashableBox) -> Bool? {
    _internalInvariant(Int64(exactly: _value) == nil)
    _internalInvariant(UInt64(exactly: _value) == nil)
    if let box = box as? _FloatAnyHashableBox {
      return _value == box._value
    }
    return nil
  }

  internal var _hashValue: Int {
    return _rawHashValue(_seed: 0)
  }

  internal func _hash(into hasher: inout Hasher) {
    _internalInvariant(Int64(exactly: _value) == nil)
    _internalInvariant(UInt64(exactly: _value) == nil)
    hasher.combine(_value)
  }

  internal func _rawHashValue(_seed: Int) -> Int {
    var hasher = Hasher(_seed: _seed)
    _hash(into: &hasher)
    return hasher.finalize()
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

public typealias FloatLiteralType = Float

// test it all compiles
public let testFloatingPointSystemIntact = 5.673
