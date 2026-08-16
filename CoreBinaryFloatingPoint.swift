// import uSwiftShims

// upgrade to this asap...
public protocol BinaryFloatingPoint: FloatingPoint, ExpressibleByFloatLiteral {
  associatedtype RawSignificand: UnsignedInteger
  associatedtype RawExponent: UnsignedInteger

  init(sign: FloatingPointSign,
       exponentBitPattern: RawExponent,
       significandBitPattern: RawSignificand)

  init(_ value: Float)
  // init<Source : BinaryFloatingPoint>(_ value: Source)
  // init?<Source : BinaryFloatingPoint>(exactly value: Source)
  static var exponentBitCount: Int { get }
  static var significandBitCount: Int { get }
  var exponentBitPattern: RawExponent { get }
  var significandBitPattern: RawSignificand { get }
  var binade: Self { get }
  var significandWidth: Int { get }

// we put in these two rather nasty looking hacks to replace the general _convert
// function from the original stdlib because that ended up always wanting type metadata
// that it didn't need or use, causing the executables to baloon out to a huge sizes
// ... once that issue with SIL optimisation is fixed, we can get rid of this hack
  static func _convertFloat(
    from source: Float
  ) -> (value: Self, exact: Bool)

  static func _convertFloat16(
    from source: Float16
  ) -> (value: Self, exact: Bool)
}



extension BinaryFloatingPoint {

  @inlinable @inline(__always)
  public static var radix: Int { return 2 }

  @inlinable
  public init(signOf: Self, magnitudeOf: Self) {
    self.init(sign: signOf.sign,
      exponentBitPattern: magnitudeOf.exponentBitPattern,
      significandBitPattern: magnitudeOf.significandBitPattern)
  }

// this is commented out because it always seems to end up demanding
// metadata and balooning the build to huge sizes
//   @inlinable
//   public // @testable
//   static func _convert<Source : BinaryFloatingPoint>(
//     from source: Source
//   ) -> (value: Self, exact: Bool) {


//     guard _fastPath(!source.isZero) else {
//       return (source.sign == .minus ? -0.0 : 0, true)
//     }


//     guard _fastPath(source.isFinite) else {
//       if source.isInfinite {
//         return (source.sign == .minus ? -.infinity : .infinity, true)
//       }
//       // IEEE 754 requires that any NaN payload be propagated, if possible.
//       let payload_ =
//         source.significandBitPattern &
//           ~(Source.nan.significandBitPattern |
//             Source.signalingNaN.significandBitPattern)
//       let mask =
//         Self.greatestFiniteMagnitude.significandBitPattern &
//           ~(Self.nan.significandBitPattern |
//             Self.signalingNaN.significandBitPattern)
//       let payload = Self.RawSignificand(truncatingIfNeeded: payload_) & mask
//       // Although .signalingNaN.exponentBitPattern == .nan.exponentBitPattern,
//       // we do not *need* to rely on this relation, and therefore we do not.
//       let value = source.isSignalingNaN
//         ? Self(
//           sign: source.sign,
//           exponentBitPattern: Self.signalingNaN.exponentBitPattern,
//           significandBitPattern: payload |
//             Self.signalingNaN.significandBitPattern)
//         : Self(
//           sign: source.sign,
//           exponentBitPattern: Self.nan.exponentBitPattern,
//           significandBitPattern: payload | Self.nan.significandBitPattern)
//       // We define exactness by equality after roundtripping; since NaN is never
//       // equal to itself, it can never be converted exactly.
//       return (value, false)
//     }

// // newest test... does adding this bit baloon the code?

//     let exponent = source.exponent
//     var exemplar = Self.leastNormalMagnitude
//     let exponentBitPattern: Self.RawExponent
//     let leadingBitIndex: Int
//     let shift: Int
//     let significandBitPattern: Self.RawSignificand

//     if exponent < exemplar.exponent {
//       // The floating-point result is either zero or subnormal.
//       exemplar = Self.leastNonzeroMagnitude
//       let minExponent = exemplar.exponent
//       if exponent + 1 < minExponent {
//         return (source.sign == .minus ? -0.0 : 0, false)
//       }
//       if _slowPath(exponent + 1 == minExponent) {
//         // Although the most significant bit (MSB) of a subnormal source
//         // significand is explicit, Swift BinaryFloatingPoint APIs actually
//         // omit any explicit MSB from the count represented in
//         // significandWidth. For instance:
//         //
//         //   Double.leastNonzeroMagnitude.significandWidth == 0
//         //
//         // Therefore, we do not need to adjust our work here for a subnormal
//         // source.
//         return source.significandWidth == 0
//           ? (source.sign == .minus ? -0.0 : 0, false)
//           : (source.sign == .minus ? -exemplar : exemplar, false)
//       }

//       exponentBitPattern = 0 as Self.RawExponent
//       leadingBitIndex = Int(Self.Exponent(exponent) - minExponent)
//       shift =
//         leadingBitIndex &-
//         (source.significandWidth &+
//           source.significandBitPattern.trailingZeroBitCount)
//       let leadingBit = source.isNormal
//         ? (1 as Self.RawSignificand) << leadingBitIndex
//         : 0
//       significandBitPattern = leadingBit | (shift >= 0
//         ? Self.RawSignificand(source.significandBitPattern) << shift
//         : Self.RawSignificand(source.significandBitPattern >> -shift))
//     } else {
//       // The floating-point result is either normal or infinite.
//       exemplar = Self.greatestFiniteMagnitude
//       if exponent > exemplar.exponent {
//         return (source.sign == .minus ? -.infinity : .infinity, false)
//       }

//       exponentBitPattern = exponent < 0
//         ? (1 as Self).exponentBitPattern - Self.RawExponent(-exponent)
//         : (1 as Self).exponentBitPattern + Self.RawExponent(exponent)
//       leadingBitIndex = exemplar.significandWidth
//       shift =
//         leadingBitIndex &-
//           (source.significandWidth &+
//             source.significandBitPattern.trailingZeroBitCount)
//       let sourceLeadingBit = source.isSubnormal
//         ? (1 as Source.RawSignificand) <<
//           (source.significandWidth &+
//             source.significandBitPattern.trailingZeroBitCount)
//         : 0
//       significandBitPattern = shift >= 0
//         ? Self.RawSignificand(
//           sourceLeadingBit ^ source.significandBitPattern) << shift
//         : Self.RawSignificand(
//           (sourceLeadingBit ^ source.significandBitPattern) >> -shift)
//     }

//     return (0, false)

//     let value = Self(
//       sign: source.sign,
//       exponentBitPattern: exponentBitPattern,
//       significandBitPattern: significandBitPattern)

//     if source.significandWidth <= leadingBitIndex {
//       return (value, true)
//     }



//     // // // We promise to round to the closest representation, and if two
//     // // // representable values are equally close, the value with more trailing
//     // // // zeros in its significand bit pattern. Therefore, we must take a look at
//     // // // the bits that we've just truncated.
//     // let ulp = (1 as Source.RawSignificand) << -shift
//     // let truncatedBits = source.significandBitPattern & (ulp - 1)
//     // if truncatedBits < ulp / 2 {
//     //   return (value, false)
//     // }



//     // let rounded = source.sign == .minus ? value.nextDown : value.nextUp
//     // guard _fastPath(
//     //   truncatedBits != ulp / 2 ||
//     //     exponentBitPattern.trailingZeroBitCount <
//     //       rounded.exponentBitPattern.trailingZeroBitCount) else {
//     //   return (value, false)
//     // }

//     // return (rounded, false)
//   }

