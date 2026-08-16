// The floating point protocol covers IEEE 754 floating point
// behavior and structure.
// Theoretically this allows any radix, such as 10. In reality
// all swift stdlib implementations use binary radix.
// See the daughter protocol BinaryFloatingPoint for detailed implementations.
// All types in our stdlib implement BinaryFloatingPoint.

public typealias _MaxBuiltinFloatType = Builtin.FPIEEE64

public protocol _ExpressibleByBuiltinFloatLiteral {
  init(_builtinFloatLiteral value: _MaxBuiltinFloatType)
}

public protocol ExpressibleByFloatLiteral {
  associatedtype FloatLiteralType : _ExpressibleByBuiltinFloatLiteral
  init(floatLiteral value: FloatLiteralType)
}

@frozen
public enum FloatingPointSign: Int {
  case plus
  case minus

  @inlinable
  public init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .plus
    case 1: self = .minus
    default: return nil
    }
  }

  @inlinable
  public var rawValue: Int {
    switch self {
    case .plus: return 0
    case .minus: return 1
    }
  }

  @_transparent
  @inlinable
  public static func ==(a: FloatingPointSign, b: FloatingPointSign) -> Bool {
    return a.rawValue == b.rawValue
  }

  @inlinable
  public var hashValue: Int { return rawValue.hashValue }

  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(rawValue)
  }

  @inlinable
  public func _rawHashValue(seed: Int) -> Int {
    return rawValue._rawHashValue(seed: seed)
  }
}

@frozen
public enum FloatingPointClassification {
  case signalingNaN
  case quietNaN
  case negativeInfinity
  case negativeNormal
  case negativeSubnormal
  case negativeZero
  case positiveZero
  case positiveSubnormal
  case positiveNormal
  case positiveInfinity
}

public enum FloatingPointRoundingRule {
  case toNearestOrAwayFromZero
  case toNearestOrEven
  case up
  case down
  case towardZero
  case awayFromZero
}

public protocol FloatingPoint : SignedNumeric, Strideable, Hashable
                                where Magnitude == Self {
  associatedtype Exponent: SignedInteger
  init(sign: FloatingPointSign, exponent: Exponent, significand: Self)
  init(signOf: Self, magnitudeOf: Self)
  init(_ value: Int)
  init<Source : BinaryInteger>(_ value: Source)
  init?<Source : BinaryInteger>(exactly value: Source)
  static var radix: Int { get }
  static var nan: Self { get }
  static var signalingNaN: Self { get }
  static var infinity: Self { get }
  static var greatestFiniteMagnitude: Self { get }
  static var pi: Self { get }
  var ulp: Self { get }
  static var ulpOfOne: Self { get }
  static var leastNormalMagnitude: Self { get }
  static var leastNonzeroMagnitude: Self { get }
  var sign: FloatingPointSign { get }
  var exponent: Exponent { get }
  var significand: Self { get }
  override static func +(lhs: Self, rhs: Self) -> Self
  override static func +=(lhs: inout Self, rhs: Self)
  override static prefix func - (_ operand: Self) -> Self
  override mutating func negate()
  override static func -(lhs: Self, rhs: Self) -> Self
  override static func -=(lhs: inout Self, rhs: Self)
  override static func *(lhs: Self, rhs: Self) -> Self
  override static func *=(lhs: inout Self, rhs: Self)
  static func /(lhs: Self, rhs: Self) -> Self
  static func /=(lhs: inout Self, rhs: Self)
  func remainder(dividingBy other: Self) -> Self
  mutating func formRemainder(dividingBy other: Self)
  func truncatingRemainder(dividingBy other: Self) -> Self
  mutating func formTruncatingRemainder(dividingBy other: Self)
  func squareRoot() -> Self
  mutating func formSquareRoot()
  func addingProduct(_ lhs: Self, _ rhs: Self) -> Self
  mutating func addProduct(_ lhs: Self, _ rhs: Self)
  static func minimum(_ x: Self, _ y: Self) -> Self
  static func maximum(_ x: Self, _ y: Self) -> Self
  static func minimumMagnitude(_ x: Self, _ y: Self) -> Self
  static func maximumMagnitude(_ x: Self, _ y: Self) -> Self
  func rounded(_ rule: FloatingPointRoundingRule) -> Self
  mutating func round(_ rule: FloatingPointRoundingRule)
  var nextUp: Self { get }
  var nextDown: Self { get }
  func isEqual(to other: Self) -> Bool
  func isLess(than other: Self) -> Bool
  func isLessThanOrEqualTo(_ other: Self) -> Bool
  func isTotallyOrdered(belowOrEqualTo other: Self) -> Bool
  var isNormal: Bool { get }
  var isFinite: Bool { get }
  var isZero: Bool { get }
  var isSubnormal: Bool { get }
  var isInfinite: Bool { get }
  var isNaN: Bool { get }
  var isSignalingNaN: Bool { get }
  var floatingPointClass: FloatingPointClassification { get }
  var isCanonical: Bool { get }
}

