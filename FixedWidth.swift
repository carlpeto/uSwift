// fixed width integers implement extra operations such as bitWidth, a static function
// and have concrete implementations in memory
// at this time all integer types are fixed width


// I'm not sure why this is needed but Slava says it is, and compiling borks otherwise!
public protocol _FakeIntegerProtocol {}

public protocol FixedWidthInteger : BinaryInteger, _FakeIntegerProtocol
where Magnitude : FixedWidthInteger & UnsignedInteger,
      Stride : FixedWidthInteger & SignedInteger
{
  static var bitWidth: Int { get }
  static var max: Self { get }
  static var min: Self { get }

  init(_truncatingBits bits: UInt)

  var nonzeroBitCount: Int { get }
  var leadingZeroBitCount: Int { get }

 func addingReportingOverflow(
   _ rhs: Self
 ) -> (partialValue: Self, overflow: Bool)

 func subtractingReportingOverflow(
   _ rhs: Self
 ) -> (partialValue: Self, overflow: Bool)

  func multipliedReportingOverflow(
    by rhs: Self
  ) -> (partialValue: Self, overflow: Bool)

  func dividedReportingOverflow(
    by rhs: Self
  ) -> (partialValue: Self, overflow: Bool)

  func remainderReportingOverflow(
    dividingBy rhs: Self
  ) -> (partialValue: Self, overflow: Bool)

  func multipliedFullWidth(by other: Self) -> (high: Self, low: Self.Magnitude)

  func dividingFullWidth(_ dividend: (high: Self, low: Self.Magnitude))
    -> (quotient: Self, remainder: Self)

  init(bigEndian value: Self)
  init(littleEndian value: Self)
  var bigEndian: Self { get }
  var littleEndian: Self { get }
  var byteSwapped: Self { get }

  static func &>>(lhs: Self, rhs: Self) -> Self
  static func &>>=(lhs: inout Self, rhs: Self)
  static func &<<(lhs: Self, rhs: Self) -> Self
  static func &<<=(lhs: inout Self, rhs: Self)
}

extension FixedWidthInteger {
  @inlinable
  public var bitWidth: Int { return Self.bitWidth }

  @inlinable
  public func _binaryLogarithm() -> Int {
    // _precondition(self > (0 as Self))
    return Self.bitWidth &- (leadingZeroBitCount &+ 1)
  }

  // hard coded to little endian for AVR platforms
  @inlinable
  public init(littleEndian value: Self) {
    self = value
  }

  @inlinable
  public init(bigEndian value: Self) {
    self = value.byteSwapped

  }

  @inlinable
  public var littleEndian: Self {
    return self
  }

  @inlinable
  public var bigEndian: Self {
    return byteSwapped
  }

// original implementation is way too heavyweight...
  //   @_transparent
  // public var _lowWord: UInt {
  //   var it = words.makeIterator()
  //   return it.next() ?? 0
  // }

  // @inlinable // FIXME(sil-serialize-all)
  // @inline(__always)
  // public init<T : BinaryInteger>(truncatingIfNeeded source: T) {
  //   // if Self.bitWidth == 8, T.bitWidth == 8 {
  //   //   self = Self(bitPattern: source)
  //   //   return
  //   // }

  //   if Self.bitWidth <= Int.bitWidth {
  //     self = Self(_truncatingBits: source._lowWord)
  //   }
  //   else {
  //     // not implemented
  //     self = 0

