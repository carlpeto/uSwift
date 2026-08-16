// this contains the pointer sized integer, unsigned integer and related extensions
// we keep this separate as it varies between microcontrollers, for example it is 16 bit on AVR and 32 bit on ARM Cortex-M0

@frozen
public struct Int :
_ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, SignedInteger
{
  @usableFromInline
  var _value: Builtin.Int16

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    self._value = Builtin.s_to_s_checked_trunc_IntLiteral_Int16(value).0
  }

  @_transparent
  public init(bitPattern x: UInt) {
    _value = x._value
  }

  @_transparent
  public init(_truncatingBits bits: UInt) {
    self.init(bitPattern: bits)
  }

  @_transparent
  public static var bitWidth : Int { return 16 }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(bitPattern: self)
  }

  @_transparent
  public // @testable
  init(_ _v: Builtin.Int16) {
    self._value = _v
  }

  @_transparent
  public // @testable
  init(_ _v: Builtin.Word) {
    self._value = Builtin.truncOrBitCast_Word_Int16(_v)
  }

  @_transparent
  public // @testable
  var _builtinWordValue: Builtin.Word {
    return Builtin.zextOrBitCast_Int16_Word(_value)
  }

  @_transparent
  public var magnitude: UInt {
    let base = UInt(_value)
    return self < (0 as Int) ? ~base &+ 1 : base
  }
}

extension Int {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<Int.Words>

    @usableFromInline
    internal var _value: Int

    @inlinable
    public init(_ value: Int) {
      self._value = value
    }

    @inlinable
    public var count: Int {
      return (16 + 16 - 1) / 16
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

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> Int(_truncatingBits: shift))._lowWord
      }
    }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: Int {
    return Int(Builtin.int_bswap_Int16(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: Int)
    -> (high: Int, low: Int.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.sext_Int16_Int32(self._value)
    let rhs_ = Builtin.sext_Int16_Int32(other._value)

    let res = Builtin.mul_Int32(lhs_, rhs_)
    let low = Int.Magnitude(Builtin.truncOrBitCast_Int32_Int16(res))
    let shift = Builtin.zextOrBitCast_Int8_Int32(UInt8(16)._value)
    let shifted = Builtin.ashr_Int32(res, shift)
    let high = Int(Builtin.truncOrBitCast_Int32_Int16(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: Int, low: Int.Magnitude)
  ) -> (quotient: Int, remainder: Int) {
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

    let quotient = Int(
      Builtin.truncOrBitCast_Int32_Int16(quotient_))
    let remainder = Int(
      Builtin.truncOrBitCast_Int32_Int16(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension Int: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(seed: seed, UInt(_value))
  }
}

@frozen
public struct UInt : _ExpressibleByBuiltinIntegerLiteral, ExpressibleByIntegerLiteral,
FixedWidthInteger, UnsignedInteger
{
  @usableFromInline
  var _value: Builtin.Int16

  @_transparent
  public init(_builtinIntegerLiteral value: Builtin.IntLiteral) {
    self._value = Builtin.s_to_u_checked_trunc_IntLiteral_Int16(value).0
  }

  @_transparent
  public init(bitPattern x: Int) {
    _value = x._value
  }

  @_transparent
  public // @testable
  init(_ _v: Builtin.Int16) {
    self._value = _v
  }

  @_transparent
  public // @testable
  init(_ _v: Builtin.Word) {
    self._value = Builtin.truncOrBitCast_Word_Int16(_v)
  }

  @_transparent
  public // @testable
  var _builtinWordValue: Builtin.Word {
    return Builtin.zextOrBitCast_Int16_Word(_value)
  }

  @_transparent
  public init(_truncatingBits bits: UInt) {
    self = bits
  }

  @_transparent
  public static var bitWidth : Int { return 16 }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return self
  }
}

extension UInt {
  @frozen
  public struct Words : RandomAccessCollection {
    public typealias Indices = Range<Int>
    public typealias SubSequence = Slice<UInt.Words>

    @usableFromInline
    internal var _value: UInt

    @inlinable
    public init(_ value: UInt) {
      self._value = value
    }

    @inlinable
    public var count: Int {
      return (16 + 16 - 1) / 16
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

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> UInt(_truncatingBits: shift))._lowWord
      }
    }
  }

  @_transparent
  public var words: Words {
    return Words(self)
  }

  @_transparent
  public var byteSwapped: UInt {
    return UInt(Builtin.int_bswap_Int16(_value))
  }

  @inlinable
  public func multipliedFullWidth(by other: UInt)
    -> (high: UInt, low: UInt.Magnitude) {
    // FIXME(integers): tests
    let lhs_ = Builtin.zext_Int16_Int32(self._value)
    let rhs_ = Builtin.zext_Int16_Int32(other._value)

    let res = Builtin.mul_Int32(lhs_, rhs_)
    let low = UInt.Magnitude(Builtin.truncOrBitCast_Int32_Int16(res))
    let shift = Builtin.zextOrBitCast_Int8_Int32(UInt8(16)._value)
    let shifted = Builtin.ashr_Int32(res, shift)
    let high = UInt(Builtin.truncOrBitCast_Int32_Int16(shifted))
    return (high: high, low: low)
  }

  @inlinable
  public func dividingFullWidth(
    _ dividend: (high: UInt, low: UInt.Magnitude)
  ) -> (quotient: UInt, remainder: UInt) {
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

    let quotient = UInt(
      Builtin.truncOrBitCast_Int32_Int16(quotient_))
    let remainder = UInt(
      Builtin.truncOrBitCast_Int32_Int16(remainder_))

    return (quotient: quotient, remainder: remainder)
  }
}

extension UInt: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher._combine(UInt(_value))
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return Hasher._hash(seed: seed, UInt(_value))
  }
}


