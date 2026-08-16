import uSwiftShims

@frozen
public struct Float16 {
  public // @testable
  var _value: Builtin.FPIEEE16

  @_transparent
  public init() {
    let zero: Int64 = 0
    self._value = Builtin.sitofp_Int64_FPIEEE16(zero._value)
  }

  @_transparent
  public // @testable
  init(_ _value: Builtin.FPIEEE16) {
    self._value = _value
  }
}

extension Float16: BinaryFloatingPoint {
  public typealias Magnitude = Float16
  public typealias Exponent = Int
  public typealias RawSignificand = UInt16

  @inlinable
  public static var exponentBitCount: Int {
    return 5
  }


  @inlinable
  public static var significandBitCount: Int {
    return 10
  }

  @inlinable
  public var bitPattern: UInt16 {
    return UInt16(Builtin.bitcast_FPIEEE16_Int16(_value))
  }

  @inlinable
  public init(bitPattern: UInt16) {
    self.init(Builtin.bitcast_Int16_FPIEEE16(bitPattern._value))
  }

  @inlinable
  public var sign: FloatingPointSign {
    let shift = Float16.significandBitCount + Float16.exponentBitCount
    return FloatingPointSign(
      rawValue: Int(bitPattern &>> UInt16(shift))
    )!
  }

  //  Implementation details.
  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _infinityExponent: UInt {
    @inline(__always) get { return 1 &<< UInt(exponentBitCount) - 1 }
  }

  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _exponentBias: UInt {
    @inline(__always) get { return _infinityExponent &>> 1 }
  }

  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _significandMask: UInt16 {
    @inline(__always) get {
      return 1 &<< UInt16(significandBitCount) - 1
    }
  }

  @inlinable // FIXME(inline-always) was usableFromInline
  internal static var _quietNaNMask: UInt16 {
    @inline(__always) get {
      return 1 &<< UInt16(significandBitCount - 1)
    }
  }

  @available(*, unavailable, renamed: "sign")
  public var isSignMinus: Bool { Builtin.unreachable() }

  @inlinable
  public var exponentBitPattern: UInt {
    return UInt(bitPattern &>> UInt16(Float16.significandBitCount)) &
      Float16._infinityExponent
  }

  @inlinable
  public var significandBitPattern: UInt16 {
    return UInt16(bitPattern) & Float16._significandMask
  }

  @inlinable
  public init(
    sign: FloatingPointSign,
    exponentBitPattern: UInt,
    significandBitPattern: UInt16
  ) {
    let signShift = Float16.significandBitCount + Float16.exponentBitCount
    let sign = UInt16(sign == .minus ? 1 : 0)
    let exponent = UInt16(
      exponentBitPattern & Float16._infinityExponent
    )
    let significand = UInt16(
      significandBitPattern & Float16._significandMask
    )
    self.init(bitPattern:
      sign &<< UInt16(signShift) |
      exponent &<< UInt16(Float16.significandBitCount) |
      significand
    )
  }

  @inlinable
  public var isCanonical: Bool {
    // All Float and Double encodings are canonical in IEEE 754.
    //
    // On platforms that do not support subnormals, we treat them as
    // non-canonical encodings of zero.
    if Self.leastNonzeroMagnitude == Self.leastNormalMagnitude {
      if exponentBitPattern == 0 && significandBitPattern != 0 {
        return false
      }
    }
    return true
  }


  @inlinable
  public static var infinity: Float16 {

    return Float16(
      sign: .plus,
      exponentBitPattern: _infinityExponent,
      significandBitPattern: 0
    )

  }

  @inlinable
  public static var nan: Float16 {

    return Float16(nan: 0, signaling: false)

  }

  @inlinable
  public static var signalingNaN: Float16 {
    return Float16(nan: 0, signaling: true)
  }

  @available(*, unavailable, renamed: "nan")  
  public static var quietNaN: Float16 { Builtin.unreachable() }

  @inlinable
  public static var greatestFiniteMagnitude: Float16 {

    return Float16(
      sign: .plus,
      exponentBitPattern: _infinityExponent - 1,
      significandBitPattern: _significandMask
    )

  }

  @inlinable
  public static var pi: Float16 {

    return 0x1.92p1

  }

  @inlinable
  public var ulp: Float16 {

    guard _fastPath(isFinite) else { return .nan }
    if _fastPath(isNormal) {
      let bitPattern_ = bitPattern & Float16.infinity.bitPattern
      return Float16(bitPattern: bitPattern_) * 0x1p-10
    }
    // On arm, flush subnormal values to 0.
    return .leastNormalMagnitude * 0x1p-10

  }