  //     // let neg = source < (0 as T)
  //     // var result: Self = neg ? ~0 : 0
  //     // var shift: Self = 0
  //     // let width = Self(_truncatingBits: Self.bitWidth._lowWord)
  //     // for word in source.words {
  //     //   guard shift < width else { break }
  //     //   // Masking shift is OK here because we have already ensured
  //     //   // that shift < Self.bitWidth. Not masking results in
  //     //   // infinite recursion.
  //     //   result ^= Self(_truncatingBits: neg ? ~word : word) &<< shift
  //     //   shift += Self(_truncatingBits: Int.bitWidth._lowWord)
  //     // }
  //     // self = result
  //   }
  // }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init<T : BinaryInteger>(truncatingIfNeeded source: T) {
    if Self.bitWidth <= Int.bitWidth {
      self = Self(_truncatingBits: source._lowWord)
    }
    else {
      let neg = source < (0 as T)
      var result: Self = neg ? ~0 : 0
      var shift: Self = 0
      let width = Self(_truncatingBits: Self.bitWidth._lowWord)
      for word in source.words {
        guard shift < width else { break }
        // Masking shift is OK here because we have already ensured
        // that shift < Self.bitWidth. Not masking results in
        // infinite recursion.
        result ^= Self(_truncatingBits: neg ? ~word : word) &<< shift
        shift += Self(_truncatingBits: Int.bitWidth._lowWord)
      }
      self = result
    }
  }

  @_transparent
  public // transparent
  static var _highBitIndex: Self {
    return Self.init(_truncatingBits: UInt(Self.bitWidth._value) &- 1)
  }
}

extension FixedWidthInteger {
  @_transparent
  public static func &+ (lhs: Self, rhs: Self) -> Self {
    return lhs.addingReportingOverflow(rhs).partialValue
  }

  @_transparent
  public static func &+= (lhs: inout Self, rhs: Self) {
    lhs = lhs &+ rhs
  }

  @_transparent
  public static func &- (lhs: Self, rhs: Self) -> Self {
    return lhs.subtractingReportingOverflow(rhs).partialValue
  }

  @_transparent
  public static func &-= (lhs: inout Self, rhs: Self) {
    lhs = lhs &- rhs
  }

  @_transparent
  public static func &* (lhs: Self, rhs: Self) -> Self {
    return lhs.multipliedReportingOverflow(by: rhs).partialValue
  }

  @_transparent
  public static func &*= (lhs: inout Self, rhs: Self) {
    lhs = lhs &* rhs
  }

