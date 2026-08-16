//===----------------------------------------------------------------------===//
//
// This source file is part of Swift for Arduino
//
// Copyright (c) 2020 Carl Peto
// Strictly limited, not for reproduction or copying, use only as explicitly
// allowed within the Swift for Arduino IDE.
//
//===----------------------------------------------------------------------===//

import uSwiftShims

public protocol Marshalled {
    static func readSharedGlobal(_ test: Self) -> Self
}

extension Bool: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: Bool) -> Bool {
        return _readSharedGlobalBool(test)
    }    
}

extension UInt8: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: UInt8) -> UInt8 {
    	return _readSharedGlobalUInt8(test)
    }
}

extension Int8: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: Int8) -> Int8 {
    	return _readSharedGlobalInt8(test)
    }
}

extension UInt16: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: UInt16) -> UInt16 {
    	return _readSharedGlobalUInt16(test)
    }
}

extension Int32: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: Int32) -> Int32 {
    	return _readSharedGlobalInt32(test)
    }
}

extension UInt32: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: UInt32) -> UInt32 {
        return _readSharedGlobalUInt32(test)
    }
}

extension Int64: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: Int64) -> Int64 {
        return _readSharedGlobalInt64(test)
    }
}

extension UInt64: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: UInt64) -> UInt64 {
        return _readSharedGlobalUInt64(test)
    }
}

extension Float: Marshalled {
    @inlinable
    @inline(__always)
    public static func readSharedGlobal(_ test: Float) -> Float {
        return _readSharedGlobalFloat(test)
    }
}


@propertyWrapper
@frozen
public struct Volatile<Value: Marshalled> {
    @usableFromInline
    var _value: Value

    @inlinable
    @inline(__always)
    @_specialize(kind: full, where Value == UInt16)
    public init(wrappedValue value: Value) {
        _value = value
    }

    public var wrappedValue: Value {
        @inlinable
        @inline(__always)
        get {
            Value.readSharedGlobal(_value)
        }
        @inlinable
        @inline(__always)
        set { _value = newValue }
    }
}

@propertyWrapper
@frozen
public struct hardwarePointer<Pointee> {
    @usableFromInline
    var _ptr: UnsafeMutablePointer<Pointee>

    // @inlinable
    // @inline(__always)
    @_transparent
    public init(registerAddress address: Int) {
       _ptr = UnsafeMutablePointer<Pointee>(knownNotNilBitPattern: address)
    }

    @_transparent
    public var wrappedValue: Pointee {
        // @inlinable
        // @inline(__always)
        @_transparent
        get {
            // equivalent of
            // _ptr.pointee
            // but safe from optimisations
           Builtin.loadRaw(_ptr._rawValue)
        }
        // @inlinable
        // @inline(__always)
        @_transparent
        set {
            // equivalent of
            // _ptr.pointee = newValue
            // but safe from optimisations
           Builtin.assign(newValue, _ptr._rawValue)
        }
    }
}

@frozen
public struct Flag {
    public var _value: Bool

    @inlinable
    @inline(__always)
    public init() {
        _value = false
    }
    @_transparent
    public func isSet() -> Bool {
        _globalFlagRead(flag: _value)
    }
    @_transparent
    public mutating func set() {
        _globalFlagUpdate(flag: &_value, value: true)
    }
    @_transparent
    public mutating func clear() {
        _globalFlagUpdate(flag: &_value, value: false)
    }
}

// these functions are just optimiser defeaters, to allow interrupts to read and set global flags
@_transparent
public func _globalFlagUpdate(flag: inout Bool, value: Bool) {
    Builtin.assign(value, Builtin.addressof(&flag))
}

@_transparent
public func _globalFlagRead(flag: Bool) -> Bool {
    var flag = flag
    return Builtin.loadRaw(Builtin.addressof(&flag))
}

@_transparent
public func _rawPointerWrite<Pointee>(address: Int, value: Pointee) {
    Builtin.assign(value, UnsafeMutablePointer<Pointee>(knownNotNilBitPattern: address)._rawValue)
}

@_transparent
public func _rawPointerRead<Pointee>(address: Int) -> Pointee {
    Builtin.loadRaw(UnsafeMutablePointer<Pointee>(knownNotNilBitPattern: address)._rawValue)
}

