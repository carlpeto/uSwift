// integer math functions for the Int and UInt types
// in this case, when those types are 16 bit

extension Int {
  @_transparent
  public static func == (lhs: Int, rhs: Int) -> Bool {
    return Bool(Builtin.cmp_eq_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: Int, rhs: Int) -> Bool {
    return Bool(Builtin.cmp_slt_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func +=(lhs: inout Int, rhs: Int) {
    let (result, _) =
    Builtin.sadd_with_overflow_Int32(
      lhs._value, rhs._value, true._value)
    lhs = Int(result)
  }

  @_transparent
  public static func -=(lhs: inout Int, rhs: Int) {
    let (result, _) =
    Builtin.ssub_with_overflow_Int32(
      lhs._value, rhs._value, true._value)
    lhs = Int(result)
  }

  @_transparent
  public static func *=(lhs: inout Int, rhs: Int) {
    let (result, _) =
    Builtin.smul_with_overflow_Int32(
      lhs._value, rhs._value, true._value)
    lhs = Int(result)
  }

  @_transparent
  public static func /=(lhs: inout Int, rhs: Int) {
    if _slowPath(rhs == (0 as Int)) {
      _precondition(false)
      return
    }

    if _slowPath(
      lhs == Int.min && rhs == (-1 as Int)
    ) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.sdiv_Int32(lhs._value, rhs._value),
      false._value)

    lhs = Int(result)
  }

  @_transparent
  public static func %=(lhs: inout Int, rhs: Int) {
    if _slowPath(rhs == (0 as Int)) {
      _precondition(false)
      return
    }

    if _slowPath(lhs == Int.min && rhs == (-1 as Int)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.srem_Int32(lhs._value, rhs._value),
      false._value)

    lhs = Int(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout Int, rhs: Int) {
    lhs = Int(Builtin.and_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout Int, rhs: Int) {
    lhs = Int(Builtin.or_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout Int, rhs: Int) {
    lhs = Int(Builtin.xor_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout Int, rhs: Int) {
    let rhs_ = rhs & 31
    lhs = Int(
      Builtin.ashr_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout Int, rhs: Int) {
    let rhs_ = rhs & 31
    lhs = Int(
      Builtin.shl_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: Int
  ) -> (partialValue: Int, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.sadd_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: Int(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: Int
  ) -> (partialValue: Int, overflow: Bool) {

        let (newStorage, overflow) =
      Builtin.ssub_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: Int(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: Int
  ) -> (partialValue: Int, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.smul_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: Int(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: Int
  ) -> (partialValue: Int, overflow: Bool) {
    if _slowPath(other == (0 as Int)) {
      return (partialValue: self, overflow: true)
    }
    if _slowPath(self == Int.min && other == (-1 as Int)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.sdiv_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: Int(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: Int
  ) -> (partialValue: Int, overflow: Bool) {
    if _slowPath(other == (0 as Int)) {
      return (partialValue: self, overflow: true)
    }
    if _slowPath(self == Int.min && other == (-1 as Int)) {
      return (partialValue: 0, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.srem_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: Int(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(Builtin.int_ctlz_Int32(self._value, false._value))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(Builtin.int_cttz_Int32(self._value, Bool(false)._value))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(Builtin.int_ctpop_Int32(self._value))
  }
}

@_transparent
public func _assumeNonNegative(_ x: Int) -> Int {
  _internalInvariant(x >= (0 as Int))
  return Int(Builtin.assumeNonNegative_Int32(x._value))
}

extension UInt {
  @_transparent
  public static func == (lhs: UInt, rhs: UInt) -> Bool {
    return Bool(Builtin.cmp_eq_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: UInt, rhs: UInt) -> Bool {
    return Bool(Builtin.cmp_ult_Int32(lhs._value, rhs._value))
  }

  // Builtin.condfail(overflow) [EXCISED]
  @_transparent
  public static func +=(lhs: inout UInt, rhs: UInt) {
    let (result, _) =
    Builtin.uadd_with_overflow_Int32(
      lhs._value, rhs._value, true._value)

    lhs = UInt(result)
  }

  @_transparent
  public static func -=(lhs: inout UInt, rhs: UInt) {
    let (result, _) =
    Builtin.usub_with_overflow_Int32(
      lhs._value, rhs._value, true._value)
    lhs = UInt(result)
  }

  @_transparent
  public static func *=(lhs: inout UInt, rhs: UInt) {
    let (result, _) =
      Builtin.umul_with_overflow_Int32(
        lhs._value, rhs._value, true._value)
    lhs = UInt(result)
  }

  @_transparent
  public static func /=(lhs: inout UInt, rhs: UInt) {
    if _slowPath(rhs == (0 as UInt)) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.udiv_Int32(lhs._value, rhs._value),
      false._value)
    lhs = UInt(result)
  }

  @_transparent
  public static func %=(lhs: inout UInt, rhs: UInt) {

    if _slowPath(rhs == (0 as UInt)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.urem_Int32(lhs._value, rhs._value),
      false._value)
    lhs = UInt(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout UInt, rhs: UInt) {
    lhs = UInt(Builtin.and_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout UInt, rhs: UInt) {
    lhs = UInt(Builtin.or_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout UInt, rhs: UInt) {
    lhs = UInt(Builtin.xor_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout UInt, rhs: UInt) {
    let rhs_ = rhs & 31
    lhs = UInt(
      Builtin.lshr_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout UInt, rhs: UInt) {
    let rhs_ = rhs & 31
    lhs = UInt(
      Builtin.shl_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: UInt
  ) -> (partialValue: UInt, overflow: Bool) {

    let (newStorage, overflow) =
    Builtin.uadd_with_overflow_Int32(
      self._value, other._value, false._value)

    return (
      partialValue: UInt(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: UInt
  ) -> (partialValue: UInt, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.usub_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: UInt(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: UInt
  ) -> (partialValue: UInt, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.umul_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: UInt(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: UInt
  ) -> (partialValue: UInt, overflow: Bool) {
    if _slowPath(other == (0 as UInt)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.udiv_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: UInt(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: UInt
  ) -> (partialValue: UInt, overflow: Bool) {
    if _slowPath(other == (0 as UInt)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.urem_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: UInt(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(Builtin.int_ctlz_Int32(self._value, false._value))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(Builtin.int_cttz_Int32(self._value, Bool(false)._value))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(Builtin.int_ctpop_Int32(self._value))
  }
}

// for 32 bit platforms there's no point in making sure short integers are not converted to 32 bit
// because all ints will be in a single register (or stack slot) anyway, so convert all floats to
// 32 bit int then convert to the appropriate int type
extension FixedWidthInteger {
  // I was dying of boredom with days trying to get this rubbish working
  // gave up and used libc hack

  // UPDATE: the hack was removed here because it was breaking on our planned 32-bit platforms...
  // the runtime workaround functions I used from AVR libc are not available. So I reverted to the
  // standard Swift standard library code for float to int conversion. Hopefully it should compile and
  // work now that we have embedded swift mode.

  // @inlinable
  // @inline(__always)
  // public init?(safe source: Float) {
  //   guard source.isFinite, !source.isNaN else {
  //     return nil
  //   }

  //   guard Self.isSigned || source >= 0 else {
  //     return nil
  //   }

  //   self = Self(float_to_int32(source))
  // }

  // @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
  // @inlinable
  // @inline(__always)
  // public init(_ source: Float) {
  //   guard source.isFinite, !source.isNaN else {
  //     self = 0
  //     return
  //   }

  //   self = Self(float_to_int32(source))
  // }

  // @inlinable
  // @_semantics("optimize.sil.specialize.generic.partial.never")
  // public // @testable
  // static func _convert<Source: BinaryFloatingPoint>(
  //   from source: Source
  // ) -> (value: Self?, exact: Bool) {
  //   guard _fastPath(!source.isZero) else { return (0, true) }
  //   guard _fastPath(source.isFinite) else { return (nil, false) }
  //   guard Self.isSigned || source > -1 else { return (nil, false) }
  //   let exponent = source.exponent
  //   if _slowPath(Self.bitWidth <= exponent) { return (nil, false) }
  //   let minBitWidth = source.significandWidth
  //   let isExact = (minBitWidth <= exponent)
  //   let bitPattern = source.significandBitPattern
  //   // Determine the actual number of fractional significand bits.
  //   // `Source.significandBitCount` would not reflect the actual number of
  //   // fractional significand bits if `Source` is not a fixed-width floating-point
  //   // type; we can compute this value as follows if `source` is finite:
  //   let bitWidth = minBitWidth &+ bitPattern.trailingZeroBitCount
  //   let shift = exponent - Source.Exponent(bitWidth)
  //   // Use `Self.Magnitude` to prevent sign extension if `shift < 0`.
  //   let shiftedBitPattern = Self.Magnitude.bitWidth > bitWidth
  //     ? Self.Magnitude(truncatingIfNeeded: bitPattern) << shift
  //     : Self.Magnitude(truncatingIfNeeded: bitPattern << shift)
  //   if _slowPath(Self.isSigned && Self.bitWidth &- 1 == exponent) {
  //     return source < 0 && shiftedBitPattern == 0
  //       ? (Self.min, isExact)
  //       : (nil, false)
  //   }
  //   let magnitude = ((1 as Self.Magnitude) << exponent) | shiftedBitPattern
  //   return (
  //     Self.isSigned && source < 0 ? 0 &- Self(magnitude) : Self(magnitude),
  //     isExact)
  // }

  // @inlinable
  // @_semantics("optimize.sil.specialize.generic.partial.never")
  // @inline(__always)
  // public init<T: BinaryFloatingPoint>(_ source: T) {
  //   guard let value = Self._convert(from: source).value else {
  //     #if !$Embedded
  //     fatalError("""
  //       \(T.self) value cannot be converted to \(Self.self) because it is \
  //       outside the representable range
  //       """)
  //     #else
  //     fatalError("value not representable")
  //     #endif
  //   }
  //   self = value
  // }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @inlinable
  public init?<T: BinaryFloatingPoint>(safe source: T) {
    let (temporary, exact) = Self._convert(from: source)
    guard exact, let value = temporary else {
      return nil
    }
    self = value
  }
}

// special case 64 bit to ensure no incorrect truncation for these types
// extension UInt64 {
//   @inlinable
//   @inline(__always)
//   public init?(safe source: Float) {
//     guard source.isFinite, !source.isNaN else {
//       return nil
//     }

//     guard Self.isSigned || source >= 0 else {
//       return nil
//     }

//     self = Self(float_to_int64(source))
//   }

//   @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
//   @inlinable
//   @inline(__always)
//   public init(_ source: Float) {
//     guard source.isFinite, !source.isNaN else {
//       self = 0
//       return
//     }

//     self = Self(float_to_int64(source))
//   }
// }

// extension Int64 {
//   @inlinable
//   @inline(__always)
//   public init?(safe source: Float) {
//     guard source.isFinite, !source.isNaN else {
//       return nil
//     }

//     guard Self.isSigned || source >= 0 else {
//       return nil
//     }

//     self = Self(float_to_int64(source))
//   }

//   @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
//   @inlinable
//   @inline(__always)
//   public init(_ source: Float) {
//     guard source.isFinite, !source.isNaN else {
//       self = 0
//       return
//     }

//     self = Self(float_to_int64(source))
//   }
// }
