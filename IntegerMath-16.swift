// integer math functions for the Int and UInt types
// in this case, when those types are 16 bit
import uSwiftShims

extension Int {
  @_transparent
  public static func == (lhs: Int, rhs: Int) -> Bool {
    return Bool(Builtin.cmp_eq_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: Int, rhs: Int) -> Bool {
    return Bool(Builtin.cmp_slt_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func +=(lhs: inout Int, rhs: Int) {
    let (result, _) =
    Builtin.sadd_with_overflow_Int16(
      lhs._value, rhs._value, true._value)
    lhs = Int(result)
  }

  @_transparent
  public static func -=(lhs: inout Int, rhs: Int) {
    let (result, _) =
    Builtin.ssub_with_overflow_Int16(
      lhs._value, rhs._value, true._value)
    lhs = Int(result)
  }

  @_transparent
  public static func *=(lhs: inout Int, rhs: Int) {
    let (result, _) =
    Builtin.smul_with_overflow_Int16(
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
      (Builtin.sdiv_Int16(lhs._value, rhs._value),
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
      Builtin.srem_Int16(lhs._value, rhs._value),
      false._value)

    lhs = Int(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout Int, rhs: Int) {
    lhs = Int(Builtin.and_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout Int, rhs: Int) {
    lhs = Int(Builtin.or_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout Int, rhs: Int) {
    lhs = Int(Builtin.xor_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout Int, rhs: Int) {
    let rhs_ = rhs & 15
    lhs = Int(
      Builtin.ashr_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout Int, rhs: Int) {
    let rhs_ = rhs & 15
    lhs = Int(
      Builtin.shl_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: Int
  ) -> (partialValue: Int, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.sadd_with_overflow_Int16(
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
      Builtin.ssub_with_overflow_Int16(
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
      Builtin.smul_with_overflow_Int16(
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
      Builtin.sdiv_Int16(self._value, other._value),
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
      Builtin.srem_Int16(self._value, other._value),
      false._value)

    return (
      partialValue: Int(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(Builtin.int_ctlz_Int16(self._value, false._value))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(Builtin.int_cttz_Int16(self._value, Bool(false)._value))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(Builtin.int_ctpop_Int16(self._value))
  }
}

@_transparent
public func _assumeNonNegative(_ x: Int) -> Int {
  _internalInvariant(x >= (0 as Int))
  return Int(Builtin.assumeNonNegative_Int16(x._value))
}

extension UInt {
  @_transparent
  public static func == (lhs: UInt, rhs: UInt) -> Bool {
    return Bool(Builtin.cmp_eq_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: UInt, rhs: UInt) -> Bool {
    return Bool(Builtin.cmp_ult_Int16(lhs._value, rhs._value))
  }

  // Builtin.condfail(overflow) [EXCISED]
  @_transparent
  public static func +=(lhs: inout UInt, rhs: UInt) {
    let (result, _) =
    Builtin.uadd_with_overflow_Int16(
      lhs._value, rhs._value, true._value)

    lhs = UInt(result)
  }

  @_transparent
  public static func -=(lhs: inout UInt, rhs: UInt) {
    let (result, _) =
    Builtin.usub_with_overflow_Int16(
      lhs._value, rhs._value, true._value)
    lhs = UInt(result)
  }

  @_transparent
  public static func *=(lhs: inout UInt, rhs: UInt) {
    let (result, _) =
      Builtin.umul_with_overflow_Int16(
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
      (Builtin.udiv_Int16(lhs._value, rhs._value),
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
      Builtin.urem_Int16(lhs._value, rhs._value),
      false._value)
    lhs = UInt(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout UInt, rhs: UInt) {
    lhs = UInt(Builtin.and_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout UInt, rhs: UInt) {
    lhs = UInt(Builtin.or_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout UInt, rhs: UInt) {
    lhs = UInt(Builtin.xor_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout UInt, rhs: UInt) {
    let rhs_ = rhs & 15
    lhs = UInt(
      Builtin.lshr_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout UInt, rhs: UInt) {
    let rhs_ = rhs & 15
    lhs = UInt(
      Builtin.shl_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: UInt
  ) -> (partialValue: UInt, overflow: Bool) {

    let (newStorage, overflow) =
    Builtin.uadd_with_overflow_Int16(
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
      Builtin.usub_with_overflow_Int16(
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
      Builtin.umul_with_overflow_Int16(
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
      Builtin.udiv_Int16(self._value, other._value),
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
      Builtin.urem_Int16(self._value, other._value),
      false._value)

    return (
      partialValue: UInt(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(Builtin.int_ctlz_Int16(self._value, false._value))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(Builtin.int_cttz_Int16(self._value, Bool(false)._value))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(Builtin.int_ctpop_Int16(self._value))
  }
}

extension Int16 {
}

// for 16 bit platforms where final type is 8 bit or 16 bit, convert all floats to
// 16 bit int then convert to the appropriate int type
extension FixedWidthInteger {
  // I was dying of boredom with days trying to get this rubbish working
  // gave up and used libc hack

  // NOTE: the hack didn't work outside of the AVR platform,
  // but for now, that's the only 16 bit platform Microswift supports
  // so we will review if other platforms get added later
  // (maybe add these workaround functions into their custom runtime too, for example, same as AVR)
  // In the meantime, we'll limit this hack to AVR. For the 32 bit ARM Cortex M0, RISC-V ISA and Xtensa
  // architectures we plan to support, we'll restore the original swift standard library code, which has
  // proper conversion from IEEE 754 to integer
  // (it was not optimising correctly on AVR before Embedded Swift was invented, it's possible that the original
  //  swift standard library float to int coce will work properly on all platforms including AVR now that embedded
  //  swift exists but I can't be bothered to find out right now, the performance optimisation doesn't seem worth
  //  the effort... it works as is on AVR)
  @inlinable
  @inline(__always)
  public init?(safe source: Float) {
    guard source.isFinite, !source.isNaN else {
      return nil
    }

    guard Self.isSigned || source >= 0 else {
      return nil
    }

    self = Self(float_to_int16(source))
  }

  @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
  @inlinable
  @inline(__always)
  public init(_ source: Float) {
    guard source.isFinite, !source.isNaN else {
      self = 0
      return
    }

    self = Self(float_to_int16(source))
  }
}

// special case 32 bit to ensure no incorrect truncation for these types
extension UInt32 {
  @inlinable
  @inline(__always)
  public init?(safe source: Float) {
    guard source.isFinite, !source.isNaN else {
      return nil
    }

    guard Self.isSigned || source >= 0 else {
      return nil
    }

    self = Self(float_to_int32(source))
  }

  @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
  @inlinable
  @inline(__always)
  public init(_ source: Float) {
    guard source.isFinite, !source.isNaN else {
      self = 0
      return
    }

    self = Self(float_to_int32(source))
  }
}

extension Int32 {
  @inlinable
  @inline(__always)
  public init?(safe source: Float) {
    guard source.isFinite, !source.isNaN else {
      return nil
    }

    guard Self.isSigned || source >= 0 else {
      return nil
    }

    self = Self(float_to_int32(source))
  }

  @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
  @inlinable
  @inline(__always)
  public init(_ source: Float) {
    guard source.isFinite, !source.isNaN else {
      self = 0
      return
    }

    self = Self(float_to_int32(source))
  }
}

// special case 64 bit to ensure no incorrect truncation for these types
extension UInt64 {
  @inlinable
  @inline(__always)
  public init?(safe source: Float) {
    guard source.isFinite, !source.isNaN else {
      return nil
    }

    guard Self.isSigned || source >= 0 else {
      return nil
    }

    self = Self(float_to_int64(source))
  }

  @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
  @inlinable
  @inline(__always)
  public init(_ source: Float) {
    guard source.isFinite, !source.isNaN else {
      self = 0
      return
    }

    self = Self(float_to_int64(source))
  }
}

extension Int64 {
  @inlinable
  @inline(__always)
  public init?(safe source: Float) {
    guard source.isFinite, !source.isNaN else {
      return nil
    }

    guard Self.isSigned || source >= 0 else {
      return nil
    }

    self = Self(float_to_int64(source))
  }

  @available(*, deprecated, message: "warning, this initialiser will return 0 when it cannot cast! Use safe: instead")
  @inlinable
  @inline(__always)
  public init(_ source: Float) {
    guard source.isFinite, !source.isNaN else {
      self = 0
      return
    }

    self = Self(float_to_int64(source))
  }
}