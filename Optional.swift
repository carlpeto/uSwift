@frozen
public enum Optional<Wrapped: ~Copyable & ~Escapable>: ~Copyable, ~Escapable {
  case none
  case some(Wrapped)
}

extension Optional: Copyable where Wrapped: Copyable & ~Escapable {}

extension Optional: Escapable where Wrapped: Escapable & ~Copyable {}

extension Optional: BitwiseCopyable
where Wrapped: BitwiseCopyable & ~Escapable {}

extension Optional: Sendable where Wrapped: ~Copyable & ~Escapable & Sendable {}

extension Optional where Wrapped: ~Copyable {
  /// Creates an instance that stores the given value.
  @_transparent
  @_preInverseGenerics
  public init(_ value: consuming Wrapped) {
    // FIXME: Merge this with the generalization below.
    // This is the original initializer, preserved to avoid breaking source
    // compatibility with clients that use the `Optional.init` syntax to create
    // a function reference. The ~Escapable generalization is currently breaking
    // that. (rdar://147533059)
    self = .some(value)
  }
}

extension Optional where Wrapped: ~Copyable & ~Escapable {
  /// Creates an instance that stores the given value.
  @_transparent
  @_alwaysEmitIntoClient
  @lifetime(copy value)
  public init(_ value: consuming Wrapped) {
    // FIXME: Merge this into the original entry above.
    self = .some(value)
  }
}

extension Optional where Wrapped: ~Copyable {
  // FIXME(NCG): Make this public.
  @_alwaysEmitIntoClient
  public consuming func _consumingMap<U: ~Copyable, E: Error>(
    _ transform: (consuming Wrapped) throws(E) -> U
  ) throws(E) -> U? {
    switch consume self {
    case .some(let y):
      return .some(try transform(y))
    case .none:
      return .none
    }
  }

  // FIXME(NCG): Make this public.
  @_alwaysEmitIntoClient
  public borrowing func _borrowingMap<U: ~Copyable, E: Error>(
    _ transform: (borrowing Wrapped) throws(E) -> U
  ) throws(E) -> U? {
    switch self {
    case .some(let y):
      return .some(try transform(y))
    case .none:
      return .none
    }
  }
}

@_preInverseGenerics
extension Optional: ExpressibleByNilLiteral
where Wrapped: ~Copyable & ~Escapable {
  /// Creates an instance initialized with `nil`.
  ///
  /// Do not call this initializer directly. It is used by the compiler when you
  /// initialize an `Optional` instance with a `nil` literal. For example:
  ///
  ///     var i: Index? = nil
  ///
  /// In this example, the assignment to the `i` variable calls this
  /// initializer behind the scenes.
  @_transparent
  @_preInverseGenerics
  @lifetime(immortal)
  public init(nilLiteral: ()) {
    self = .none
  }
}

extension Optional { //: ExpressibleByNilLiteral {
  // @_transparent
  // public init(_ some: Wrapped) { self = .some(some) }

  @_alwaysEmitIntoClient
  public func map<E: Error, U: ~Copyable>(
    _ transform: (Wrapped) throws(E) -> U
  ) throws(E) -> U? {
    switch self {
    case .some(let y):
      return .some(try transform(y))
    case .none:
      return .none
    }
  }

  @inlinable
  public func map<U>(
    _ transform: (Wrapped) throws -> U
  ) rethrows -> U? {
    switch self {
    case .some(let y):
      return .some(try transform(y))
    case .none:
      return .none
    }
  }

  @inlinable
  public func flatMap<U>(
    _ transform: (Wrapped) throws -> U?
  ) rethrows -> U? {
    switch self {
    case .some(let y):
      return try transform(y)
    case .none:
      return .none
    }
  }

  // @_transparent
  // public init(nilLiteral: ()) {
  //   self = .none
  // }

  // @inlinable
  // public var unsafelyUnwrapped: Wrapped {
  //   @inline(__always)
  //   get {
  //     if let x = self {
  //       return x
  //     }
  //     _debugPreconditionFailure()
  //   }
  // }
}

@frozen
public struct _OptionalNilComparisonType: ExpressibleByNilLiteral {
  /// Create an instance initialized with `nil`.
  @_transparent
  public init(nilLiteral: ()) {
  }
}