  // shifts

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func &>> (lhs: Self, rhs: Self) -> Self {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func &>> <
    Other : BinaryInteger
  >(lhs: Self, rhs: Other) -> Self {
    return lhs &>> Self(truncatingIfNeeded: rhs)
  }

  // @_semantics("optimize.sil.specialize.generic.partial.never")
  // @_transparent
  // public static func &>>= <
  //   Other : BinaryInteger
  // >(lhs: inout Self, rhs: Other) {
  //   lhs = lhs &>> rhs
  // }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func &<< (lhs: Self, rhs: Self) -> Self {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func &<< <
    Other : BinaryInteger
  >(lhs: Self, rhs: Other) -> Self {
    return lhs &<< Self(truncatingIfNeeded: rhs)
  }

  // @_semantics("optimize.sil.specialize.generic.partial.never")
  // @_transparent
  // public static func &<<= <
  //   Other : BinaryInteger
  // >(lhs: inout Self, rhs: Other) {
  //   lhs = lhs &<< rhs
  // }
}

extension FixedWidthInteger {
  @inlinable
  public static func _random<R: RandomNumberGenerator>(
    using generator: inout R
  ) -> Self {
    if bitWidth <= UInt32.bitWidth {
      return Self(truncatingIfNeeded: generator.next() as UInt32)
    }

    let (quotient, remainder) = bitWidth.quotientAndRemainder(
      dividingBy: UInt32.bitWidth
    )
    var tmp: Self = 0
    for i in 0 ..< quotient + remainder.signum() {
      let next: UInt32 = generator.next()
      tmp += Self(truncatingIfNeeded: next) &<< (UInt32.bitWidth * i)
    }
    return tmp
  }
}

// extension FixedWidthInteger {
//   @inlinable
//   public // @testable
//   static func _convert(from source: Float) -> (value: Self?, exact: Bool) {

//     guard _fastPath(!source.isZero) else { return (0, true) }
//     guard _fastPath(source.isFinite) else { return (nil, false) }
//     guard Self.isSigned || source > -1 else { return (nil, false) }
//     let exponent = source.exponent
//     if _slowPath(Self.bitWidth <= exponent) { return (nil, false) }
//     let minBitWidth = source.significandWidth
//     let isExact = (minBitWidth <= exponent)
//     let bitPattern = source.significandBitPattern
//     // `RawSignificand.bitWidth` is not available if `RawSignificand` does not
//     // conform to `FixedWidthInteger`; we can compute this value as follows if
//     // `source` is finite:
//     let bitWidth = minBitWidth &+ bitPattern.trailingZeroBitCount
//     let shift = exponent - Float.Exponent(bitWidth)
//     // Use `Self.Magnitude` to prevent sign extension if `shift < 0`.
//     let shiftedBitPattern = Self.Magnitude.bitWidth > bitWidth
//       ? Self.Magnitude(truncatingIfNeeded: bitPattern) << shift
//       : Self.Magnitude(truncatingIfNeeded: bitPattern << shift)
//     if _slowPath(Self.isSigned && Self.bitWidth &- 1 == exponent) {
//       return source < 0 && shiftedBitPattern == 0
//         ? (Self.min, isExact)
//         : (nil, false)
//     }
//     let magnitude = ((1 as Self.Magnitude) << exponent) | shiftedBitPattern
//     return (
//       Self.isSigned && source < 0 ? 0 &- Self(magnitude) : Self(magnitude),
//       isExact)
//   }

//   @inlinable
//   @inline(__always)
//   public init(_ source: Float) {
//     guard let value = Self._convert(from: source).value else {
//       self = 0
//       return
//     }
//     self = value
//   }

//   @inlinable
//   public init?(exactly source: Float) {
//     let (temporary, exact) = Self._convert(from: source)
//     guard exact, let value = temporary else {
//       return nil
//     }
//     self = value
//   }
// }

extension FixedWidthInteger {
  @_transparent
  public static prefix func ~ (x: Self) -> Self {
    return 0 &- x &- 1
  }

//===----------------------------------------------------------------------===//
//=== "Smart right shift", supporting overshifts and negative shifts ------===//
//===----------------------------------------------------------------------===//

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func >> <
    Other : BinaryInteger
  >(lhs: Self, rhs: Other) -> Self {
    var lhs = lhs
    _nonMaskingRightShiftGeneric(&lhs, rhs)
    return lhs
  }

  @_transparent
  @_semantics("optimize.sil.specialize.generic.partial.never")
  public static func >>= <
    Other : BinaryInteger
  >(lhs: inout Self, rhs: Other) {
    _nonMaskingRightShiftGeneric(&lhs, rhs)
  }

  @_transparent
  public static func _nonMaskingRightShiftGeneric <
    Other : BinaryInteger
  >(_ lhs: inout Self, _ rhs: Other) {
    let shift = rhs < -Self.bitWidth ? -Self.bitWidth
                : rhs > Self.bitWidth ? Self.bitWidth
                : Int(rhs)
    lhs = _nonMaskingRightShift(lhs, shift)
  }

  @_transparent
  public static func _nonMaskingRightShift(_ lhs: Self, _ rhs: Int) -> Self {
    let overshiftR = Self.isSigned ? lhs &>> (Self.bitWidth - 1) : 0
    let overshiftL: Self = 0
    if _fastPath(rhs >= 0) {
      if _fastPath(rhs < Self.bitWidth) {
        return lhs &>> Self(truncatingIfNeeded: rhs)
      }
      return overshiftR
    }

    if _slowPath(rhs <= -Self.bitWidth) {
      return overshiftL
    }
    return lhs &<< -rhs
  }

//===----------------------------------------------------------------------===//
//=== "Smart left shift", supporting overshifts and negative shifts -------===//
//===----------------------------------------------------------------------===//

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func << <
    Other : BinaryInteger
  >(lhs: Self, rhs: Other) -> Self {
    var lhs = lhs
    _nonMaskingLeftShiftGeneric(&lhs, rhs)
    return lhs
  }

