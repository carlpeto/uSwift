public protocol ExpressibleByNilLiteral: ~Copyable, ~Escapable {
  /// Creates an instance initialized with `nil`.
  @lifetime(immortal)
  init(nilLiteral: ())
}

public protocol _ExpressibleByBuiltinIntegerLiteral {
  init(_builtinIntegerLiteral value: Builtin.IntLiteral)
}

public protocol ExpressibleByIntegerLiteral {
  associatedtype IntegerLiteralType : _ExpressibleByBuiltinIntegerLiteral
  init(integerLiteral value: IntegerLiteralType)
}

public protocol _ExpressibleByBuiltinBooleanLiteral {
  init(_builtinBooleanLiteral value: Builtin.Int1)
}

public protocol ExpressibleByBooleanLiteral {
  associatedtype BooleanLiteralType : _ExpressibleByBuiltinBooleanLiteral
  init(booleanLiteral value: BooleanLiteralType)
}

extension ExpressibleByIntegerLiteral
  where Self : _ExpressibleByBuiltinIntegerLiteral {
  @_transparent
  public init(integerLiteral value: Self) {
    self = value
  }
}