extension Optional where Wrapped: ~Escapable {
  /// The wrapped value of this instance, unwrapped without checking whether
  /// the instance is `nil`.
  ///
  /// The `unsafelyUnwrapped` property provides the same value as the forced
  /// unwrap operator (postfix `!`). However, in optimized builds (`-O`), no
  /// check is performed to ensure that the current instance actually has a
  /// value. Accessing this property in the case of a `nil` value is a serious
  /// programming error and could lead to undefined behavior or a runtime
  /// error.
  ///
  /// In debug builds (`-Onone`), the `unsafelyUnwrapped` property has the same
  /// behavior as using the postfix `!` operator and triggers a runtime error
  /// if the instance is `nil`.
  ///
  /// The `unsafelyUnwrapped` property is recommended over calling the
  /// `unsafeBitCast(_:)` function because the property is more restrictive
  /// and because accessing the property still performs checking in debug
  /// builds.
  ///
  /// - Warning: This property trades safety for performance.  Use
  ///   `unsafelyUnwrapped` only when you are confident that this instance
  ///   will never be equal to `nil` and only after you've tried using the
  ///   postfix `!` operator.
  @inlinable
  @_preInverseGenerics
  @unsafe
  public var unsafelyUnwrapped: Wrapped {
    // FIXME: Generalize this for ~Copyable wrapped types. Note that the current
    // implementation is copying the value, so that generalization will need to
    // be emitted into clients -- `@_preInverseGenerics` will not cut it.
    @inline(__always)
    @lifetime(copy self)
    get {
      if let x = self {
        return x
      }
      _debugPreconditionFailure()
    }
  }
}

extension Optional where Wrapped: ~Copyable & ~Escapable {
  // FIXME(NCG): Do we want this? It seems like we do. Make this public.
  @_alwaysEmitIntoClient
  @lifetime(copy self)
  public consuming func _consumingUnsafelyUnwrap() -> Wrapped {
    switch consume self {
    case .some(let x):
      return x
    case .none:
      _debugPreconditionFailure()
    }
  }
}

extension Optional where Wrapped: ~Escapable {
  /// - Returns: `unsafelyUnwrapped`.
  ///
  /// This version is for internal stdlib use; it avoids any checking
  /// overhead for users, even in Debug builds.
  @inlinable
  @_preInverseGenerics
  internal var _unsafelyUnwrappedUnchecked: Wrapped {
    @inline(__always)
    @lifetime(copy self)
    get {
      if let x = self {
        return x
      }
      _internalInvariantFailure()
    }
  }
}

extension Optional where Wrapped: ~Copyable {
  // FIXME(NCG): Make this public.
  @_alwaysEmitIntoClient
  public consuming func _consumingFlatMap<U: ~Copyable, E: Error>(
    _ transform: (consuming Wrapped) throws(E) -> U?
  ) throws(E) -> U? {
    switch consume self {
    case .some(let y):
      return try transform(consume y)
    case .none:
      return .none
    }
  }

  // FIXME(NCG): Make this public.
  @_alwaysEmitIntoClient
  public func _borrowingFlatMap<U: ~Copyable, E: Error>(
    _ transform: (borrowing Wrapped) throws(E) -> U?
  ) throws(E) -> U? {
    switch self {
    case .some(let y):
      return try transform(y)
    case .none:
      return .none
    }
  }
}

extension Optional where Wrapped: ~Copyable & ~Escapable {
  /// - Returns: `unsafelyUnwrapped`.
  ///
  /// This version is for internal stdlib use; it avoids any checking
  /// overhead for users, even in Debug builds.
  @_alwaysEmitIntoClient
  @lifetime(copy self)
  internal consuming func _consumingUncheckedUnwrapped() -> Wrapped {
    if let x = self {
      return x
    }
    _internalInvariantFailure()
  }
}

extension Optional where Wrapped: ~Copyable & ~Escapable {
  /// Takes the wrapped value being stored in this instance and returns it while
  /// also setting the instance to `nil`. If there is no value being stored in
  /// this instance, this returns `nil` instead.
  ///
  ///     var numberOfShoes: Int? = 34
  ///
  ///     if let numberOfShoes = numberOfShoes.take() {
  ///       print(numberOfShoes)
  ///       // Prints "34"
  ///     }
  ///
  ///     print(numberOfShoes)
  ///     // Prints "nil"
  ///
  /// - Returns: The wrapped value being stored in this instance. If this
  ///   instance is `nil`, returns `nil`.
  @_alwaysEmitIntoClient
  @lifetime(copy self)
  public mutating func take() -> Self {
    let result = consume self
    self = nil
    return result
  }
}

// extension Optional: Equatable where Wrapped: Equatable {
//   @_transparent
//   public static func ==(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
//     switch (lhs, rhs) {
//     case let (l?, r?):
//       return l == r
//     case (nil, nil):
//       return true
//     default:
//       return false
//     }
//   }
// }

extension Optional where Wrapped: ~Copyable & ~Escapable {
  @_transparent
  @_preInverseGenerics
  public static func ~=(
    lhs: _OptionalNilComparisonType,
    rhs: borrowing Wrapped?
  ) -> Bool {
    switch rhs {
    case .some:
      return false
    case .none:
      return true
    }
  }

