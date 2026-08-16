import uSwiftShims

extension FixedWidthInteger {
  @available(*, unavailable, message: "exactly: is not used on this platform, use safe:")
  public init?(exactly source: Float) {
    return nil
  }
}

// these math functions are generalised and don't depend on the bit size of Int
extension Int {
  @_transparent
  public static func +(lhs: Int, rhs: Int) -> Int {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: Int, rhs: Int) -> Int {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: Int, rhs: Int) -> Int {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: Int, rhs: Int) -> Int {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: Int, rhs: Int) -> Int {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }
}

// these math functions are generalised and don't depend on the bit size of UInt
extension UInt {
  @_transparent
  public static func +(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func &(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: UInt, rhs: UInt) -> UInt {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: UInt, rhs: UInt) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: UInt, rhs: UInt) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: UInt, rhs: UInt) -> Bool {
    return rhs < lhs
  }
}

// most traps are suppressed in uSwift as hanging is rarely useful
// this might introduce potential security holes in some cases


@_transparent
public func _assumeNonNegative(_ x: Int64) -> Int64 {
  _internalInvariant(x >= (0 as Int64))
  return Int64(Builtin.assumeNonNegative_Int64(x._value))
}

@_transparent
public func _assumeNonNegative(_ x: Int32) -> Int32 {
  _internalInvariant(x >= (0 as Int32))
  return Int32(Builtin.assumeNonNegative_Int32(x._value))
}

@_transparent
public func _assumeNonNegative(_ x: Int16) -> Int16 {
  _internalInvariant(x >= (0 as Int16))
  return Int16(Builtin.assumeNonNegative_Int16(x._value))
}

@_transparent
public func _assumeNonNegative(_ x: Int8) -> Int8 {
  _internalInvariant(x >= (0 as Int8))
  return Int8(Builtin.assumeNonNegative_Int8(x._value))
}

extension Int64 {

