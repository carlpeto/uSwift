@_transparent
public // @testable
func _canBeClass<T>(_: T.Type) -> Int8 {
  return Int8(Builtin.canBeClass(T.self))
}

@inlinable // unsafe-performance
@_transparent
public func unsafeBitCast<T, U>(_ x: T, to type: U.Type) -> U {
  // _precondition(MemoryLayout<T>.size == MemoryLayout<U>.size)
  return Builtin.reinterpretCast(x)
}

@_transparent
public func _identityCast<T, U>(_ x: T, to expectedType: U.Type) -> U {
  // _precondition(T.self == expectedType)
  return Builtin.reinterpretCast(x)
}

@usableFromInline @_transparent
internal func _reinterpretCastToAnyObject<T>(_ x: T) -> AnyObject {
  return unsafeBitCast(x, to: AnyObject.self)
}

@usableFromInline @_transparent
internal func == (
  lhs: Builtin.NativeObject, rhs: Builtin.NativeObject
) -> Bool {
  return unsafeBitCast(lhs, to: Int.self) == unsafeBitCast(rhs, to: Int.self)
}

@usableFromInline @_transparent
internal func != (
  lhs: Builtin.NativeObject, rhs: Builtin.NativeObject
) -> Bool {
  return !(lhs == rhs)
}

@usableFromInline @_transparent
internal func == (
  lhs: Builtin.RawPointer, rhs: Builtin.RawPointer
) -> Bool {
  return unsafeBitCast(lhs, to: Int.self) == unsafeBitCast(rhs, to: Int.self)
}

@usableFromInline @_transparent
internal func != (lhs: Builtin.RawPointer, rhs: Builtin.RawPointer) -> Bool {
  return !(lhs == rhs)
}

/// Returns a Boolean value indicating whether two types are identical.
///
/// - Parameters:
///   - t0: A type to compare.
///   - t1: Another type to compare.
/// - Returns: `true` if both `t0` and `t1` are `nil` or if they represent the
///   same type; otherwise, `false`.
@_alwaysEmitIntoClient
@_transparent
public func == (
  t0: (any (~Copyable & ~Escapable).Type)?,
  t1: (any (~Copyable & ~Escapable).Type)?
) -> Bool {
  switch (t0, t1) {
  case (.none, .none):
    return true
  case let (.some(ty0), .some(ty1)):
#if compiler(>=5.3) && $GeneralizedIsSameMetaTypeBuiltin
    return Bool(Builtin.is_same_metatype(ty0, ty1))
#else
    // FIXME: Remove this branch once all supported compilers understand the
    // generalized is_same_metatype builtin
    let p1 = unsafeBitCast(ty0, to: UnsafeRawPointer.self)
    let p2 = unsafeBitCast(ty1, to: UnsafeRawPointer.self)
    return p1 == p2
#endif
  default:
    return false
  }
}

/// Returns a Boolean value indicating whether two types are not identical.
///
/// - Parameters:
///   - t0: A type to compare.
///   - t1: Another type to compare.
/// - Returns: `true` if one, but not both, of `t0` and `t1` are `nil`, or if
///   they represent different types; otherwise, `false`.
@_alwaysEmitIntoClient
@_transparent
public func != (
  t0: (any (~Copyable & ~Escapable).Type)?,
  t1: (any (~Copyable & ~Escapable).Type)?
) -> Bool {
  !(t0 == t1)
}

#if !$Embedded
@inlinable
public func == (t0: Any.Type?, t1: Any.Type?) -> Bool {
  switch (t0, t1) {
  case (.none, .none): return true
  case let (.some(ty0), .some(ty1)):
    return Bool(Builtin.is_same_metatype(ty0, ty1))
  default: return false
  }
}

@inlinable
public func != (t0: Any.Type?, t1: Any.Type?) -> Bool {
  return !(t0 == t1)
}
#endif

@usableFromInline @_transparent
internal func _unreachable(_ condition: Bool = true) {
  if condition {
    Builtin.unreachable()
  }
}

@usableFromInline @_transparent
internal func _conditionallyUnreachable() -> Never {
  Builtin.conditionallyUnreachable()
}

@_transparent
public func _unsafeReferenceCast<T, U>(_ x: T, to: U.Type) -> U {
  return Builtin.castReference(x)
}

@_transparent
public func unsafeDowncast<T : AnyObject>(_ x: AnyObject, to type: T.Type) -> T {
  _debugPrecondition(x is T)
  return Builtin.castReference(x)
}

