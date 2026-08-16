// this version of uSwift is currently hard coded with AVR in mind, meaning 16 bit words
// Builtin.Word should be 16 bit

/*
binaryArithmetic = {
  'Numeric' : [
    struct(operator='+', name='adding',      firstArg='_',  llvmName='add', kind='+'),
    struct(operator='-', name='subtracting', firstArg='_',  llvmName='sub', kind='-'),
    struct(operator='*', name='multiplied',  firstArg='by', llvmName='mul', kind='*'),
  ],
  'BinaryInteger' : [
    struct(operator='/', name='divided',     firstArg='by', llvmName='div', kind='/'),
    struct(operator='%', name='remainder',   firstArg='dividingBy', llvmName='rem', kind='/'),
  ],
}
*/

/*

The core of all math based types.

AdditiveArithmetic is the most basic protocol, the set of types that conform to this all have a zero and
define addition and subtraction operators. In theory things like colors could conform to this. It is not
exactly the same as mathematical operators, associativity and commutabiility guarantees are not implied.

Numeric is the base protocol for all microswift standard library types, floating point and integer.
They define multiplication, absolute magnitude and must be Comprarable.

SignedNumeric types can be negative, this includes all floating point types and all signed integers.


for the base protocols of integers, see FixedWidth and BinaryInteger
for the base 

*/


public protocol AdditiveArithmetic : Equatable {
  static var zero: Self { get }
  static func +=(lhs: inout Self, rhs: Self)
  static func -(lhs: Self, rhs: Self) -> Self
  static func -=(lhs: inout Self, rhs: Self)
  static func +(lhs: Self, rhs: Self) -> Self
}

public extension AdditiveArithmetic where Self : ExpressibleByIntegerLiteral {
  @inlinable @inline(__always)
  static var zero: Self {
    return 0
  }
}

public extension AdditiveArithmetic {
  @_alwaysEmitIntoClient
  static func +=(lhs: inout Self, rhs: Self) {
    lhs = lhs + rhs
  }

  @_alwaysEmitIntoClient
  static func -=(lhs: inout Self, rhs: Self) {
    lhs = lhs - rhs
  }
}

public protocol Numeric : AdditiveArithmetic, Comparable, ExpressibleByIntegerLiteral {
  associatedtype Magnitude : Numeric

  var magnitude: Magnitude { get }

  static func *(lhs: Self, rhs: Self) -> Self

  static func *=(lhs: inout Self, rhs: Self)
}

public protocol SignedNumeric : Numeric {
  static prefix func - (_ operand: Self) -> Self
  mutating func negate()
}

extension SignedNumeric {
  @_transparent
  public static prefix func - (_ operand: Self) -> Self {
    var result = operand
    result.negate()
    return result
  }

  @_transparent
  public mutating func negate() {
    self = 0 - self
  }
}

@inlinable
public func abs<T : SignedNumeric & Comparable>(_ x: T) -> T {
  if T.self == T.Magnitude.self {
    return unsafeBitCast(x.magnitude, to: T.self)
  }

  return x < (0 as T) ? -x : x
}