  @inlinable
  public static var leastNormalMagnitude: Float16 {
    return 0x1.0p-14
  }

  @inlinable
  public static var leastNonzeroMagnitude: Float16 {

    return leastNormalMagnitude * ulpOfOne
  }

  @inlinable
  public static var ulpOfOne: Float16 {
    return 0x1.0p-10
  }

  @inlinable
  public var exponent: Int {
    if !isFinite { return .max }
    if isZero { return .min }
    let provisional = Int(exponentBitPattern) - Int(Float16._exponentBias)
    if isNormal { return provisional }
    let shift =
      Float16.significandBitCount - significandBitPattern._binaryLogarithm()
    return provisional + 1 - shift
  }

  @inlinable
  public var significand: Float16 {
    if isNaN { return self }
    if isNormal {
      return Float16(sign: .plus,
        exponentBitPattern: Float16._exponentBias,
        significandBitPattern: significandBitPattern)
    }
    if isSubnormal {
      let shift =
        Float16.significandBitCount - significandBitPattern._binaryLogarithm()
      return Float16(
        sign: .plus,
        exponentBitPattern: Float16._exponentBias,
        significandBitPattern: significandBitPattern &<< shift
      )
    }
    // zero or infinity.
    return Float16(
      sign: .plus,
      exponentBitPattern: exponentBitPattern,
      significandBitPattern: 0
    )
  }

  @inlinable
  public init(sign: FloatingPointSign, exponent: Int, significand: Float16) {
    var result = significand
    if sign == .minus { result = -result }
    if significand.isFinite && !significand.isZero {
      var clamped = exponent
      let leastNormalExponent = 1 - Int(Float16._exponentBias)
      let greatestFiniteExponent = Int(Float16._exponentBias)
      if clamped < leastNormalExponent {
        clamped = max(clamped, 3*leastNormalExponent)
        while clamped < leastNormalExponent {
          result  *= Float16.leastNormalMagnitude
          clamped -= leastNormalExponent
        }
      }
      else if clamped > greatestFiniteExponent {
        clamped = min(clamped, 3*greatestFiniteExponent)
        let step = Float16(sign: .plus,
          exponentBitPattern: Float16._infinityExponent - 1,
          significandBitPattern: 0)
        while clamped > greatestFiniteExponent {
          result  *= step
          clamped -= greatestFiniteExponent
        }
      }
      let scale = Float16(
        sign: .plus,
        exponentBitPattern: UInt(Int(Float16._exponentBias) + clamped),
        significandBitPattern: 0
      )
      result = result * scale
    }
    self = result
  }

  @inlinable
  public init(nan payload: RawSignificand, signaling: Bool) {
    // We use significandBitCount - 2 bits for NaN payload.
    _precondition(payload < (Float16._quietNaNMask &>> 1))
    var significand = payload
    significand |= Float16._quietNaNMask &>> (signaling ? 1 : 0)
    self.init(
      sign: .plus,
      exponentBitPattern: Float16._infinityExponent,
      significandBitPattern: significand
    )
  }

  @inlinable
  public var nextUp: Float16 {

    // Silence signaling NaNs, map -0 to +0.
    let x = self + 0

    if _fastPath(x < .infinity) {
      let increment = Int16(bitPattern: x.bitPattern) &>> 15 | 1
      let bitPattern_ = x.bitPattern &+ UInt16(bitPattern: increment)
      return Float16(bitPattern: bitPattern_)
    }
    return x

  }

  //  For core standard library floating-point types, LLVM can lower copysign
  //  for us; this gets somewhat better codegen than the generic implementation,
  //  but more importantly allows it to participate in other optimizations
  //  at the LLVM level.
  @_transparent
  public init(signOf sign: Float16, magnitudeOf mag: Float16) {
    _value = Builtin.int_copysign_FPIEEE16(mag._value, sign._value)
  }

