@frozen
public struct Bool {
  @usableFromInline
  internal var _value: Builtin.Int1

  @_transparent
  public init() {
    let zero: Int8 = 0
    self._value = Builtin.trunc_Int8_Int1(zero._value)
  }

  @usableFromInline @_transparent
  internal init(_ v: Builtin.Int1) { self._value = v }
  
  @inlinable
  public init(_ value: Bool) {
    self = value
  }
}

extension Bool : _ExpressibleByBuiltinBooleanLiteral, ExpressibleByBooleanLiteral {
  @_transparent
  public init(_builtinBooleanLiteral value: Builtin.Int1) {
    self._value = value
  }

  @_transparent
  public init(booleanLiteral value: Bool) {
    self = value
  }
}

extension Bool {
  // This is a magic entry point known to the compiler.
  @_transparent
  public // COMPILER_INTRINSIC
  func _getBuiltinLogicValue() -> Builtin.Int1 {
    return _value
  }
}

@_transparent
public // COMPILER_INTRINSIC
func _getBool(_ v: Builtin.Int1) -> Bool { return Bool(v) }

extension Bool: Equatable {
  @_transparent
  public static func == (lhs: Bool, rhs: Bool) -> Bool {
    return Bool(Builtin.cmp_eq_Int1(lhs._value, rhs._value))
  }
}

extension Bool: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine((self ? 1 : 0) as UInt8)
  }
}

extension Bool {
  @_transparent
  public static prefix func ! (a: Bool) -> Bool {
    return Bool(Builtin.xor_Int1(a._value, Bool(true)._value))
  }
}

extension Bool {
  @_transparent
  @inline(__always)
  public static func && (lhs: Bool, rhs: @autoclosure () throws -> Bool) rethrows
      -> Bool {
    return lhs ? try rhs() : false
  }

  @_transparent
  @inline(__always)
  public static func || (lhs: Bool, rhs: @autoclosure () throws -> Bool) rethrows
      -> Bool {
    return lhs ? true : try rhs()
  }
}

extension Bool {
  @inlinable
  public mutating func toggle() {
    self = !self
  }
}