@_transparent
public func _unsafeUncheckedDowncast<T : AnyObject>(_ x: AnyObject, to type: T.Type) -> T {
  // _sanityCheck(x is T, "invalid unsafeDowncast")
  return Builtin.castReference(x)
}


@_transparent
public func assert(
  _ condition: @autoclosure () -> Bool
) {
  // noop
}

@_transparent
public func precondition(
  _ condition: @autoclosure () -> Bool
) {
  // noop
}

@inlinable
@inline(__always)
public func assertionFailure(
) {
  // noop
}

@_transparent
public func preconditionFailure(
) -> Never {
  // Only check in debug and release mode.  In release mode just trap.
  _conditionallyUnreachable()
}

@_transparent
public func fatalError(
) -> Never {
  _assertionFailure()
}

@usableFromInline
@inline(never)
@_semantics("programtermination_point")
internal func _assertionFailure(
) -> Never {
  Builtin.int_trap()
}

public // COMPILER_INTRINSIC
func _undefined<T>(
) -> T {
  _assertionFailure()
}

// this is used when using classes, such as in existential box
// note this is NOT functional, we may need to modify the compiler appropriately

@_transparent
public // COMPILER_INTRINSIC
func _unimplementedInitializer(
  className: StaticString,
  initName: StaticString = #function,
  file: StaticString = #file,
  line: UInt = #line,
  column: UInt = #column
) -> Never {
  // This function is marked @_transparent so that it is inlined into the caller
  // (the initializer stub), and, depending on the build configuration,
  // redundant parameter values (#file etc.) are eliminated, and don't leak
  // information about the user's source.
  Builtin.int_trap()
}

// note for things like undefined, it returns T so we can check if we should
// trap, for things like _diagnoseUnexpectedEnumCaseValue, the function signature
// returns Never so we have to trap, otherwise we would need to change every
// call site

@inline(never)
@usableFromInline // COMPILER_INTRINSIC
internal func _diagnoseUnexpectedEnumCaseValue<SwitchedValue, RawValue>(
  type: SwitchedValue.Type,
  rawValue: RawValue
) -> Never {
  _assertionFailure()
}

@inline(never)
@usableFromInline // COMPILER_INTRINSIC
internal func _diagnoseUnexpectedEnumCase<SwitchedValue>(
  type: SwitchedValue.Type
) -> Never {
  _assertionFailure()
}

// @inlinable
// internal
// func _isValidAddress(_ address: UInt) -> Bool {
//   // TODO: define (and use) ABI max valid pointer value
//   return address >= _swift_abi_LeastValidPointerValue
// }

// NEEDS OBJC
// @inlinable // FIXME(sil-serialize-all)
// internal func _unsafeDowncastToAnyObject(fromAny any: Any) -> AnyObject {
//   // _sanityCheck(type(of: any) is AnyObject.Type
//   //              || type(of: any) is AnyObject.Protocol,
//   //              "Any expected to contain object reference")
//   return any as AnyObject
// }

@inlinable // FIXME(sil-serialize-all)
@inline(__always)
public // internal with availability
func _trueAfterDiagnostics() -> Builtin.Int1 {
  let val: Bool = true
  return val._value
}

@usableFromInline @_transparent
internal func _preconditionFailure() {
  _precondition(false)
}

@usableFromInline @_transparent
internal func _debugPreconditionFailure() -> Never {
  Builtin.conditionallyUnreachable()
}

@usableFromInline @_transparent
internal func _sanityCheckFailure() -> Never {
  Builtin.conditionallyUnreachable()
}

@usableFromInline @_transparent
@_semantics("branchhint")
internal func _branchHint(_ actual: Bool, expected: Bool) -> Bool {
  return Bool(Builtin.int_expect_Int1(actual._value, expected._value))
}

@_transparent
@_semantics("fastpath")
public func _fastPath(_ x: Bool) -> Bool {
  return _branchHint(x, expected: true)
}

@_transparent
@_semantics("slowpath")
public func _slowPath(_ x: Bool) -> Bool {
  return _branchHint(x, expected: false)
}

@_transparent
public func _onFastPath() {
  Builtin.onFastPath()
}

@inlinable // FIXME(sil-serialize-all)
@inline(__always)
internal func _bitPattern(_ x: Builtin.BridgeObject) -> UInt {
  return UInt(Builtin.castBitPatternFromBridgeObject(x))
}



@usableFromInline @_transparent
internal func _isUnique<T>(_ object: inout T) -> Bool {
  return Bool(Builtin.isUnique(&object))
}

