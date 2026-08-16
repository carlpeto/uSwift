// the core protocol for integer types
// this defines the core operations any integer type must support
// whether fixed width or not, and implies they are stored in binary
// (note: at this time, all integer types in microswift are fixed width)

public protocol BinaryInteger : Numeric, Hashable, Strideable
  where Magnitude : BinaryInteger, Magnitude.Magnitude == Magnitude
{
  // init<T : BinaryFloatingPoint>(_ source: T)

  init<T : BinaryInteger>(_ source: T)
  init<T : BinaryInteger>(truncatingIfNeeded source: T)
  static var isSigned: Bool { get }
  var _lowWord: UInt { get }
  var bitWidth: Int { get }

  associatedtype Words : RandomAccessCollection
    where Words.Element == UInt, Words.Index == Int

  var words: Words { get }

  init<T : BinaryInteger>(clamping source: T)
  static func /(lhs: Self, rhs: Self) -> Self
  static func /=(lhs: inout Self, rhs: Self)
  static func %(lhs: Self, rhs: Self) -> Self
  static func %=(lhs: inout Self, rhs: Self)
  override static func +(lhs: Self, rhs: Self) -> Self
  override static func +=(lhs: inout Self, rhs: Self)
  override static func -(lhs: Self, rhs: Self) -> Self
  override static func -=(lhs: inout Self, rhs: Self)
  override static func *(lhs: Self, rhs: Self) -> Self
  override static func *=(lhs: inout Self, rhs: Self)
  static prefix func ~ (_ x: Self) -> Self

  static func &(lhs: Self, rhs: Self) -> Self
  static func &=(lhs: inout Self, rhs: Self)
  static func |(lhs: Self, rhs: Self) -> Self
  static func |=(lhs: inout Self, rhs: Self)
  static func ^(lhs: Self, rhs: Self) -> Self
  static func ^=(lhs: inout Self, rhs: Self)
  static func >> <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self
  static func >>= <RHS: BinaryInteger>(lhs: inout Self, rhs: RHS)
  static func << <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self
  static func <<=<RHS: BinaryInteger>(lhs: inout Self, rhs: RHS)

  init?<T : BinaryFloatingPoint>(exactly source: T)
  init<T : BinaryFloatingPoint>(_ source: T)

  func _binaryLogarithm() -> Int
  var trailingZeroBitCount: Int { get }

  func quotientAndRemainder(dividingBy rhs: Self)
    -> (quotient: Self, remainder: Self)

  func isMultiple(of other: Self) -> Bool
  func signum() -> Self
}

extension BinaryInteger {
  @available(*, unavailable, message: "truncatingBitPattern: is obsolete, use truncatingIfNeeded:")
  init<T : BinaryInteger>(truncatingBitPattern source: T) {
    self = 0
  }

  @_transparent
  public init() {
    self = 0
  }

  @inlinable
  public func signum() -> Self {
    return (self > (0 as Self) ? 1 : 0) - (self < (0 as Self) ? 1 : 0)
  }

  // @_transparent
  // public var _lowWord: UInt {
  //   var it = words.makeIterator()
  //   return it.next() ?? 0
  // }

  @inlinable
  public func _binaryLogarithm() -> Int {
    _precondition(self > (0 as Self))
    var (quotient, remainder) =
      (bitWidth &- 1).quotientAndRemainder(dividingBy: UInt.bitWidth)
    remainder = remainder &+ 1
    var word = UInt(truncatingIfNeeded: self >> (bitWidth &- remainder))
    // If, internally, a variable-width binary integer uses digits of greater
    // bit width than that of Magnitude.Words.Element (i.e., UInt), then it is
    // possible that `word` could be zero. Additionally, a signed variable-width
    // binary integer may have a leading word that is zero to store a clear sign
    // bit.
    while word == 0 {
      quotient = quotient &- 1
      remainder = remainder &+ UInt.bitWidth
      word = UInt(truncatingIfNeeded: self >> (bitWidth &- remainder))
    }
    // Note that the order of operations below is important to guarantee that
    // we won't overflow.
    return UInt.bitWidth &* quotient &+
        (UInt.bitWidth &- (word.leadingZeroBitCount &+ 1))
  }

  @inlinable
  public func quotientAndRemainder(dividingBy rhs: Self)
    -> (quotient: Self, remainder: Self) {
    return (self / rhs, self % rhs)
  }