  @_transparent
  @_semantics("optimize.sil.specialize.generic.partial.never")
  public static func <<= <
    Other : BinaryInteger
  >(lhs: inout Self, rhs: Other) {
    _nonMaskingLeftShiftGeneric(&lhs, rhs)
  }

  @_transparent
  public static func _nonMaskingLeftShiftGeneric <
    Other : BinaryInteger
  >(_ lhs: inout Self, _ rhs: Other) {
    let shift = rhs < -Self.bitWidth ? -Self.bitWidth
                : rhs > Self.bitWidth ? Self.bitWidth
                : Int(rhs)
    lhs = _nonMaskingLeftShift(lhs, shift)
  }

  @_transparent
  public static func _nonMaskingLeftShift(_ lhs: Self, _ rhs: Int) -> Self {
    let overshiftR = Self.isSigned ? lhs &>> (Self.bitWidth - 1) : 0
    let overshiftL: Self = 0
    if _fastPath(rhs >= 0) {
      if _fastPath(rhs < Self.bitWidth) {
        return lhs &<< Self(truncatingIfNeeded: rhs)
      }
      return overshiftL
    }

    if _slowPath(rhs <= -Self.bitWidth) {
      return overshiftR
    }
    return lhs &>> -rhs
  }

  @inlinable
  @_semantics("optimize.sil.specialize.generic.partial.never")
  public // @testable
  static func _convert<Source : BinaryFloatingPoint>(
    from source: Source
  ) -> (value: Self?, exact: Bool) {
    guard _fastPath(!source.isZero) else { return (0, true) }
    guard _fastPath(source.isFinite) else { return (nil, false) }
    guard Self.isSigned || source > -1 else { return (nil, false) }
    let exponent = source.exponent
    if _slowPath(Self.bitWidth <= exponent) { return (nil, false) }
    let minBitWidth = source.significandWidth
    let isExact = (minBitWidth <= exponent)
    let bitPattern = source.significandBitPattern
    // `RawSignificand.bitWidth` is not available if `RawSignificand` does not
    // conform to `FixedWidthInteger`; we can compute this value as follows if
    // `source` is finite:
    let bitWidth = minBitWidth &+ bitPattern.trailingZeroBitCount
    let shift = exponent - Source.Exponent(bitWidth)
    // Use `Self.Magnitude` to prevent sign extension if `shift < 0`.
    let shiftedBitPattern = Self.Magnitude.bitWidth > bitWidth
      ? Self.Magnitude(truncatingIfNeeded: bitPattern) << shift
      : Self.Magnitude(truncatingIfNeeded: bitPattern << shift)
    if _slowPath(Self.isSigned && Self.bitWidth &- 1 == exponent) {
      return source < 0 && shiftedBitPattern == 0
        ? (Self.min, isExact)
        : (nil, false)
    }
    let magnitude = ((1 as Self.Magnitude) << exponent) | shiftedBitPattern
    return (
      Self.isSigned && source < 0 ? 0 &- Self(magnitude) : Self(magnitude),
      isExact)
  }

  @inlinable
  @_semantics("optimize.sil.specialize.generic.partial.never")
  @inline(__always)
  public init<T : BinaryFloatingPoint>(_ source: T) {
    guard let value = Self._convert(from: source).value else {
      self = 0
      // fatalError("""
      //   \(T.self) value cannot be converted to \(Self.self) because it is \
      //   outside the representable range
      //   """)
      return
    }
    self = value
  }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @inlinable
  public init?<T : BinaryFloatingPoint>(exactly source: T) {
    let (temporary, exact) = Self._convert(from: source)
    guard exact, let value = temporary else {
      return nil
    }
    self = value
  }

  @inlinable
  @_semantics("optimize.sil.specialize.generic.partial.never")
  public init<Other : BinaryInteger>(clamping source: Other) {
    if _slowPath(source < Self.min) {
      self = Self.min
    }
    else if _slowPath(source > Self.max) {
      self = Self.max
    }
    else { self = Self(truncatingIfNeeded: source) }
  }
}