  @_transparent
  @_preInverseGenerics
  public static func ==(
    lhs: borrowing Wrapped?,
    rhs: _OptionalNilComparisonType
  ) -> Bool {
    switch lhs {
    case .some:
      return false
    case .none:
      return true
    }
  }

  @_transparent
  @_preInverseGenerics
  public static func !=(
    lhs: borrowing Wrapped?,
    rhs: _OptionalNilComparisonType
  ) -> Bool {
    switch lhs {
    case .some:
      return true
    case .none:
      return false
    }
  }

  @_transparent
  @_preInverseGenerics
  public static func ==(
    lhs: _OptionalNilComparisonType,
    rhs: borrowing Wrapped?
  ) -> Bool {
    switch rhs {
    case .some:
      return false
    case .none:
      return true
    }
  }

  @_transparent
  @_preInverseGenerics
  public static func !=(
    lhs: _OptionalNilComparisonType,
    rhs: borrowing Wrapped?
  ) -> Bool {
    switch rhs {
    case .some:
      return true
    case .none:
      return false
    }
  }
}

@_transparent
public // COMPILER_INTRINSIC
func _diagnoseUnexpectedNilOptional(_filenameStart: Builtin.RawPointer,
                                    _filenameLength: Builtin.Word,
                                    _filenameIsASCII: Builtin.Int1,
                                    _line: Builtin.Word,
                                    _isImplicitUnwrap: Builtin.Int1) {
  _preconditionFailure()
    // Bool(_isImplicitUnwrap)
    //   ? "Unexpectedly found nil while implicitly unwrapping an Optional value"
    //   : "Unexpectedly found nil while unwrapping an Optional value",
    // file: StaticString(_start: _filenameStart,
    //                    utf8CodeUnitCount: _filenameLength,
    //                    isASCII: _filenameIsASCII),
    // line: UInt(_line))
}

@_alwaysEmitIntoClient
@_semantics("typechecker.type(of:)")
public func type<T: ~Copyable & ~Escapable, Metatype>(
  of value: borrowing T
) -> Metatype {
  // This implementation is never used, since calls to `Swift.type(of:)` are
  // resolved as a special case by the type checker.
  unsafe Builtin.staticReport(_trueAfterDiagnostics(), true._value,
    ("internal consistency error: 'type(of:)' operation failed to resolve"
     as StaticString).utf8Start._rawValue)
  Builtin.unreachable()
}

extension Optional : Equatable where Wrapped : Equatable {
  @inlinable
  public static func ==(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
      return l == r
    case (nil, nil):
      return true
    default:
      return false
    }
  }

  @inlinable
  public static func !=(lhs: Wrapped?, rhs: Wrapped?) -> Bool {
    return !(lhs == rhs)
  }
}

extension Optional: Hashable where Wrapped: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .none:
      hasher.combine(0 as UInt8)
    case .some(let wrapped):
      hasher.combine(1 as UInt8)
      hasher.combine(wrapped)
    }
  }
}

// @frozen
// public struct _OptionalNilComparisonType : ExpressibleByNilLiteral {
//   @_transparent
//   public init(nilLiteral: ()) {
//   }
// }

// extension Optional {
//   @_transparent
//   public static func ~=(lhs: _OptionalNilComparisonType, rhs: Wrapped?) -> Bool {
//     switch rhs {
//     case .some:
//       return false
//     case .none:
//       return true
//     }
//   }

//   @_transparent
//   public static func ==(lhs: Wrapped?, rhs: _OptionalNilComparisonType) -> Bool {
//     switch lhs {
//     case .some:
//       return false
//     case .none:
//       return true
//     }
//   }

//   @_transparent
//   public static func !=(lhs: Wrapped?, rhs: _OptionalNilComparisonType) -> Bool {
//     switch lhs {
//     case .some:
//       return true
//     case .none:
//       return false
//     }
//   }

//   @_transparent
//   public static func ==(lhs: _OptionalNilComparisonType, rhs: Wrapped?) -> Bool {
//     switch rhs {
//     case .some:
//       return false
//     case .none:
//       return true
//     }
//   }

//   @_transparent
//   public static func !=(lhs: _OptionalNilComparisonType, rhs: Wrapped?) -> Bool {
//     switch rhs {
//     case .some:
//       return true
//     case .none:
//       return false
//     }
//   }
// }



@_transparent
public func ?? <T>(optional: T?, defaultValue: @autoclosure () throws -> T)
    rethrows -> T {
  switch optional {
  case .some(let value):
    return value
  case .none:
    return try defaultValue()
  }
}

@_transparent
public func ?? <T>(optional: T?, defaultValue: @autoclosure () throws -> T?)
    rethrows -> T? {
  switch optional {
  case .some(let value):
    return value
  case .none:
    return try defaultValue()
  }
}