extension FloatingPoint {
  @_transparent
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.isEqual(to: rhs)
  }

  @_transparent
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.isLess(than: rhs)
  }

  @_transparent
  public static func <= (lhs: Self, rhs: Self) -> Bool {
    return lhs.isLessThanOrEqualTo(rhs)
  }

  @_transparent
  public static func > (lhs: Self, rhs: Self) -> Bool {
    return rhs.isLess(than: lhs)
  }

  @_transparent
  public static func >= (lhs: Self, rhs: Self) -> Bool {
    return rhs.isLessThanOrEqualTo(lhs)
  }
}

extension FloatingPoint {

  @inlinable // FIXME(sil-serialize-all)
  public static var ulpOfOne: Self {
    return (1 as Self).ulp
  }

  @_transparent
  public func rounded(_ rule: FloatingPointRoundingRule) -> Self {
    var lhs = self
    lhs.round(rule)
    return lhs
  }

  @_transparent
  public func rounded() -> Self {
    return rounded(.toNearestOrAwayFromZero)
  }

  @_transparent
  public mutating func round() {
    round(.toNearestOrAwayFromZero)
  }

  @inlinable // FIXME(inline-always)
  public var nextDown: Self {
    @inline(__always)
    get {
      return -(-self).nextUp
    }
  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public func truncatingRemainder(dividingBy other: Self) -> Self {
    var lhs = self
    lhs.formTruncatingRemainder(dividingBy: other)
    return lhs
  }

  @inlinable // FIXME(inline-always)
  @inline(__always)
  public func remainder(dividingBy other: Self) -> Self {
    var lhs = self
    lhs.formRemainder(dividingBy: other)
    return lhs
  }

  @_transparent
  public func squareRoot( ) -> Self {
    var lhs = self
    lhs.formSquareRoot( )
    return lhs
  }

  @_transparent
  public func addingProduct(_ lhs: Self, _ rhs: Self) -> Self {
    var addend = self
    addend.addProduct(lhs, rhs)
    return addend
  }

  @inlinable
  public static func minimum(_ x: Self, _ y: Self) -> Self {
    if x.isSignalingNaN || y.isSignalingNaN {
      //  Produce a quiet NaN matching platform arithmetic behavior.
      return x + y
    }
    if x <= y || y.isNaN { return x }
    return y
  }

  @inlinable
  public static func maximum(_ x: Self, _ y: Self) -> Self {
    if x.isSignalingNaN || y.isSignalingNaN {
      //  Produce a quiet NaN matching platform arithmetic behavior.
      return x + y
    }
    if x > y || y.isNaN { return x }
    return y
  }

  @inlinable
  public static func minimumMagnitude(_ x: Self, _ y: Self) -> Self {
    if x.isSignalingNaN || y.isSignalingNaN {
      //  Produce a quiet NaN matching platform arithmetic behavior.
      return x + y
    }
    if x.magnitude <= y.magnitude || y.isNaN { return x }
    return y
  }

  @inlinable
  public static func maximumMagnitude(_ x: Self, _ y: Self) -> Self {
    if x.isSignalingNaN || y.isSignalingNaN {
      //  Produce a quiet NaN matching platform arithmetic behavior.
      return x + y
    }
    if x.magnitude > y.magnitude || y.isNaN { return x }
    return y
  }

  @inlinable
  public var floatingPointClass: FloatingPointClassification {
    if isSignalingNaN { return .signalingNaN }
    if isNaN { return .quietNaN }
    if isInfinite { return sign == .minus ? .negativeInfinity : .positiveInfinity }
    if isNormal { return sign == .minus ? .negativeNormal : .positiveNormal }
    if isSubnormal { return sign == .minus ? .negativeSubnormal : .positiveSubnormal }
    return sign == .minus ? .negativeZero : .positiveZero
  }
}