  @_transparent
  public mutating func round(_ rule: FloatingPointRoundingRule) {
    switch rule {
    case .toNearestOrAwayFromZero:
      _value = Builtin.int_round_FPIEEE16(_value)
    case .toNearestOrEven:
      _value = Builtin.int_rint_FPIEEE16(_value)
    case .towardZero:
      _value = Builtin.int_trunc_FPIEEE16(_value)
    case .awayFromZero:
      if sign == .minus {
        _value = Builtin.int_floor_FPIEEE16(_value)
      }
      else {
        _value = Builtin.int_ceil_FPIEEE16(_value)
      }
    case .up:
      _value = Builtin.int_ceil_FPIEEE16(_value)
    case .down:
      _value = Builtin.int_floor_FPIEEE16(_value)
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
  public mutating func negate() {
    _value = Builtin.fneg_FPIEEE16(self._value)
  }

  @_transparent
  public static func +=(lhs: inout Float16, rhs: Float16) {
    lhs._value = Builtin.fadd_FPIEEE16(lhs._value, rhs._value)
  }

  @_transparent
  public static func -=(lhs: inout Float16, rhs: Float16) {
    lhs._value = Builtin.fsub_FPIEEE16(lhs._value, rhs._value)
  }

  @_transparent
  public static func *=(lhs: inout Float16, rhs: Float16) {
    lhs._value = Builtin.fmul_FPIEEE16(lhs._value, rhs._value)
  }

  @_transparent
  public static func /=(lhs: inout Float16, rhs: Float16) {
    lhs._value = Builtin.fdiv_FPIEEE16(lhs._value, rhs._value)
  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public mutating func formRemainder(dividingBy other: Float16) {

    self = Float16(_stdlib_remainderf(Float(self), Float(other)))

  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public mutating func formTruncatingRemainder(dividingBy other: Float16) {
    _value = Builtin.frem_FPIEEE16(self._value, other._value)
  }

  @_transparent
  public mutating func formSquareRoot( ) {

    self = Float16(_stdlib_squareRootf(Float(self)))

  }

  @_transparent
  public mutating func addProduct(_ lhs: Float16, _ rhs: Float16) {
    _value = Builtin.int_fma_FPIEEE16(lhs._value, rhs._value, _value)
  }

  @_transparent
  public func isEqual(to other: Float16) -> Bool {
    return Bool(Builtin.fcmp_oeq_FPIEEE16(self._value, other._value))
  }

  @_transparent
  public func isLess(than other: Float16) -> Bool {
    return Bool(Builtin.fcmp_olt_FPIEEE16(self._value, other._value))
  }

  @_transparent
  public func isLessThanOrEqualTo(_ other: Float16) -> Bool {
    return Bool(Builtin.fcmp_ole_FPIEEE16(self._value, other._value))
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
      return exponentBitPattern < Float16._infinityExponent
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
      return isNaN && (significandBitPattern & Float16._quietNaNMask) == 0
    }
  }

  @inlinable
  public var binade: Float16 {

    guard _fastPath(isFinite) else { return .nan }

    return Float16(bitPattern: bitPattern & (-Float16.infinity).bitPattern)

  }

  @inlinable
  public var significandWidth: Int {
    let trailingZeroBits = significandBitPattern.trailingZeroBitCount
    if isNormal {
      guard significandBitPattern != 0 else { return 0 }
      return Float16.significandBitCount &- trailingZeroBits
    }
    if isSubnormal {
      let leadingZeroBits = significandBitPattern.leadingZeroBitCount
      return UInt16.bitWidth &- (trailingZeroBits &+ leadingZeroBits &+ 1)
    }
    return -1
  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init(floatLiteral value: Float16) {
    self = value
  }

  public static func _convertFloat(
    from source: Float
  ) -> (value: Self, exact: Bool) {
    return (Float16(Builtin.fptrunc_FPIEEE32_FPIEEE16(source._value)), false)
  
  // alternative implementation
    // // see if we can squeeze it in
    // // basically 0 goes to 0, -0 goes to -0, nan -> nan, inf -> inf
    // // then we look at the exponent and see if it fits in 5 bits
    // guard !source.isZero else {
    //   return (source.sign == .minus ? -0.0 as Float16 : 0.0 as Float16, true)
    // }

    // guard source.isFinite else {
    //   return (source.sign == .minus ? -.infinity : .infinity, true)
    // }

    // guard source.isSignalingNaN else {
    //   return (.signalingNaN, true)
    // }

    // guard source.isNaN else {
    //   return (.nan, true)
    // }

    // guard source.exponent >= -64, source.exponent <= 63 else {
    //   return (.nan, true)
    // }

    // return (
    //   Float16(sign: source.sign,
    //  exponentBitPattern: source.exponentBitPattern >> 3,
    //   significandBitPattern: UInt16(source.significandBitPattern)),
    //    false)
  }

  public static func _convertFloat16(
    from source: Float16
  ) -> (value: Self, exact: Bool) {
    return (source, true)
  }
}


extension Float16: _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral {
  @_transparent
  public
  init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    self = Float16(Builtin.itofp_with_overflow_IntLiteral_FPIEEE16(value))
  }

  @_transparent
  public init(integerLiteral value: Int64) {
    self = Float16(Builtin.sitofp_Int64_FPIEEE16(value._value))
  }
}

extension Float16: _ExpressibleByBuiltinFloatLiteral {
  @_transparent
  public
  init(_builtinFloatLiteral value: Builtin.FPIEEE64) {

    // FIXME: This can result in double rounding errors (SR-7124).
    self = Float16(Builtin.fptrunc_FPIEEE64_FPIEEE16(value))

  }
}

extension Float16: Hashable {
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

    return Hasher._hash(seed: seed, bytes: UInt64(v.bitPattern), count: 2)

  }
}

extension Float16 {
  @inlinable // FIXME(inline-always)
  public var magnitude: Float16 {
    @inline(__always)
    get {
      return Float16(Builtin.int_fabs_FPIEEE16(_value))
    }
  }
}


extension Float16 {
  @_transparent
  public static prefix func - (x: Float16) -> Float16 {
    return Float16(Builtin.fneg_FPIEEE16(x._value))
  }
}

extension Float16 {
  // Fast-path for conversion when the source is representable as int,
  // falling back on the generic _convert operation otherwise.
  // @_alwaysEmitIntoClient @inline(never)
  // public init?<Source: BinaryInteger>(exactly value: Source) {
  //   if value.bitWidth <= 128 {
  //     // If the source is small enough to fit in a word, we can use the LLVM
  //     // conversion intrinsic, then check if we can round-trip back to the
  //     // the original value; if so, the conversion was exact. We need to be
  //     // careful, however, to make sure that the first conversion does not
  //     // round to a value that is out of the defined range of the second
  //     // converion. E.g. Float(Int.max) rounds to Int.max + 1, and converting
  //     // that back to Int will trap. For Float, Double, and Float80, this is
  //     // only an issue for the upper bound (because the lower bound of [U]Int
  //     // is either zero or a power of two, both of which are exactly
  //     // representable). For Float16, we also need to check for overflow to
  //     // -.infinity.
  //     if Source.isSigned {
  //       let extended = Int(truncatingIfNeeded: value)
  //       _value = Builtin.sitofp_Int128_FPIEEE16(extended._value)

  //       guard self.isFinite && Int(self) == extended else {

  //         return nil
  //       }
  //     } else {
  //       let extended = UInt(truncatingIfNeeded: value)
  //       _value = Builtin.uitofp_Int128_FPIEEE16(extended._value)

  //       guard self.isFinite && UInt(self) == extended else {

  //         return nil
  //       }
  //     }
  //   } else {
  //     // TODO: we can do much better than the generic _convert here for Float
  //     // and Double by pulling out the high-order 32/64b of the integer, ORing
  //     // in a sticky bit, and then using the builtin.
  //     let (value_, exact) = Self._convert(from: value)
  //     guard exact else { return nil }
  //     self = value_
  //   }
  // }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init(_ other: Float16) {

    _value = other._value

  }

  @inlinable
  @inline(__always)
  public init?(exactly other: Float16) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float16(self) != other {
      return nil
    }
  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init(_ other: Float) {

    _value = Builtin.fptrunc_FPIEEE32_FPIEEE16(other._value)

  }
  
  @inlinable
  @inline(__always)
  public init?(exactly other: Float) {
    self.init(other)
    // Converting the infinity value is considered value preserving.
    // In other cases, check that we can round-trip and get the same value.
    // NaN always fails.
    if Float(self) != other {
      return nil
    }
  }
}

extension Float16 {
  @_transparent
  public static func + (lhs: Float16, rhs: Float16) -> Float16 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func - (lhs: Float16, rhs: Float16) -> Float16 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func * (lhs: Float16, rhs: Float16) -> Float16 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func / (lhs: Float16, rhs: Float16) -> Float16 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }
}

extension Float16: Strideable {
  @_transparent
  public func distance(to other: Float16) -> Float16 {
    return other - self
  }

  @_transparent
  public func advanced(by amount: Float16) -> Float16 {
    return self + amount
  }
}