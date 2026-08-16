@frozen
public struct OpaquePointer {
  @usableFromInline
  internal var _rawValue: Builtin.RawPointer

  @usableFromInline @_transparent
  internal init(_ v: Builtin.RawPointer) {
    self._rawValue = v
  }

  @_transparent
  public init?(bitPattern: Int) {
    if bitPattern == 0 { return nil }
    self._rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  @_transparent
  public init?(bitPattern: UInt) {
    if bitPattern == 0 { return nil }
    self._rawValue = Builtin.inttoptr_Word(bitPattern._builtinWordValue)
  }

  @_transparent
  public init<T>(_ from: UnsafePointer<T>) {
    self._rawValue = from._rawValue
  }

  @_transparent
  public init?<T>(_ from: UnsafePointer<T>?) {
    guard let unwrapped = from else { return nil }
    self._rawValue = unwrapped._rawValue
  }

  @_transparent
  public init<T>(_ from: UnsafeMutablePointer<T>) {
    self._rawValue = from._rawValue
  }

  @_transparent
  public init?<T>(_ from: UnsafeMutablePointer<T>?) {
    guard let unwrapped = from else { return nil }
    self._rawValue = unwrapped._rawValue
  }
}

extension OpaquePointer: Equatable {
  @inlinable // unsafe-performance
  public static func == (lhs: OpaquePointer, rhs: OpaquePointer) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}




public protocol _Pointer: Equatable {
// Hashable, Strideable, CustomDebugStringConvertible, CustomReflectable {
  typealias Distance = Int
  
  associatedtype Pointee

  var _rawValue: Builtin.RawPointer { get }

  init?(_ _rawValue: Builtin.RawPointer)
}

extension _Pointer {
  @_transparent
  public init(_ from : OpaquePointer) {
    self.init(from._rawValue)
  }

  @_transparent
  public init?(_ from : OpaquePointer?) {
    guard let unwrapped = from else { return nil }
    self.init(unwrapped)
  }

  @_transparent
  public init?(bitPattern: Int) {
    if bitPattern == 0 { return nil }
    self.init(Builtin.inttoptr_Word(bitPattern._builtinWordValue))
  }

  @_transparent
  public init?(bitPattern: UInt) {
    if bitPattern == 0 { return nil }
    self.init(Builtin.inttoptr_Word(bitPattern._builtinWordValue))
  }

  @_transparent
  public init?(_ other: Self) {
    self.init(other._rawValue)
  }

  @_transparent
  public init?(_ other: Self?) {
    guard let unwrapped = other else { return nil }
    self.init(unwrapped._rawValue)
  }

  // all pointers are creatable from mutable pointers
  
  @_transparent
  public init<T>?(_ other: UnsafeMutablePointer<T>) {
    self.init(other._rawValue)
  }

  @_transparent
  public init?<T>(_ other: UnsafeMutablePointer<T>?) {
    guard let unwrapped = other else { return nil }
    self.init(unwrapped)
  }
}

// well, this is pretty annoying
extension _Pointer /*: Equatable */ {
  @_transparent
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}

extension _Pointer /*: Comparable */ {
  @_transparent
  public static func < (lhs: Self, rhs: Self) -> Bool {
    return Bool(Builtin.cmp_ult_RawPointer(lhs._rawValue, rhs._rawValue))
  }
}






@frozen // FIXME(sil-serialize-all)
public struct ObjectIdentifier {
  @usableFromInline // FIXME(sil-serialize-all)
  internal let _value: Builtin.RawPointer

  @inlinable // FIXME(sil-serialize-all)
  public init(_ x: AnyObject) {
    self._value = Builtin.bridgeToRawPointer(x)
  }

  @inlinable // FIXME(sil-serialize-all)
  public init(_ x: Any.Type) {
    self._value = unsafeBitCast(x, to: Builtin.RawPointer.self)
  }
}

extension ObjectIdentifier: Equatable {
  @inlinable // FIXME(sil-serialize-all)
  public static func == (x: ObjectIdentifier, y: ObjectIdentifier) -> Bool {
    return Bool(Builtin.cmp_eq_RawPointer(x._value, y._value))
  }
}

extension ObjectIdentifier: Comparable {
  @inlinable // FIXME(sil-serialize-all)
  public static func < (lhs: ObjectIdentifier, rhs: ObjectIdentifier) -> Bool {
    return UInt(bitPattern: lhs) < UInt(bitPattern: rhs)
  }
}

extension ObjectIdentifier: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(Int(Builtin.ptrtoint_Word(_value)))
  }
}

extension UInt {
  @inlinable // FIXME(sil-serialize-all)
  public init(bitPattern objectID: ObjectIdentifier) {
    self.init(Builtin.ptrtoint_Word(objectID._value))
  }
}

extension Int {
  @inlinable // FIXME(sil-serialize-all)
  public init(bitPattern objectID: ObjectIdentifier) {
    self.init(bitPattern: UInt(bitPattern: objectID))
  }
}

// @_frozen // namespace
public enum MemoryLayout<T> {
  @_transparent
  public static var size: Int {
    return Int(Builtin.sizeof(T.self))
  }

  @_transparent
  public static var stride: Int {
    return Int(Builtin.strideof(T.self))
  }

  @_transparent
  public static var alignment: Int {
    return Int(Builtin.alignof(T.self))
  }
}

extension MemoryLayout {
  @_transparent
  public static func size(ofValue value: T) -> Int {
    return MemoryLayout.size
  }

  @_transparent
  public static func stride(ofValue value: T) -> Int {
    return MemoryLayout.stride
  }

  @_transparent
  public static func alignment(ofValue value: T) -> Int {
    return MemoryLayout.alignment
  }

