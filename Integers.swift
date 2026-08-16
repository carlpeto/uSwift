// fixed/known size integers, regardless of platform

@frozen
public struct Int64 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, SignedInteger
{
  @usableFromInline
  var _value: Builtin.Int64

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    let builtinValue = Builtin.s_to_s_checked_trunc_IntLiteral_Int64(value).0
    self._value = builtinValue
  }

  @_transparent
  public init(bitPattern x: UInt64) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int64) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 64 }  

  @_transparent
  public var magnitude: UInt64 {
    let base = UInt64(_value)
    return self < (0 as Int64) ? ~base &+ 1 : base
  }
}

extension Int64 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<Int64.Words>

    @usableFromInline
    internal var _value: Int64

    @inlinable
    public init(_ value: Int64) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: Int64 {
    return Int64(Builtin.int_bswap_Int64(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: Int64)
    -> (high: Int64, low: Int64.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.sext_Int64_Int128(self._value)
    let rhs_ = Builtin.sext_Int64_Int128(other._value)

    let res = Builtin.mul_Int128(lhs_, rhs_)
    let low = Int64.Magnitude(Builtin.truncOrBitCast_Int128_Int64(res))
    let shift = Builtin.zextOrBitCast_Int8_Int128(UInt8(64)._value)
    let shifted = Builtin.ashr_Int128(res, shift)
    let high = Int64(Builtin.truncOrBitCast_Int128_Int64(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: Int64, low: Int64.Magnitude)
  ) -> (quotient: Int64, remainder: Int64) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.sext_Int64_Int128(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int128(UInt8(64)._value)
    let lhsHighShifted = Builtin.shl_Int128(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int64_Int128(dividend.low._value)
    let lhs_ = Builtin.or_Int128(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.sext_Int64_Int128(self._value)

    let quotient_ = Builtin.sdiv_Int128(lhs_, rhs_)
    let remainder_ = Builtin.srem_Int128(lhs_, rhs_)

    let quotient = Int64(
      Builtin.truncOrBitCast_Int128_Int64(quotient_))
    let remainder = Int64(
      Builtin.truncOrBitCast_Int128_Int64(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension Int64: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt64(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(seed: seed, UInt64(_value))
  }
}

@frozen
public struct UInt64 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, UnsignedInteger
{
  @usableFromInline
  var _value: Builtin.Int64

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    self._value = Builtin.s_to_u_checked_trunc_IntLiteral_Int64(value).0
  }

  @_transparent
  public init(bitPattern x: Int64) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int64) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 64 }
}

extension UInt64 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UInt64.Words>

    @usableFromInline
    internal var _value: UInt64

    @inlinable
    public init(_ value: UInt64) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: UInt64 {
    return UInt64(Builtin.int_bswap_Int64(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: UInt64)
    -> (high: UInt64, low: UInt64.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.zext_Int64_Int128(self._value)
    let rhs_ = Builtin.zext_Int64_Int128(other._value)

    let res = Builtin.mul_Int128(lhs_, rhs_)
    let low = UInt64.Magnitude(Builtin.truncOrBitCast_Int128_Int64(res))
    let shift = Builtin.zextOrBitCast_Int8_Int128(UInt8(64)._value)
    let shifted = Builtin.ashr_Int128(res, shift)
    let high = UInt64(Builtin.truncOrBitCast_Int128_Int64(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: UInt64, low: UInt64.Magnitude)
  ) -> (quotient: UInt64, remainder: UInt64) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.zext_Int64_Int128(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int128(UInt8(64)._value)
    let lhsHighShifted = Builtin.shl_Int128(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int64_Int128(dividend.low._value)
    let lhs_ = Builtin.or_Int128(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.zext_Int64_Int128(self._value)

    let quotient_ = Builtin.udiv_Int128(lhs_, rhs_)
    let remainder_ = Builtin.urem_Int128(lhs_, rhs_)

    let quotient = UInt64(
      Builtin.truncOrBitCast_Int128_Int64(quotient_))
    let remainder = UInt64(
      Builtin.truncOrBitCast_Int128_Int64(remainder_))

    return (quotient: quotient, remainder: remainder)
  }  
}

extension UInt64: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt64(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(seed: seed, UInt64(_value))
  }
}

@frozen
public struct Int32 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, SignedInteger
{
  @usableFromInline
  var _value: Builtin.Int32

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    let builtinValue = Builtin.s_to_s_checked_trunc_IntLiteral_Int32(value).0
    self._value = builtinValue
  }

  @_transparent
  public init(bitPattern x: UInt32) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int32) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 32 }

  @_transparent
  public var magnitude: UInt32 {
    let base = UInt32(_value)
    return self < (0 as Int32) ? ~base &+ 1 : base
  }
}

extension Int32 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<Int32.Words>

    @usableFromInline
    internal var _value: Int32

    @inlinable
    public init(_ value: Int32) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: Int32 {
    return Int32(Builtin.int_bswap_Int32(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: Int32)
    -> (high: Int32, low: Int32.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.sext_Int32_Int64(self._value)
    let rhs_ = Builtin.sext_Int32_Int64(other._value)

    let res = Builtin.mul_Int64(lhs_, rhs_)
    let low = Int32.Magnitude(Builtin.truncOrBitCast_Int64_Int32(res))
    let shift = Builtin.zextOrBitCast_Int8_Int64(UInt8(32)._value)
    let shifted = Builtin.ashr_Int64(res, shift)
    let high = Int32(Builtin.truncOrBitCast_Int64_Int32(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: Int32, low: Int32.Magnitude)
  ) -> (quotient: Int32, remainder: Int32) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.sext_Int32_Int64(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int64(UInt8(32)._value)
    let lhsHighShifted = Builtin.shl_Int64(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int32_Int64(dividend.low._value)
    let lhs_ = Builtin.or_Int64(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.sext_Int32_Int64(self._value)

    let quotient_ = Builtin.sdiv_Int64(lhs_, rhs_)
    let remainder_ = Builtin.srem_Int64(lhs_, rhs_)

    let quotient = Int32(
      Builtin.truncOrBitCast_Int64_Int32(quotient_))
    let remainder = Int32(
      Builtin.truncOrBitCast_Int64_Int32(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension Int32: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt32(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(
    seed: seed,
    bytes: UInt64(truncatingIfNeeded: UInt32(_value)),
    count: 4)
  }
}

@frozen
public struct UInt32 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, UnsignedInteger
{
  @usableFromInline
  var _value: Builtin.Int32

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    self._value = Builtin.s_to_u_checked_trunc_IntLiteral_Int32(value).0
  }

  @_transparent
  public init(bitPattern x: Int32) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int32) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 32 }
}

extension UInt32 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UInt32.Words>

    @usableFromInline
    internal var _value: UInt32

    @inlinable
    public init(_ value: UInt32) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: UInt32 {
    return UInt32(Builtin.int_bswap_Int32(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: UInt32)
    -> (high: UInt32, low: UInt32.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.zext_Int32_Int64(self._value)
    let rhs_ = Builtin.zext_Int32_Int64(other._value)

    let res = Builtin.mul_Int64(lhs_, rhs_)
    let low = UInt32.Magnitude(Builtin.truncOrBitCast_Int64_Int32(res))
    let shift = Builtin.zextOrBitCast_Int8_Int64(UInt8(32)._value)
    let shifted = Builtin.ashr_Int64(res, shift)
    let high = UInt32(Builtin.truncOrBitCast_Int64_Int32(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: UInt32, low: UInt32.Magnitude)
  ) -> (quotient: UInt32, remainder: UInt32) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.zext_Int32_Int64(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int64(UInt8(32)._value)
    let lhsHighShifted = Builtin.shl_Int64(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int32_Int64(dividend.low._value)
    let lhs_ = Builtin.or_Int64(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.zext_Int32_Int64(self._value)

    let quotient_ = Builtin.udiv_Int64(lhs_, rhs_)
    let remainder_ = Builtin.urem_Int64(lhs_, rhs_)

    let quotient = UInt32(
      Builtin.truncOrBitCast_Int64_Int32(quotient_))
    let remainder = UInt32(
      Builtin.truncOrBitCast_Int64_Int32(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension UInt32: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt32(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(
    seed: seed,
    bytes: UInt64(truncatingIfNeeded: UInt32(_value)),
    count: 4)
  }
}

@frozen
public struct Int16 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, SignedInteger
{
  @usableFromInline
  var _value: Builtin.Int16

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    let builtinValue = Builtin.s_to_s_checked_trunc_IntLiteral_Int16(value).0
    self._value = builtinValue
  }

  @_transparent
  public init(bitPattern x: UInt16) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int16) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 16 }

  @_transparent
  public var magnitude: UInt16 {
    let base = UInt16(_value)
    return self < (0 as Int16) ? ~base &+ 1 : base
  }
}

extension Int16 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<Int16.Words>

    @usableFromInline
    internal var _value: Int16

    @inlinable
    public init(_ value: Int16) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: Int16 {
    return Int16(Builtin.int_bswap_Int16(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: Int16)
    -> (high: Int16, low: Int16.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.sext_Int16_Int32(self._value)
    let rhs_ = Builtin.sext_Int16_Int32(other._value)

    let res = Builtin.mul_Int32(lhs_, rhs_)
    let low = Int16.Magnitude(Builtin.truncOrBitCast_Int32_Int16(res))
    let shift = Builtin.zextOrBitCast_Int8_Int32(UInt8(16)._value)
    let shifted = Builtin.ashr_Int32(res, shift)
    let high = Int16(Builtin.truncOrBitCast_Int32_Int16(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: Int16, low: Int16.Magnitude)
  ) -> (quotient: Int16, remainder: Int16) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.sext_Int16_Int32(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int32(UInt8(16)._value)
    let lhsHighShifted = Builtin.shl_Int32(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int16_Int32(dividend.low._value)
    let lhs_ = Builtin.or_Int32(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.sext_Int16_Int32(self._value)

    let quotient_ = Builtin.sdiv_Int32(lhs_, rhs_)
    let remainder_ = Builtin.srem_Int32(lhs_, rhs_)

    let quotient = Int16(
      Builtin.truncOrBitCast_Int32_Int16(quotient_))
    let remainder = Int16(
      Builtin.truncOrBitCast_Int32_Int16(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension Int16: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt16(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(
    seed: seed,
    bytes: UInt64(truncatingIfNeeded: UInt16(_value)),
    count: 2)
  }
}

@frozen
public struct UInt16 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, UnsignedInteger
{
  @usableFromInline
  var _value: Builtin.Int16

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    self._value = Builtin.s_to_u_checked_trunc_IntLiteral_Int16(value).0
  }

  @_transparent
  public init(bitPattern x: Int16) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int16) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 16 }
}

extension UInt16 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UInt16.Words>

    @usableFromInline
    internal var _value: UInt16

    @inlinable
    public init(_ value: UInt16) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: UInt16 {
    return UInt16(Builtin.int_bswap_Int16(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: UInt16)
    -> (high: UInt16, low: UInt16.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.zext_Int16_Int32(self._value)
    let rhs_ = Builtin.zext_Int16_Int32(other._value)

    let res = Builtin.mul_Int32(lhs_, rhs_)
    let low = UInt16.Magnitude(Builtin.truncOrBitCast_Int32_Int16(res))
    let shift = Builtin.zextOrBitCast_Int8_Int32(UInt8(16)._value)
    let shifted = Builtin.ashr_Int32(res, shift)
    let high = UInt16(Builtin.truncOrBitCast_Int32_Int16(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: UInt16, low: UInt16.Magnitude)
  ) -> (quotient: UInt16, remainder: UInt16) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.zext_Int16_Int32(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int32(UInt8(16)._value)
    let lhsHighShifted = Builtin.shl_Int32(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int16_Int32(dividend.low._value)
    let lhs_ = Builtin.or_Int32(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.zext_Int16_Int32(self._value)

    let quotient_ = Builtin.udiv_Int32(lhs_, rhs_)
    let remainder_ = Builtin.urem_Int32(lhs_, rhs_)

    let quotient = UInt16(
      Builtin.truncOrBitCast_Int32_Int16(quotient_))
    let remainder = UInt16(
      Builtin.truncOrBitCast_Int32_Int16(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension UInt16: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt16(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(
    seed: seed,
    bytes: UInt64(truncatingIfNeeded: UInt16(_value)),
    count: 2)
  }
}

@frozen
public struct Int8 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, SignedInteger
{
  @usableFromInline
  var _value: Builtin.Int8

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    let builtinValue = Builtin.s_to_s_checked_trunc_IntLiteral_Int8(value).0
    self._value = builtinValue
  }

  @_transparent
  public init(bitPattern x: UInt8) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int8) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 8 }

  @_transparent
  public var magnitude: UInt8 {
    let base = UInt8(_value)
    return self < (0 as Int8) ? ~base &+ 1 : base
  }
}

extension Int8 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<Int8.Words>

    @usableFromInline
    internal var _value: Int8

    @inlinable
    public init(_ value: Int8) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: Int8 {
    return self
  }

  @inlinable
  public func multipliedFullWidth(by other: Int8)
    -> (high: Int8, low: Int8.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.sext_Int8_Int16(self._value)
    let rhs_ = Builtin.sext_Int8_Int16(other._value)

    let res = Builtin.mul_Int16(lhs_, rhs_)
    let low = Int8.Magnitude(Builtin.truncOrBitCast_Int16_Int8(res))
    let shift = Builtin.zextOrBitCast_Int8_Int16(UInt8(8)._value)
    let shifted = Builtin.ashr_Int16(res, shift)
    let high = Int8(Builtin.truncOrBitCast_Int16_Int8(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: Int8, low: Int8.Magnitude)
  ) -> (quotient: Int8, remainder: Int8) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.sext_Int8_Int16(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int16(UInt8(8)._value)
    let lhsHighShifted = Builtin.shl_Int16(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int8_Int16(dividend.low._value)
    let lhs_ = Builtin.or_Int16(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.sext_Int8_Int16(self._value)

    let quotient_ = Builtin.sdiv_Int16(lhs_, rhs_)
    let remainder_ = Builtin.srem_Int16(lhs_, rhs_)

    let quotient = Int8(
      Builtin.truncOrBitCast_Int16_Int8(quotient_))
    let remainder = Int8(
      Builtin.truncOrBitCast_Int16_Int8(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension Int8: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt8(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(
    seed: seed,
    bytes: UInt64(truncatingIfNeeded: UInt8(_value)),
    count: 1)
  }
}

@frozen
public struct UInt8 : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, UnsignedInteger
{
  @usableFromInline
  var _value: Builtin.Int8

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    let builtinValue = Builtin.s_to_u_checked_trunc_IntLiteral_Int8(value).0
    self._value = builtinValue
  }

  @_transparent
  public init(bitPattern x: Int8) {
    _value = x._value
  }

  @_transparent
  public init(_ _value: Builtin.Int8) {
    self._value = _value
  }

  @_transparent
  public static var bitWidth : Int { return 8 }
}

extension  UInt8 {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UInt8.Words>

    @usableFromInline
    internal var _value: UInt8

    @inlinable
    public init(_ value: UInt8) {
      self._value = value
    }

    @inlinable
    public var startIndex: Int { return 0 }

    @inlinable
    public var endIndex: Int { return count }

    @inlinable
    public var indices: Indices { return startIndex ..< endIndex }

    @_transparent
    public func index(after i: Int) -> Int { return i + 1 }

    @_transparent
    public func index(before i: Int) -> Int { return i - 1 }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: UInt8 {
    return self
  }

  @inlinable
  public func multipliedFullWidth(by other: UInt8)
    -> (high: UInt8, low: UInt8.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.zext_Int8_Int16(self._value)
    let rhs_ = Builtin.zext_Int8_Int16(other._value)

    let res = Builtin.mul_Int16(lhs_, rhs_)
    let low = UInt8.Magnitude(Builtin.truncOrBitCast_Int16_Int8(res))
    let shift = Builtin.zextOrBitCast_Int8_Int16(UInt8(8)._value)
    let shifted = Builtin.ashr_Int16(res, shift)
    let high = UInt8(Builtin.truncOrBitCast_Int16_Int8(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: UInt8, low: UInt8.Magnitude)
  ) -> (quotient: UInt8, remainder: UInt8) {
    // FIXME(integers): tests
    // FIXME(integers): handle division by zero and overflows
    _precondition(self != 0)
    let lhsHigh = Builtin.zext_Int8_Int16(dividend.high._value)
    let shift = Builtin.zextOrBitCast_Int8_Int16(UInt8(8)._value)
    let lhsHighShifted = Builtin.shl_Int16(lhsHigh, shift)
    let lhsLow = Builtin.zext_Int8_Int16(dividend.low._value)
    let lhs_ = Builtin.or_Int16(lhsHighShifted, lhsLow)
    let rhs_ = Builtin.zext_Int8_Int16(self._value)

    let quotient_ = Builtin.udiv_Int16(lhs_, rhs_)
    let remainder_ = Builtin.urem_Int16(lhs_, rhs_)

    let quotient = UInt8(
      Builtin.truncOrBitCast_Int16_Int8(quotient_))
    let remainder = UInt8(
      Builtin.truncOrBitCast_Int16_Int8(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}
extension UInt8: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt8(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(
    seed: seed,
    bytes: UInt64(truncatingIfNeeded: UInt8(_value)),
    count: 1)
  }
}

extension UInt8 {
  // this is just to simplify the stdlib code conversion
  @_transparent
  public // @testable
  var _builtinWordValue: Builtin.Word {
    return Builtin.zextOrBitCast_Int8_Word(_value)
  }
}