  @_transparent
  public static func == (lhs: Int64, rhs: Int64) -> Bool {
    return Bool(Builtin.cmp_eq_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: Int64, rhs: Int64) -> Bool {
    return Bool(Builtin.cmp_slt_Int64(lhs._value, rhs._value))
  }
  @_transparent
  public static func +=(lhs: inout Int64, rhs: Int64) {
    let (result, _) =
    Builtin.sadd_with_overflow_Int64(
      lhs._value, rhs._value, true._value)
    lhs = Int64(result)
  }

  @_transparent
  public static func -=(lhs: inout Int64, rhs: Int64) {
    let (result, _) =
    Builtin.ssub_with_overflow_Int64(
      lhs._value, rhs._value, true._value)
    lhs = Int64(result)
  }

  @_transparent
  public static func *=(lhs: inout Int64, rhs: Int64) {
    let (result, _) =
      Builtin.smul_with_overflow_Int64(
        lhs._value, rhs._value, true._value)
    lhs = Int64(result)
  }

  @_transparent
  public static func /=(lhs: inout Int64, rhs: Int64) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as Int64)) {
      _preconditionFailure()
      return
    }

    if _slowPath(
      lhs == Int64.min && rhs == (-1 as Int64)
    ) {
      _preconditionFailure()
      return
    }

    let (result, _) =
      (Builtin.sdiv_Int64(lhs._value, rhs._value),
      false._value)
    lhs = Int64(result)
  }

  @_transparent
  public static func %=(lhs: inout Int64, rhs: Int64) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as Int64)) {
      _preconditionFailure()
    }

    if _slowPath(lhs == Int64.min && rhs == (-1 as Int64)) {
      _preconditionFailure()
    }

    let (newStorage, _) = (
      Builtin.srem_Int64(lhs._value, rhs._value),
      false._value)
    lhs = Int64(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout Int64, rhs: Int64) {
    lhs = Int64(Builtin.and_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout Int64, rhs: Int64) {
    lhs = Int64(Builtin.or_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout Int64, rhs: Int64) {
    lhs = Int64(Builtin.xor_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout Int64, rhs: Int64) {
    let rhs_ = rhs & 63
    lhs = Int64(
      Builtin.ashr_Int64(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout Int64, rhs: Int64) {
    let rhs_ = rhs & 63
    lhs = Int64(
      Builtin.shl_Int64(lhs._value, rhs_._value))
  }

  @_transparent
  public static func +(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func &(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: Int64, rhs: Int64) -> Int64 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: Int64, rhs: Int64) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: Int64, rhs: Int64) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: Int64, rhs: Int64) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: Int64
  ) -> (partialValue: Int64, overflow: Bool) {

        let (newStorage, overflow) =
      Builtin.sadd_with_overflow_Int64(
        self._value, other._value, false._value)

    return (
      partialValue: Int64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: Int64
  ) -> (partialValue: Int64, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.ssub_with_overflow_Int64(
        self._value, other._value, false._value)

    return (
      partialValue: Int64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: Int64
  ) -> (partialValue: Int64, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.smul_with_overflow_Int64(
        self._value, other._value, false._value)

    return (
      partialValue: Int64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: Int64
  ) -> (partialValue: Int64, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as Int64)) {
      return (partialValue: self, overflow: true)
    }

    if _slowPath(self == Int64.min && other == (-1 as Int64)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.sdiv_Int64(self._value, other._value),
      false._value)

    return (
      partialValue: Int64(newStorage),
      overflow: Bool(overflow))
  }


  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: Int64
  ) -> (partialValue: Int64, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as Int64)) {
      return (partialValue: self, overflow: true)
    }

    if _slowPath(self == Int64.min && other == (-1 as Int64)) {
      return (partialValue: 0, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.srem_Int64(self._value, other._value),
      false._value)

    return (
      partialValue: Int64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(
      Int64(
        Builtin.int_ctlz_Int64(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(
      Int64(
        Builtin.int_cttz_Int64(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(
      Int64(
        Builtin.int_ctpop_Int64(self._value)
      )._lowWord._value)
  }
}

extension UInt64 {

  @_transparent
  public static func == (lhs: UInt64, rhs: UInt64) -> Bool {
    return Bool(Builtin.cmp_eq_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: UInt64, rhs: UInt64) -> Bool {
    return Bool(Builtin.cmp_ult_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func +=(lhs: inout UInt64, rhs: UInt64) {
    let (result, _) =
      Builtin.uadd_with_overflow_Int64(
        lhs._value, rhs._value, true._value)
    lhs = UInt64(result)
  }

  @_transparent
  public static func -=(lhs: inout UInt64, rhs: UInt64) {
    let (result, _) =
      Builtin.usub_with_overflow_Int64(
        lhs._value, rhs._value, true._value)
    lhs = UInt64(result)
  }

  @_transparent
  public static func *=(lhs: inout UInt64, rhs: UInt64) {
    let (result, _) =
      Builtin.umul_with_overflow_Int64(
        lhs._value, rhs._value, true._value)
    lhs = UInt64(result)
  }

  @_transparent
  public static func /=(lhs: inout UInt64, rhs: UInt64) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as UInt64)) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.udiv_Int64(lhs._value, rhs._value),
      false._value)
    lhs = UInt64(result)
  }

  @_transparent
  public static func %=(lhs: inout UInt64, rhs: UInt64) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as UInt64)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.urem_Int64(lhs._value, rhs._value),
      false._value)
    lhs = UInt64(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout UInt64, rhs: UInt64) {
    lhs = UInt64(Builtin.and_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout UInt64, rhs: UInt64) {
    lhs = UInt64(Builtin.or_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout UInt64, rhs: UInt64) {
    lhs = UInt64(Builtin.xor_Int64(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout UInt64, rhs: UInt64) {
    let rhs_ = rhs & 63
    lhs = UInt64(
      Builtin.lshr_Int64(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout UInt64, rhs: UInt64) {
    let rhs_ = rhs & 63
    lhs = UInt64(
      Builtin.shl_Int64(lhs._value, rhs_._value))
  }

  @_transparent
  public static func +(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func &(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: UInt64, rhs: UInt64) -> UInt64 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: UInt64, rhs: UInt64) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: UInt64, rhs: UInt64) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: UInt64, rhs: UInt64) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: UInt64
  ) -> (partialValue: UInt64, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.uadd_with_overflow_Int64(
        self._value, other._value, false._value)

    return (
      partialValue: UInt64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: UInt64
  ) -> (partialValue: UInt64, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.usub_with_overflow_Int64(
        self._value, other._value, false._value)

    return (
      partialValue: UInt64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: UInt64
  ) -> (partialValue: UInt64, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.umul_with_overflow_Int64(
        self._value, other._value, false._value)

    return (
      partialValue: UInt64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: UInt64
  ) -> (partialValue: UInt64, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as UInt64)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.udiv_Int64(self._value, other._value),
      false._value)

    return (
      partialValue: UInt64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: UInt64
  ) -> (partialValue: UInt64, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as UInt64)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.urem_Int64(self._value, other._value),
      false._value)

    return (
      partialValue: UInt64(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(
      UInt64(
        Builtin.int_ctlz_Int64(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(
      UInt64(
        Builtin.int_cttz_Int64(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(
      UInt64(
        Builtin.int_ctpop_Int64(self._value)
      )._lowWord._value)
  }
}

extension Int32 {
  @_transparent
  public static func == (lhs: Int32, rhs: Int32) -> Bool {
    return Bool(Builtin.cmp_eq_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: Int32, rhs: Int32) -> Bool {
    return Bool(Builtin.cmp_slt_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func +=(lhs: inout Int32, rhs: Int32) {
    let (result, _) =
    Builtin.sadd_with_overflow_Int32(
      lhs._value, rhs._value, true._value)
    lhs = Int32(result)
  }

  @_transparent
  public static func -=(lhs: inout Int32, rhs: Int32) {
    let (result, _) =
    Builtin.ssub_with_overflow_Int32(
      lhs._value, rhs._value, true._value)
    lhs = Int32(result)
  }

  @_transparent
  public static func *=(lhs: inout Int32, rhs: Int32) {
    let (result, _) =
      Builtin.smul_with_overflow_Int32(
        lhs._value, rhs._value, true._value)
    lhs = Int32(result)
  }

  @_transparent
  public static func /=(lhs: inout Int32, rhs: Int32) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as Int32)) {
      _precondition(false)
      return

    }

    if _slowPath(
      lhs == Int32.min && rhs == (-1 as Int32)
    ) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.sdiv_Int32(lhs._value, rhs._value),
      false._value)
    lhs = Int32(result)
  }

  @_transparent
  public static func %=(lhs: inout Int32, rhs: Int32) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as Int32)) {
      _precondition(false)
      return
    }

    if _slowPath(lhs == Int32.min && rhs == (-1 as Int32)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.srem_Int32(lhs._value, rhs._value),
      false._value)
    lhs = Int32(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout Int32, rhs: Int32) {
    lhs = Int32(Builtin.and_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout Int32, rhs: Int32) {
    lhs = Int32(Builtin.or_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout Int32, rhs: Int32) {
    lhs = Int32(Builtin.xor_Int32(lhs._value, rhs._value))
  }


  @_transparent
  public static func &>>=(lhs: inout Int32, rhs: Int32) {
    let rhs_ = rhs & 31
    lhs = Int32(
      Builtin.ashr_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout Int32, rhs: Int32) {
    let rhs_ = rhs & 31
    lhs = Int32(
      Builtin.shl_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public static func +(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func &(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: Int32, rhs: Int32) -> Int32 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: Int32, rhs: Int32) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: Int32, rhs: Int32) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: Int32, rhs: Int32) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: Int32
  ) -> (partialValue: Int32, overflow: Bool) {

        let (newStorage, overflow) =
      Builtin.sadd_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: Int32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: Int32
  ) -> (partialValue: Int32, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.ssub_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: Int32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: Int32
  ) -> (partialValue: Int32, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.smul_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: Int32(newStorage),
      overflow: Bool(overflow))
  }
  @_transparent
  public func dividedReportingOverflow(
    by other: Int32
  ) -> (partialValue: Int32, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as Int32)) {
      return (partialValue: self, overflow: true)
    }

    if _slowPath(self == Int32.min && other == (-1 as Int32)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.sdiv_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: Int32(newStorage),
      overflow: Bool(overflow))
  }


  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: Int32
  ) -> (partialValue: Int32, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as Int32)) {
      return (partialValue: self, overflow: true)
    }

    if _slowPath(self == Int32.min && other == (-1 as Int32)) {
      return (partialValue: 0, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.srem_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: Int32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(
      Int32(
        Builtin.int_ctlz_Int32(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(
      Int32(
        Builtin.int_cttz_Int32(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(
      Int32(
        Builtin.int_ctpop_Int32(self._value)
      )._lowWord._value)
  }
}

extension UInt32 {
  @_transparent
  public static func == (lhs: UInt32, rhs: UInt32) -> Bool {
    return Bool(Builtin.cmp_eq_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: UInt32, rhs: UInt32) -> Bool {
    return Bool(Builtin.cmp_ult_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func &(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }
 
  @_transparent
  public static func /(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func +(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: UInt32, rhs: UInt32) -> UInt32 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: UInt32, rhs: UInt32) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: UInt32, rhs: UInt32) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: UInt32, rhs: UInt32) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public static func +=(lhs: inout UInt32, rhs: UInt32) {
    let (result, _) =
      Builtin.uadd_with_overflow_Int32(
        lhs._value, rhs._value, true._value)
    lhs = UInt32(result)
  }

  @_transparent
  public static func -=(lhs: inout UInt32, rhs: UInt32) {
    let (result, _) =
      Builtin.usub_with_overflow_Int32(
        lhs._value, rhs._value, true._value)
    lhs = UInt32(result)
  }

  @_transparent
  public static func *=(lhs: inout UInt32, rhs: UInt32) {
    let (result, _) =
      Builtin.umul_with_overflow_Int32(
        lhs._value, rhs._value, true._value)
    lhs = UInt32(result)
  }


  @_transparent
  public static func /=(lhs: inout UInt32, rhs: UInt32) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as UInt32)) {
      _precondition(false)
      return
    }
    let (result, _) =
      (Builtin.udiv_Int32(lhs._value, rhs._value),
      false._value)
    lhs = UInt32(result)
  }

  @_transparent
  public static func %=(lhs: inout UInt32, rhs: UInt32) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(rhs == (0 as UInt32)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.urem_Int32(lhs._value, rhs._value),
      false._value)
    lhs = UInt32(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout UInt32, rhs: UInt32) {
    lhs = UInt32(Builtin.and_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout UInt32, rhs: UInt32) {
    lhs = UInt32(Builtin.or_Int32(lhs._value, rhs._value))
  }  

  @_transparent
  public static func ^=(lhs: inout UInt32, rhs: UInt32) {
    lhs = UInt32(Builtin.xor_Int32(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout UInt32, rhs: UInt32) {
    let rhs_ = rhs & 31
    lhs = UInt32(
      Builtin.lshr_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout UInt32, rhs: UInt32) {
    let rhs_ = rhs & 31
    lhs = UInt32(
      Builtin.shl_Int32(lhs._value, rhs_._value))
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: UInt32
  ) -> (partialValue: UInt32, overflow: Bool) {

    let (newStorage, overflow) =
    Builtin.uadd_with_overflow_Int32(
      self._value, other._value, false._value)

    return (
      partialValue: UInt32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: UInt32
  ) -> (partialValue: UInt32, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.usub_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: UInt32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: UInt32
  ) -> (partialValue: UInt32, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.umul_with_overflow_Int32(
        self._value, other._value, false._value)

    return (
      partialValue: UInt32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: UInt32
  ) -> (partialValue: UInt32, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as UInt32)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.udiv_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: UInt32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: UInt32
  ) -> (partialValue: UInt32, overflow: Bool) {
    // No LLVM primitives for checking overflow of division operations, so we
    // check manually.
    if _slowPath(other == (0 as UInt32)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.urem_Int32(self._value, other._value),
      false._value)

    return (
      partialValue: UInt32(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(
      UInt32(
        Builtin.int_ctlz_Int32(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(
      UInt32(
        Builtin.int_cttz_Int32(self._value, false._value)
      )._lowWord._value)
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(
      UInt32(
        Builtin.int_ctpop_Int32(self._value)
      )._lowWord._value)
  }
}

extension Int16 {
  @_transparent
  public static func == (lhs: Int16, rhs: Int16) -> Bool {
    return Bool(Builtin.cmp_eq_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: Int16, rhs: Int16) -> Bool {
    return Bool(Builtin.cmp_slt_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func +=(lhs: inout Int16, rhs: Int16) {
    let (result, _) =
    Builtin.sadd_with_overflow_Int16(
      lhs._value, rhs._value, true._value)
    lhs = Int16(result)
  }

  @_transparent
  public static func -=(lhs: inout Int16, rhs: Int16) {
    let (result, _) =
    Builtin.ssub_with_overflow_Int16(
      lhs._value, rhs._value, true._value)
    lhs = Int16(result)
  }

  @_transparent
  public static func *=(lhs: inout Int16, rhs: Int16) {
    let (result, _) =
    Builtin.smul_with_overflow_Int16(
      lhs._value, rhs._value, true._value)
    lhs = Int16(result)
  }

  @_transparent
  public static func /=(lhs: inout Int16, rhs: Int16) {
    if _slowPath(rhs == (0 as Int16)) {
      _precondition(false)
      return
    }

    if _slowPath(
      lhs == Int16.min && rhs == (-1 as Int16)
    ) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.sdiv_Int16(lhs._value, rhs._value),
      false._value)

    lhs = Int16(result)
  }

  @_transparent
  public static func %=(lhs: inout Int16, rhs: Int16) {
    if _slowPath(rhs == (0 as Int16)) {
      _precondition(false)
      return
    }

    if _slowPath(lhs == Int16.min && rhs == (-1 as Int16)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.srem_Int16(lhs._value, rhs._value),
      false._value)

    lhs = Int16(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout Int16, rhs: Int16) {
    lhs = Int16(Builtin.and_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout Int16, rhs: Int16) {
    lhs = Int16(Builtin.or_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout Int16, rhs: Int16) {
    lhs = Int16(Builtin.xor_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func &(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: Int16, rhs: Int16) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: Int16, rhs: Int16) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: Int16, rhs: Int16) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public static func &>>=(lhs: inout Int16, rhs: Int16) {
    let rhs_ = rhs & 15
    lhs = Int16(
      Builtin.ashr_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout Int16, rhs: Int16) {
    let rhs_ = rhs & 15
    lhs = Int16(
      Builtin.shl_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public static func +(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: Int16, rhs: Int16) -> Int16 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: Int16
  ) -> (partialValue: Int16, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.sadd_with_overflow_Int16(
        self._value, other._value, false._value)

    return (
      partialValue: Int16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: Int16
  ) -> (partialValue: Int16, overflow: Bool) {

        let (newStorage, overflow) =
      Builtin.ssub_with_overflow_Int16(
        self._value, other._value, false._value)

    return (
      partialValue: Int16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: Int16
  ) -> (partialValue: Int16, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.smul_with_overflow_Int16(
        self._value, other._value, false._value)

    return (
      partialValue: Int16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: Int16
  ) -> (partialValue: Int16, overflow: Bool) {
    if _slowPath(other == (0 as Int16)) {
      return (partialValue: self, overflow: true)
    }
    if _slowPath(self == Int16.min && other == (-1 as Int16)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.sdiv_Int16(self._value, other._value),
      false._value)

    return (
      partialValue: Int16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: Int16
  ) -> (partialValue: Int16, overflow: Bool) {
    if _slowPath(other == (0 as Int16)) {
      return (partialValue: self, overflow: true)
    }
    if _slowPath(self == Int16.min && other == (-1 as Int16)) {
      return (partialValue: 0, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.srem_Int16(self._value, other._value),
      false._value)

    return (
      partialValue: Int16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(Int16(Builtin.int_ctlz_Int16(self._value, false._value)))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(Int16(Builtin.int_cttz_Int16(self._value, Bool(false)._value)))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(Int16(Builtin.int_ctpop_Int16(self._value)))
  }
}

extension UInt16 {
  @_transparent
  public static func == (lhs: UInt16, rhs: UInt16) -> Bool {
    return Bool(Builtin.cmp_eq_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: UInt16, rhs: UInt16) -> Bool {
    return Bool(Builtin.cmp_ult_Int16(lhs._value, rhs._value))
  }

  // Builtin.condfail(overflow) [EXCISED]
  @_transparent
  public static func +=(lhs: inout UInt16, rhs: UInt16) {
    let (result, _) =
    Builtin.uadd_with_overflow_Int16(
      lhs._value, rhs._value, true._value)

    lhs = UInt16(result)
  }

  @_transparent
  public static func -=(lhs: inout UInt16, rhs: UInt16) {
    let (result, _) =
    Builtin.usub_with_overflow_Int16(
      lhs._value, rhs._value, true._value)
    lhs = UInt16(result)
  }

  @_transparent
  public static func *=(lhs: inout UInt16, rhs: UInt16) {
    let (result, _) =
      Builtin.umul_with_overflow_Int16(
        lhs._value, rhs._value, true._value)
    lhs = UInt16(result)
  }

  @_transparent
  public static func /=(lhs: inout UInt16, rhs: UInt16) {
    if _slowPath(rhs == (0 as UInt16)) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.udiv_Int16(lhs._value, rhs._value),
      false._value)
    lhs = UInt16(result)
  }

  @_transparent
  public static func %=(lhs: inout UInt16, rhs: UInt16) {

    if _slowPath(rhs == (0 as UInt16)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.urem_Int16(lhs._value, rhs._value),
      false._value)
    lhs = UInt16(newStorage)
  }

  @_transparent
  public static func +(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func &(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: UInt16, rhs: UInt16) -> UInt16 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: UInt16, rhs: UInt16) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: UInt16, rhs: UInt16) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: UInt16, rhs: UInt16) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public static func &=(lhs: inout UInt16, rhs: UInt16) {
    lhs = UInt16(Builtin.and_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout UInt16, rhs: UInt16) {
    lhs = UInt16(Builtin.or_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout UInt16, rhs: UInt16) {
    lhs = UInt16(Builtin.xor_Int16(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout UInt16, rhs: UInt16) {
    let rhs_ = rhs & 15
    lhs = UInt16(
      Builtin.lshr_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout UInt16, rhs: UInt16) {
    let rhs_ = rhs & 15
    lhs = UInt16(
      Builtin.shl_Int16(lhs._value, rhs_._value))
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: UInt16
  ) -> (partialValue: UInt16, overflow: Bool) {

    let (newStorage, overflow) =
    Builtin.uadd_with_overflow_Int16(
      self._value, other._value, false._value)

    return (
      partialValue: UInt16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: UInt16
  ) -> (partialValue: UInt16, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.usub_with_overflow_Int16(
        self._value, other._value, false._value)

    return (
      partialValue: UInt16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: UInt16
  ) -> (partialValue: UInt16, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.umul_with_overflow_Int16(
        self._value, other._value, false._value)

    return (
      partialValue: UInt16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: UInt16
  ) -> (partialValue: UInt16, overflow: Bool) {
    if _slowPath(other == (0 as UInt16)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.udiv_Int16(self._value, other._value),
      false._value)

    return (
      partialValue: UInt16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: UInt16
  ) -> (partialValue: UInt16, overflow: Bool) {
    if _slowPath(other == (0 as UInt16)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.urem_Int16(self._value, other._value),
      false._value)

    return (
      partialValue: UInt16(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(UInt16(Builtin.int_ctlz_Int16(self._value, false._value)))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(UInt16(Builtin.int_cttz_Int16(self._value, Bool(false)._value)))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(UInt16(Builtin.int_ctpop_Int16(self._value)))
  }
}

extension Int8 {
  @_transparent
  public static func == (lhs: Int8, rhs: Int8) -> Bool {
    return Bool(Builtin.cmp_eq_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: Int8, rhs: Int8) -> Bool {
    return Bool(Builtin.cmp_slt_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func +=(lhs: inout Int8, rhs: Int8) {
    let (result, _) =
    Builtin.sadd_with_overflow_Int8(
      lhs._value, rhs._value, true._value)
    lhs = Int8(result)
  }

  @_transparent
  public static func -=(lhs: inout Int8, rhs: Int8) {
    let (result, _) =
    Builtin.ssub_with_overflow_Int8(
      lhs._value, rhs._value, true._value)
    lhs = Int8(result)
  }

  @_transparent
  public static func *=(lhs: inout Int8, rhs: Int8) {
    let (result, _) =
    Builtin.smul_with_overflow_Int8(
      lhs._value, rhs._value, true._value)
    lhs = Int8(result)
  }

  @_transparent
  public static func /=(lhs: inout Int8, rhs: Int8) {
    if _slowPath(rhs == (0 as Int8)) {
      _precondition(false)
      return
    }

    if _slowPath(
      lhs == Int8.min && rhs == (-1 as Int8)
    ) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.sdiv_Int8(lhs._value, rhs._value),
      false._value)

    lhs = Int8(result)
  }

  @_transparent
  public static func %=(lhs: inout Int8, rhs: Int8) {
    if _slowPath(rhs == (0 as Int8)) {
      _precondition(false)
      return
    }

    if _slowPath(lhs == Int8.min && rhs == (-1 as Int8)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.srem_Int8(lhs._value, rhs._value),
      false._value)

    lhs = Int8(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout Int8, rhs: Int8) {
    lhs = Int8(Builtin.and_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout Int8, rhs: Int8) {
    lhs = Int8(Builtin.or_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout Int8, rhs: Int8) {
    lhs = Int8(Builtin.xor_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout Int8, rhs: Int8) {
    let rhs_ = rhs & 15
    lhs = Int8(
      Builtin.ashr_Int8(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout Int8, rhs: Int8) {
    let rhs_ = rhs & 15
    lhs = Int8(
      Builtin.shl_Int8(lhs._value, rhs_._value))
  }

  @_transparent
  public static func +(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func &(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: Int8, rhs: Int8) -> Int8 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: Int8, rhs: Int8) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: Int8, rhs: Int8) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: Int8, rhs: Int8) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: Int8
  ) -> (partialValue: Int8, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.sadd_with_overflow_Int8(
        self._value, other._value, false._value)

    return (
      partialValue: Int8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: Int8
  ) -> (partialValue: Int8, overflow: Bool) {

        let (newStorage, overflow) =
      Builtin.ssub_with_overflow_Int8(
        self._value, other._value, false._value)

    return (
      partialValue: Int8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: Int8
  ) -> (partialValue: Int8, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.smul_with_overflow_Int8(
        self._value, other._value, false._value)

    return (
      partialValue: Int8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: Int8
  ) -> (partialValue: Int8, overflow: Bool) {
    if _slowPath(other == (0 as Int8)) {
      return (partialValue: self, overflow: true)
    }
    if _slowPath(self == Int8.min && other == (-1 as Int8)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.sdiv_Int8(self._value, other._value),
      false._value)

    return (
      partialValue: Int8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: Int8
  ) -> (partialValue: Int8, overflow: Bool) {
    if _slowPath(other == (0 as Int8)) {
      return (partialValue: self, overflow: true)
    }
    if _slowPath(self == Int8.min && other == (-1 as Int8)) {
      return (partialValue: 0, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.srem_Int8(self._value, other._value),
      false._value)

    return (
      partialValue: Int8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(Int8(Builtin.int_ctlz_Int8(self._value, false._value)))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(Int8(Builtin.int_cttz_Int8(self._value, Bool(false)._value)))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(Int8(Builtin.int_ctpop_Int8(self._value)))
  }
}

extension UInt8 {
  @_transparent
  public static func == (lhs: UInt8, rhs: UInt8) -> Bool {
    return Bool(Builtin.cmp_eq_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func < (lhs: UInt8, rhs: UInt8) -> Bool {
    return Bool(Builtin.cmp_ult_Int8(lhs._value, rhs._value))
  }

  // Builtin.condfail(overflow) [EXCISED]
  @_transparent
  public static func +=(lhs: inout UInt8, rhs: UInt8) {
    let (result, _) =
    Builtin.uadd_with_overflow_Int8(
      lhs._value, rhs._value, true._value)

    lhs = UInt8(result)
  }

  @_transparent
  public static func -=(lhs: inout UInt8, rhs: UInt8) {
    let (result, _) =
    Builtin.usub_with_overflow_Int8(
      lhs._value, rhs._value, true._value)
    lhs = UInt8(result)
  }

  @_transparent
  public static func *=(lhs: inout UInt8, rhs: UInt8) {
    let (result, _) =
      Builtin.umul_with_overflow_Int8(
        lhs._value, rhs._value, true._value)
    lhs = UInt8(result)
  }

  @_transparent
  public static func /=(lhs: inout UInt8, rhs: UInt8) {
    if _slowPath(rhs == (0 as UInt8)) {
      _precondition(false)
      return
    }

    let (result, _) =
      (Builtin.udiv_Int8(lhs._value, rhs._value),
      false._value)
    lhs = UInt8(result)
  }

  @_transparent
  public static func %=(lhs: inout UInt8, rhs: UInt8) {

    if _slowPath(rhs == (0 as UInt8)) {
      _precondition(false)
      return
    }

    let (newStorage, _) = (
      Builtin.urem_Int8(lhs._value, rhs._value),
      false._value)
    lhs = UInt8(newStorage)
  }

  @_transparent
  public static func &=(lhs: inout UInt8, rhs: UInt8) {
    lhs = UInt8(Builtin.and_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func |=(lhs: inout UInt8, rhs: UInt8) {
    lhs = UInt8(Builtin.or_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func ^=(lhs: inout UInt8, rhs: UInt8) {
    lhs = UInt8(Builtin.xor_Int8(lhs._value, rhs._value))
  }

  @_transparent
  public static func &>>=(lhs: inout UInt8, rhs: UInt8) {
    let rhs_ = rhs & 7
    lhs = UInt8(
      Builtin.lshr_Int8(lhs._value, rhs_._value))
  }

  @_transparent
  public static func &<<=(lhs: inout UInt8, rhs: UInt8) {
    let rhs_ = rhs & 7
    lhs = UInt8(
      Builtin.shl_Int8(lhs._value, rhs_._value))
  }

  @_transparent
  public static func +(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs += rhs
    return lhs
  }

  @_transparent
  public static func -(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs -= rhs
    return lhs
  }

  @_transparent
  public static func *(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs *= rhs
    return lhs
  }

  @_transparent
  public static func /(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs /= rhs
    return lhs
  }

  @_transparent
  public static func %(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs %= rhs
    return lhs
  }

  @_transparent
  public static func &(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func |(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

  @_transparent
  public static func &>>(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs &>>= rhs
    return lhs
  }

  @_transparent
  public static func &<<(lhs: UInt8, rhs: UInt8) -> UInt8 {
    var lhs = lhs
    lhs &<<= rhs
    return lhs
  }

  @_transparent
  public static func <= (lhs: UInt8, rhs: UInt8) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: UInt8, rhs: UInt8) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: UInt8, rhs: UInt8) -> Bool {
    return rhs < lhs
  }

  @_transparent
  public func addingReportingOverflow(
    _ other: UInt8
  ) -> (partialValue: UInt8, overflow: Bool) {

    let (newStorage, overflow) =
    Builtin.uadd_with_overflow_Int8(
      self._value, other._value, false._value)

    return (
      partialValue: UInt8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func subtractingReportingOverflow(
    _ other: UInt8
  ) -> (partialValue: UInt8, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.usub_with_overflow_Int8(
        self._value, other._value, false._value)

    return (
      partialValue: UInt8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func multipliedReportingOverflow(
    by other: UInt8
  ) -> (partialValue: UInt8, overflow: Bool) {

    let (newStorage, overflow) =
      Builtin.umul_with_overflow_Int8(
        self._value, other._value, false._value)

    return (
      partialValue: UInt8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func dividedReportingOverflow(
    by other: UInt8
  ) -> (partialValue: UInt8, overflow: Bool) {
    if _slowPath(other == (0 as UInt8)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.udiv_Int8(self._value, other._value),
      false._value)

    return (
      partialValue: UInt8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public func remainderReportingOverflow(
    dividingBy other: UInt8
  ) -> (partialValue: UInt8, overflow: Bool) {
    if _slowPath(other == (0 as UInt8)) {
      return (partialValue: self, overflow: true)
    }

    let (newStorage, overflow) = (
      Builtin.urem_Int8(self._value, other._value),
      false._value)

    return (
      partialValue: UInt8(newStorage),
      overflow: Bool(overflow))
  }

  @_transparent
  public var leadingZeroBitCount: Int {
    return Int(Int8(Builtin.int_ctlz_Int8(self._value, false._value)))
  }

  @_transparent
  public var trailingZeroBitCount: Int {
    return Int(Int8(Builtin.int_cttz_Int8(self._value, Bool(false)._value)))
  }

  @_transparent
  public var nonzeroBitCount: Int {
    return Int(Int8(Builtin.int_ctpop_Int8(self._value)))
  }
}