  // @_transparent
  // public static func offset(of key: PartialKeyPath<T>) -> Int? {
  //   return key._storedInlineOffset
  // }
}

@frozen // unsafe-performance
public struct UnsafePointer<Pointee>: _Pointer {
  public typealias Distance = Int
  public let _rawValue: Builtin.RawPointer

  @_transparent
  public init(_ _rawValue : Builtin.RawPointer) {
    self._rawValue = _rawValue
  }

  @inlinable
  public func deallocate() {
    Builtin.deallocRaw(_rawValue, (-1)._builtinWordValue, (-1)._builtinWordValue)
  }

  @inlinable // unsafe-performance
  public var pointee: Pointee {
    @_transparent unsafeAddress {
      return self
    }
  }

  // @inlinable
  // public func withMemoryRebound<T, Result>(to type: T.Type, capacity count: Int,
  //   _ body: (UnsafePointer<T>) throws -> Result
  // ) rethrows -> Result {
  //   Builtin.bindMemory(_rawValue, count._builtinWordValue, T.self)
  //   defer {
  //     Builtin.bindMemory(_rawValue, count._builtinWordValue, Pointee.self)
  //   }
  //   return try body(UnsafePointer<T>(_rawValue))
  // }

/** REQUIRES BINARY INTEGER ARITHMETIC */

  // @inlinable
  // public subscript(i: Int) -> Pointee {
  //   @_transparent
  //   unsafeAddress {
  //     return self + i
  //   }
  // }

  // @inlinable // unsafe-performance
  // internal static var _max : UnsafePointer {
  //   return UnsafePointer(
  //     bitPattern: 0 as Int &- MemoryLayout<Pointee>.stride
  //   )._unsafelyUnwrappedUnchecked
  // }
}

@frozen // unsafe-performance
public struct UnsafeMutablePointer<Pointee>: _Pointer {
  public typealias Distance = Int
  public let _rawValue: Builtin.RawPointer

  @_transparent
  public init(_ _rawValue : Builtin.RawPointer) {
    self._rawValue = _rawValue
  }

  @_transparent
  public init(mutating other: UnsafePointer<Pointee>) {
    self._rawValue = other._rawValue
  }

  @_transparent
  public init?(mutating other: UnsafePointer<Pointee>?) {
    guard let unwrapped = other else { return nil }
    self.init(mutating: unwrapped)
  }
  @_transparent   
  public init(_ other: UnsafeMutablePointer<Pointee>) {   
   self._rawValue = other._rawValue   
  }   
   
  @_transparent   
  public init?(_ other: UnsafeMutablePointer<Pointee>?) {   
   guard let unwrapped = other else { return nil }    
   self.init(unwrapped)   
  } 

/** REQUIRES BINARY INTEGER ARITHMETIC */
  @inlinable
  public static func allocate(capacity count: Int)
    -> UnsafeMutablePointer<Pointee> {
    let size = MemoryLayout<Pointee>.stride * count
    let rawPtr =
      Builtin.allocRaw(size._builtinWordValue, Builtin.alignof(Pointee.self))
    Builtin.bindMemory(rawPtr, count._builtinWordValue, Pointee.self)
    return UnsafeMutablePointer(rawPtr)
  }

  @inlinable
  public func deallocate() {
    Builtin.deallocRaw(_rawValue, (-1)._builtinWordValue, (-1)._builtinWordValue)
  }

  // @inlinable // unsafe-performance
  // public var pointee: Pointee {
  //   get {
  //     let s: Builtin.RawPointer = self._rawValue
  //     let r: UnsafePointer<Pointee> = UnsafePointer<Pointee>(s)
  //     return self
  //   }
  //   // @_transparent unsafeAddress {
  //   //   let s = self._rawValue
  //   //   let r = UnsafePointer<Pointee>(s)
  //   //   return self
  //   // }
  //   // @_transparent nonmutating unsafeMutableAddress {
  //   //   return self
  //   // }
  // }

  // @inlinable
  // public func initialize(repeating repeatedValue: Pointee, count: Int) {
  //   // FIXME: add tests (since the `count` has been added)
  //   _debugPrecondition(count >= 0)
  //   // Must not use `initializeFrom` with a `Collection` as that will introduce
  //   // a cycle.
  //   for offset in 0..<count {
  //     Builtin.initialize(repeatedValue, (self + offset)._rawValue)
  //   }
  // }
 
  @inlinable
  public func initialize(to value: Pointee) {
    Builtin.initialize(value, self._rawValue)
  }

  @inlinable
  public func move() -> Pointee {
    return Builtin.take(_rawValue)
  }

  // @inlinable
  // public func assign(repeating repeatedValue: Pointee, count: Int) {
  //   _debugPrecondition(count >= 0)
  //   for i in 0..<count {
  //     self[i] = repeatedValue
  //   }
  // }

  // @inlinable
  // @discardableResult
  // public func deinitialize(count: Int) -> UnsafeMutableRawPointer {
  //   _debugPrecondition(count >= 0)
  //   // FIXME: optimization should be implemented, where if the `count` value
  //   // is 1, the `Builtin.destroy(Pointee.self, _rawValue)` gets called.
  //   Builtin.destroyArray(Pointee.self, _rawValue, count._builtinWordValue)
  //   return UnsafeMutableRawPointer(self)
  // }
}

@_transparent
public // COMPILER_INTRINSIC
func _convertPointerToPointerArgument<
  FromPointer : _Pointer,
  ToPointer : _Pointer
>(_ from: FromPointer) -> ToPointer {
  return ToPointer(from._rawValue)
}

@_transparent
public // COMPILER_INTRINSIC
func _convertInOutToPointerArgument<
  ToPointer : _Pointer
>(_ from: Builtin.RawPointer) -> ToPointer {
  return ToPointer(from)
}