// extensions on known size integers that have dependancies on Int's bit size

extension Int64 {
  @_transparent
  public init(_truncatingBits bits: UInt) {
    // this seems wrong for 16 bit words but I suspect may be hard to fix
    self.init(Builtin.zextOrBitCast_Int16_Int64(bits._value))
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(
      Builtin.truncOrBitCast_Int64_Int16(_value)
    )
  }
}

extension Int64.Words {
    @inlinable
	public var count: Int {
	  return (64 + 16 - 1) / 16
	}

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> Int64(_truncatingBits: shift))._lowWord
      }
    }
}

extension UInt64 {
  @_transparent
  public init(_truncatingBits bits: UInt) {
    // this seems wrong for 16 bit words but I suspect may be hard to fix
    self.init(Builtin.zextOrBitCast_Int16_Int64(bits._value))
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(
      Builtin.truncOrBitCast_Int64_Int16(_value)
    )
  }
}


extension UInt64.Words {
    @inlinable
    public var count: Int {
      return (64 + 16 - 1) / 16
    }

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> UInt64(_truncatingBits: shift))._lowWord
      }
    }
}

extension Int32 {
  @_transparent
  public init(_truncatingBits bits: UInt) {
    // this seems wrong for 16 bit words but I suspect may be hard to fix
    self.init(Builtin.zextOrBitCast_Int16_Int32(bits._value))
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(
      Builtin.truncOrBitCast_Int32_Int16(_value)
    )
  }
}

extension Int32.Words {
    @inlinable
    public var count: Int {
      return (32 + 16 - 1) / 16
    }

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> Int32(_truncatingBits: shift))._lowWord
      }
    }
}

extension UInt32 {
  @_transparent
  public init(_truncatingBits bits: UInt) {
    // this seems wrong for 16 bit words but I suspect may be hard to fix
    self.init(Builtin.zextOrBitCast_Int16_Int32(bits._value))
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(
      Builtin.truncOrBitCast_Int32_Int16(_value)
    )
  }
}

extension UInt32.Words {
    @inlinable
    public var count: Int {
      return (32 + 16 - 1) / 16
    }

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> UInt32(_truncatingBits: shift))._lowWord
      }
    }
}

extension Int16 {
  @_transparent
  public // transparent
  init(_truncatingBits bits: UInt) {
    self.init(bits._value)
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(self._value)
  }
}