  @inlinable
  public init(_ value: Float) {
    self = Self._convertFloat(from: value).value
  }

  @inlinable
  public init(_ value: Float16) {
    self = Self._convertFloat16(from: value).value
  }

  @inlinable
  public init?(exactly value: Float) {
    let (value_, exact) = Self._convertFloat(from: value)
    guard exact else { return nil }
    self = value_
  }

  @inlinable
  public init?(exactly value: Float16) {
    let (value_, exact) = Self._convertFloat16(from: value)
    guard exact else { return nil }
    self = value_
  }

  @inlinable
  public func isTotallyOrdered(belowOrEqualTo other: Self) -> Bool {
    // Quick return when possible.
    if self < other { return true }
    if other > self { return false }
    // Self and other are either equal or unordered.
    // Every negative-signed value (even NaN) is less than every positive-
    // signed value, so if the signs do not match, we simply return the
    // sign bit of self.
    if sign != other.sign { return sign == .minus }
    // Sign bits match; look at exponents.
    if exponentBitPattern > other.exponentBitPattern { return sign == .minus }
    if exponentBitPattern < other.exponentBitPattern { return sign == .plus }
    // Signs and exponents match, look at significands.
    if significandBitPattern > other.significandBitPattern {
      return sign == .minus
    }
    if significandBitPattern < other.significandBitPattern {
      return sign == .plus
    }
    //  Sign, exponent, and significand all match.
    return true
  }
}

extension BinaryFloatingPoint where Self.RawSignificand : FixedWidthInteger {
  