  @inlinable
  public func isMultiple(of other: Self) -> Bool {
    // Nothing but zero is a multiple of zero.
    if other == 0 { return self == 0 }
    // Do the test in terms of magnitude, which guarantees there are no other
    // edge cases. If we write this as `self % other` instead, it could trap
    // for types that are not symmetric around zero.
    return self.magnitude % other.magnitude == 0
  }

//===----------------------------------------------------------------------===//
//===--- Homogeneous ------------------------------------------------------===//
//===----------------------------------------------------------------------===//
  @_transparent
  public static func & (lhs: Self, rhs: Self) -> Self {
    var lhs = lhs
    lhs &= rhs
    return lhs
  }

  @_transparent
  public static func | (lhs: Self, rhs: Self) -> Self {
    var lhs = lhs
    lhs |= rhs
    return lhs
  }

  @_transparent
  public static func ^ (lhs: Self, rhs: Self) -> Self {
    var lhs = lhs
    lhs ^= rhs
    return lhs
  }

//===----------------------------------------------------------------------===//
//===--- Heterogeneous non-masking shift in terms of shift-assignment -----===//
//===----------------------------------------------------------------------===//
  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func >> <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self {
    var r = lhs
    r >>= rhs
    return r
  }

  @_semantics("optimize.sil.specialize.generic.partial.never")
  @_transparent
  public static func << <RHS: BinaryInteger>(lhs: Self, rhs: RHS) -> Self {
    var r = lhs
    r <<= rhs
    return r
  }
}

// extension BinaryInteger {
//   // @_transparent
//   // public init() {
//   //   self = 0
//   // }

//   @inlinable // FIXME(sil-serialize-all)
//   @inline(__always)
//   public static func == <
//     Other : BinaryInteger
//   >(lhs: Self, rhs: Other) -> Bool {
//     let lhsNegative = Self.isSigned && lhs < (0 as Self)
//     let rhsNegative = Other.isSigned && rhs < (0 as Other)

//     if lhsNegative != rhsNegative { return false }

//     // Here we know the values are of the same sign.
//     //
//     // There are a few possible scenarios from here:
//     //
//     // 1. Both values are negative
//     //  - If one value is strictly wider than the other, then it is safe to
//     //    convert to the wider type.
//     //  - If the values are of the same width, it does not matter which type we
//     //    choose to convert to as the values are already negative, and thus
//     //    include the sign bit if two's complement representation already.
//     // 2. Both values are non-negative
//     //  - If one value is strictly wider than the other, then it is safe to
//     //    convert to the wider type.
//     //  - If the values are of the same width, than signedness matters, as not
//     //    unsigned types are 'wider' in a sense they don't need to 'waste' the
//     //    sign bit. Therefore it is safe to convert to the unsigned type.

//     if lhs.bitWidth < rhs.bitWidth {
//       return Other(truncatingIfNeeded: lhs) == rhs
//     }
//     if lhs.bitWidth > rhs.bitWidth {
//       return lhs == Self(truncatingIfNeeded: rhs)
//     }

//     if Self.isSigned {
//       return Other(truncatingIfNeeded: lhs) == rhs
//     }
//     return lhs == Self(truncatingIfNeeded: rhs)
//   }

//   @_transparent
//   public static func != <
//     Other : BinaryInteger
//   >(lhs: Self, rhs: Other) -> Bool {
//     return !(lhs == rhs)
//   }
// }

extension BinaryInteger {
  @inlinable
  @inline(__always)
  public func distance(to other: Self) -> Int {
    if !Self.isSigned {
      if self > other {
        if let result = Int(exactly: self - other) {
          return -result
        }
      } else {
        if let result = Int(exactly: other - self) {
          return result
        }
      }
    } else {
      let isNegative = self < (0 as Self)
      if isNegative == (other < (0 as Self)) {
        if let result = Int(exactly: other - self) {
          return result
        }
      } else {
        if let result = Int(exactly: self.magnitude + other.magnitude) {
          return isNegative ? result : -result
        }
      }
    }
    _precondition(false)
    return 0
  }

  @inlinable
  @inline(__always)
  public func advanced(by n: Int) -> Self {
    if !Self.isSigned {
      return n < (0 as Int)
        ? self - Self(-n)
        : self + Self(n)
    }
    if (self < (0 as Self)) == (n < (0 as Self)) {
      return self + Self(n)
    }
    return self.magnitude < n.magnitude
      ? Self(Int(self) + n)
      : self + Self(n)
  }
}

//===----------------------------------------------------------------------===//
//===--- Heterogeneous comparison -----------------------------------------===//
//===----------------------------------------------------------------------===//