@_transparent
public // @testable
func _isUnique_native<T>(_ object: inout T) -> Bool {
  // This could be a bridge object, single payload enum, or plain old
  // reference. Any case it's non pointer bits must be zero, so
  // force cast it to BridgeObject and check the spare bits.
  // _sanityCheck(
  //   (_bitPattern(Builtin.reinterpretCast(object)) & _objectPointerSpareBits)
  //   == 0)
  // _sanityCheck(_usesNativeSwiftReferenceCounting(
  //     type(of: Builtin.reinterpretCast(object) as AnyObject)))
  return Bool(Builtin.isUnique_native(&object))
}

@_alwaysEmitIntoClient
@_transparent
public // @testable
func _COWBufferForReading<T: AnyObject>(_ object: T) -> T {
  return Builtin.COWBufferForReading(object)
}

@_transparent
@_preInverseGenerics
public // @testable
func _isPOD<T: ~Copyable & ~Escapable>(_ type: T.Type) -> Bool {
  Bool(Builtin.ispod(type))
}

@_transparent
public // @testable
func _isBitwiseTakable<T>(_ type: T.Type) -> Bool {
  return Bool(Builtin.isbitwisetakable(type))
}

@_transparent
public // @testable
func _isOptional<T>(_ type: T.Type) -> Bool {
  return Bool(Builtin.isOptional(type))
}

@_alwaysEmitIntoClient
@_transparent
public // @testable
func _isConcrete<T>(_ type: T.Type) -> Bool {
  return Bool(Builtin.isConcrete(type))
}

@_alwaysEmitIntoClient @inline(__always)
internal func _isComputed(_ value: Int) -> Bool {
  return !Bool(Builtin.int_is_constant_Word(value._builtinWordValue))
}

@inlinable // trivial-implementation
public func === (lhs: AnyObject?, rhs: AnyObject?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return ObjectIdentifier(l) == ObjectIdentifier(r)
  case (nil, nil):
    return true
  default:
    return false
  }
}

@inlinable // trivial-implementation
public func !== (lhs: AnyObject?, rhs: AnyObject?) -> Bool {
  return !(lhs === rhs)
}

#if SHOULD_EXECUTE_ABORT_ROUTINE
// set this callback for an indicator routine that should be called whenever an internal
// precondition fails, this is very good for debugging unexpected or unsafe code paths
// and enhancing the safety of uSwift
// but should be used with thought... a good use case on an Arduino Uno might be to go into an
// infinte loop and flash the L indicator light very rapidly or in a characteristic pattern so
// it's obvious to the user or developer that there's an issue
// an example for a more production level system might be to send a signal down a known pin or
// to a known I2C device to indicate a failure condition, then possibly trigger a reboot, or
// wait for the watchdog timer to do it for you
// note: this routine will not be called on precondition failure unless SHOULD_EXECUTE_ABORT_ROUTINE is defined
public var preconditionFailureTrapRoutine: (() -> Never)? = nil

// This variant works on the idea of a failure code. This makes more sense on embedded platforms.
// It's space consuming and unneccesary to have a full catalog of strings of what each precondition failure means.
// Instead we'll just store a two byte code and give the users a great big lookup table.
// public var preconditionFailureTrapRoutine: ((assertNumber: Int) -> Never)? = nil
#endif

// The define SHOULD_TRAP_ON_PRECONDITION will cause the program to either trap (go into an infinite loop) or call a handler on precondition fail
// The define SHOULD_EXECUTE_ABORT_ROUTINE will cause the program to jump to a defined callback (if set) on precondition fail

@usableFromInline @_transparent
internal func _precondition(
  _ condition: @autoclosure () -> Bool
) {
  // Only check in debug and release mode. In release mode just trap.
#if SHOULD_TRAP_ON_PRECONDITION
#if SHOULD_EXECUTE_ABORT_ROUTINE
  if !condition() {
    preconditionFailureTrapRoutine?()
  }
#else
  let error = !condition()
  Builtin.condfail(error._value)
#endif
#endif
}

@usableFromInline @_transparent
internal func _debugPrecondition(
  _ condition: @autoclosure () -> Bool
) {
  // noop
}

@usableFromInline @_transparent
internal func _internalInvariant(
  _ condition: @autoclosure () -> Bool
) {
// noop
}

@_alwaysEmitIntoClient // Swift 5.1
@_transparent
internal func _internalInvariant_5_1(
  _ condition: @autoclosure () -> Bool
) {
// noop
}

@usableFromInline @_transparent
internal func _internalInvariantFailure(
) -> Never {
  _internalInvariant(false)
  Builtin.conditionallyUnreachable()
}