extension Int16.Words {
    @inlinable
    public var count: Int {
      return (16 + 16 - 1) / 16
    }

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> Int16(_truncatingBits: shift))._lowWord
      }
    }
}

extension UInt16 {
  @_transparent
  public // transparent
  init(_truncatingBits bits: UInt) {
    self.init(bits._value)
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(self._value)
  }
}

extension UInt16.Words {
    @inlinable
    public var count: Int {
      return (16 + 16 - 1) / 16
    }

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> UInt16(_truncatingBits: shift))._lowWord
      }
    }
}

extension Int8 {
  @_transparent
  public init(_truncatingBits bits: UInt) {
    self.init(Builtin.truncOrBitCast_Int16_Int8(bits._value))
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(
      Builtin.sextOrBitCast_Int8_Int16(_value)
    )
  }
}

extension Int8.Words {
    @inlinable
    public var count: Int {
      return (8 + 16 - 1) / 16
    }

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        _precondition(position >= 0)
        _precondition(position < endIndex)
        let shift = UInt(position._value) &* 16
        _internalInvariant(shift < UInt(_value.bitWidth._value))
        return (_value &>> Int8(_truncatingBits: shift))._lowWord
      }
    }
}

extension UInt8 {
  @_transparent
  public init(_truncatingBits bits: UInt) {
    self.init(Builtin.truncOrBitCast_Int16_Int8(bits._value))
  }

  @_transparent
  public // transparent
  var _lowWord: UInt {
    return UInt(
      Builtin.zextOrBitCast_Int8_Int16(_value)
    )
  }
}

extension UInt8.Words {
    @inlinable
    public var count: Int {
      return (8 + 16 - 1) / 16
    }

    @inlinable
    public subscript(position: Int) -> UInt {
      get {
        let shift = UInt(position._value) &* 16
        return (_value &>> UInt8(_truncatingBits: shift))._lowWord
      }
    }
}

extension Float {
    // We "shouldn't" need this, but the typechecker barfs on an expression
  // in the test suite without it.
  // If replaced with @inline(__always) the init no longer gets
  // inlined in -Onone and this breaks the abi_v7k test in a subtle way.
  @_transparent
  public init(_ v: Int) {
    _value = Builtin.sitofp_Int16_FPIEEE32(v._value)
  }

  // Fast-path for conversion when the source is representable as a 64-bit int,
  // falling back on the generic _convert operation otherwise.
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init<Source : BinaryInteger>(_ value: Source) {
    if value.bitWidth <= 16 {
      if Source.isSigned {
        let asInt = Int(truncatingIfNeeded: value)
        _value = Builtin.sitofp_Int16_FPIEEE32(asInt._value)
      } else {
        let asUInt = Int(truncatingIfNeeded: value)
        _value = Builtin.uitofp_Int16_FPIEEE32(asUInt._value)
      }
    } else {
      self = Float._convert(from: value).value
    }
  }
}

extension Float16 {
  // We "shouldn't" need this, but the typechecker barfs on an expression
  // in the test suite without it.
  // If replaced with @inline(__always) the init no longer gets
  // inlined in -Onone and this breaks the abi_v7k test in a subtle way.
  @_transparent
  public init(_ v: Int) {
    _value = Builtin.sitofp_Int16_FPIEEE16(v._value)
  }

  // Fast-path for conversion when the source is representable as int,
  // falling back on the generic _convert operation otherwise.
  @inlinable // FIXME(inline-always)
  @inline(__always)
  public init<Source: BinaryInteger>(_ value: Source) {
    if value.bitWidth <= 16 {
      if Source.isSigned {
        let asInt = Int(truncatingIfNeeded: value)
        _value = Builtin.sitofp_Int16_FPIEEE16(asInt._value)
      } else {
        let asUInt = UInt(truncatingIfNeeded: value)
        _value = Builtin.uitofp_Int16_FPIEEE16(asUInt._value)
      }
    } else {
      // TODO: we can do much better than the generic _convert here for Float
      // and Double by pulling out the high-order 32/64b of the integer, ORing
      // in a sticky bit, and then using the builtin.
      self = Float16._convert(from: value).value
    }
  }
}