extension BinaryInteger {
  @_transparent
  public static func == <
    Other : BinaryInteger
  >(lhs: Self, rhs: Other) -> Bool {
    let lhsNegative = Self.isSigned && lhs < (0 as Self)
    let rhsNegative = Other.isSigned && rhs < (0 as Other)

    if lhsNegative != rhsNegative { return false }

    // Here we know the values are of the same sign.
    //
    // There are a few possible scenarios from here:
    //
    // 1. Both values are negative
    //  - If one value is strictly wider than the other, then it is safe to
    //    convert to the wider type.
    //  - If the values are of the same width, it does not matter which type we
    //    choose to convert to as the values are already negative, and thus
    //    include the sign bit if two's complement representation already.
    // 2. Both values are non-negative
    //  - If one value is strictly wider than the other, then it is safe to
    //    convert to the wider type.
    //  - If the values are of the same width, than signedness matters, as not
    //    unsigned types are 'wider' in a sense they don't need to 'waste' the
    //    sign bit. Therefore it is safe to convert to the unsigned type.

    if lhs.bitWidth < rhs.bitWidth {
      return Other(truncatingIfNeeded: lhs) == rhs
    }
    if lhs.bitWidth > rhs.bitWidth {
      return lhs == Self(truncatingIfNeeded: rhs)
    }

    if Self.isSigned {
      return Other(truncatingIfNeeded: lhs) == rhs
    }
    return lhs == Self(truncatingIfNeeded: rhs)
  }

  @_transparent
  public static func != <
    Other : BinaryInteger
  >(lhs: Self, rhs: Other) -> Bool {
    return !(lhs == rhs)
  }

  @_transparent
  public static func < <Other : BinaryInteger>(lhs: Self, rhs: Other) -> Bool {
    let lhsNegative = Self.isSigned && lhs < (0 as Self)
    let rhsNegative = Other.isSigned && rhs < (0 as Other)
    if lhsNegative != rhsNegative { return lhsNegative }

    if lhs == (0 as Self) && rhs == (0 as Other) { return false }

    // if we get here, lhs and rhs have the same sign. If they're negative,
    // then Self and Other are both signed types, and one of them can represent
    // values of the other type. Otherwise, lhs and rhs are positive, and one
    // of Self, Other may be signed and the other unsigned.

    let rhsAsSelf = Self(truncatingIfNeeded: rhs)
    let rhsAsSelfNegative = rhsAsSelf < (0 as Self)


    // Can we round-trip rhs through Other?
    if Other(truncatingIfNeeded: rhsAsSelf) == rhs &&
      // This additional check covers the `Int8.max < (128 as UInt8)` case.
      // Since the types are of the same width, init(truncatingIfNeeded:)
      // will result in a simple bitcast, so that rhsAsSelf would be -128, and
      // `lhs < rhsAsSelf` will return false.
      // We basically guard against that bitcast by requiring rhs and rhsAsSelf
      // to be the same sign.
      rhsNegative == rhsAsSelfNegative {
      return lhs < rhsAsSelf
    }

    return Other(truncatingIfNeeded: lhs) < rhs
  }

  @_transparent
  public static func <= <Other : BinaryInteger>(lhs: Self, rhs: Other) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= <Other : BinaryInteger>(lhs: Self, rhs: Other) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > <Other : BinaryInteger>(lhs: Self, rhs: Other) -> Bool {
    return rhs < lhs
  }
}

//===----------------------------------------------------------------------===//
//===--- Ambiguity breakers -----------------------------------------------===//
//
// These two versions of the operators are not ordered with respect to one
// another, but the compiler choses the second one, and that results in infinite
// recursion.
//
//     <T : Comparable>(T, T) -> Bool
//     <T : BinaryInteger, U : BinaryInteger>(T, U) -> Bool
//
// so we define:
//
//     <T : BinaryInteger>(T, T) -> Bool
//
//===----------------------------------------------------------------------===//

extension BinaryInteger {
  @_transparent
  public static func != (lhs: Self, rhs: Self) -> Bool {
    return !(lhs == rhs)
  }

  @_transparent
  public static func <= (lhs: Self, rhs: Self) -> Bool {
    return !(rhs < lhs)
  }

  @_transparent
  public static func >= (lhs: Self, rhs: Self) -> Bool {
    return !(lhs < rhs)
  }

  @_transparent
  public static func > (lhs: Self, rhs: Self) -> Bool {
    return rhs < lhs
  }
}