  @inlinable
  public // @testable
  static func _convert<Source : BinaryInteger>(
    from source: Source
  ) -> (value: Self, exact: Bool) {
    //  Useful constants:
    let exponentBias = (1 as Self).exponentBitPattern
    let significandMask = ((1 as RawSignificand) << Self.significandBitCount) &- 1
    //  Zero is really extra simple, and saves us from trying to normalize a
    //  value that cannot be normalized.
    if _fastPath(source == 0) { return (0, true) }
    //  We now have a non-zero value; convert it to a strictly positive value
    //  by taking the magnitude.
    let magnitude = source.magnitude
    var exponent = magnitude._binaryLogarithm()
    //  If the exponent would be larger than the largest representable
    //  exponent, the result is just an infinity of the appropriate sign.
    guard exponent <= Self.greatestFiniteMagnitude.exponent else {
      return (Source.isSigned && source < 0 ? -.infinity : .infinity, false)
    }
    //  If exponent <= significandBitCount, we don't need to round it to
    //  construct the significand; we just need to left-shift it into place;
    //  the result is always exact as we've accounted for exponent-too-large
    //  already and no rounding can occur.
    if exponent <= Self.significandBitCount {
      let shift = Self.significandBitCount &- exponent
      let significand = RawSignificand(magnitude) &<< shift
      let value = Self(
        sign: Source.isSigned && source < 0 ? .minus : .plus,
        exponentBitPattern: exponentBias + RawExponent(exponent),
        significandBitPattern: significand
      )
      return (value, true)
    }
    //  exponent > significandBitCount, so we need to do a rounding right
    //  shift, and adjust exponent if needed
    let shift = exponent &- Self.significandBitCount
    let halfway = (1 as Source.Magnitude) << (shift - 1)
    let mask = 2 * halfway - 1
    let fraction = magnitude & mask
    var significand = RawSignificand(truncatingIfNeeded: magnitude >> shift) & significandMask
    if fraction > halfway || (fraction == halfway && significand & 1 == 1) {
      var carry = false
      (significand, carry) = significand.addingReportingOverflow(1)
      if carry || significand > significandMask {
        exponent += 1
        guard exponent <= Self.greatestFiniteMagnitude.exponent else {
          return (Source.isSigned && source < 0 ? -.infinity : .infinity, false)
        }
      }
    }
    return (Self(
      sign: Source.isSigned && source < 0 ? .minus : .plus,
      exponentBitPattern: exponentBias + RawExponent(exponent),
      significandBitPattern: significand
    ), fraction == 0)
  }
  
  @inlinable
  public init<Source : BinaryInteger>(_ value: Source) {
    self = Self._convert(from: value).value
  }
  
  @inlinable
  public init?<Source : BinaryInteger>(exactly value: Source) {
    let (value_, exact) = Self._convert(from: value)
    guard exact else { return nil }
    self = value_
  }

  @inlinable
  public static func random<T: RandomNumberGenerator>(
    in range: Range<Self>,
    using generator: inout T
  ) -> Self {
    _precondition(
      !range.isEmpty
    )
    let delta = range.upperBound - range.lowerBound
    //  TODO: this still isn't quite right, because the computation of delta
    //  can overflow (e.g. if .upperBound = .maximumFiniteMagnitude and
    //  .lowerBound = -.upperBound); this should be re-written with an
    //  algorithm that handles that case correctly, but this precondition
    //  is an acceptable short-term fix.
    _precondition(
      delta.isFinite
    )
    let rand: Self.RawSignificand
    if Self.RawSignificand.bitWidth == Self.significandBitCount + 1 {
      rand = generator.next()
    } else {
      let significandCount = Self.significandBitCount + 1
      let maxSignificand: Self.RawSignificand = 1 << significandCount
      // Rather than use .next(upperBound:), which has to work with arbitrary
      // upper bounds, and therefore does extra work to avoid bias, we can take
      // a shortcut because we know that maxSignificand is a power of two.
      rand = generator.next() & (maxSignificand - 1)
    }
    let unitRandom = Self.init(rand) * (Self.ulpOfOne / 2)
    let randFloat = delta * unitRandom + range.lowerBound
    if randFloat == range.upperBound {
      return Self.random(in: range, using: &generator)
    }
    return randFloat
  }

  @inlinable
  public static func random(in range: Range<Self>) -> Self {
    var g = SystemRandomNumberGenerator()
    return Self.random(in: range, using: &g)
  }
  
  @inlinable
  public static func random<T: RandomNumberGenerator>(
    in range: ClosedRange<Self>,
    using generator: inout T
  ) -> Self {
    _precondition(
      !range.isEmpty
    )
    let delta = range.upperBound - range.lowerBound
    //  TODO: this still isn't quite right, because the computation of delta
    //  can overflow (e.g. if .upperBound = .maximumFiniteMagnitude and
    //  .lowerBound = -.upperBound); this should be re-written with an
    //  algorithm that handles that case correctly, but this precondition
    //  is an acceptable short-term fix.
    _precondition(
      delta.isFinite
    )
    let rand: Self.RawSignificand
    if Self.RawSignificand.bitWidth == Self.significandBitCount + 1 {
      rand = generator.next()
      let tmp: UInt8 = generator.next() & 1
      if rand == Self.RawSignificand.max && tmp == 1 {
        return range.upperBound
      }
    } else {
      let significandCount = Self.significandBitCount + 1
      let maxSignificand: Self.RawSignificand = 1 << significandCount
      rand = generator.next(upperBound: maxSignificand + 1)
      if rand == maxSignificand {
        return range.upperBound
      }
    }
    let unitRandom = Self.init(rand) * (Self.ulpOfOne / 2)
    let randFloat = delta * unitRandom + range.lowerBound
    return randFloat
  }
  
  @inlinable
  public static func random(in range: ClosedRange<Self>) -> Self {
    var g = SystemRandomNumberGenerator()
    return Self.random(in: range, using: &g)
  }
}