import uSwiftShims

/* PROGMEM */

@inlinable
public func byteFromProgmem(address: UnsafePointer<UInt8>) -> UInt8 {
	return _byteFromProgmem(address)
}

@inlinable
public func intFromProgmem(address: UnsafePointer<UInt8>) -> UInt {
	return _intFromProgmem(address)
}

@inlinable
public func dwordFromProgmem(address: UnsafePointer<UInt8>) -> UInt32 {
	return _dwordFromProgmem(address)
}

@inlinable
public func floatFromProgmem(address: UnsafePointer<UInt8>) -> Float {
	return _floatFromProgmem(address)
}

extension StaticString: Collection {
	public typealias Element = UInt8

	@inlinable
	public subscript(index: Int) -> UInt8 {
		if hasPointerRepresentation {
			return _byteFromProgmem(utf8Start+index)
		} else {
			return UInt8(UInt(_startPtrOrData))
		}
	}

	@inlinable
	public var count: Int {
		if hasPointerRepresentation {
			return utf8CodeUnitCount
		} else {
			return 1
		}
	}

	@inlinable
	public var startIndex: Int { 0 }
	@inlinable
	public var endIndex: Int { count }
	@inlinable
	public func index(after i: Int) -> Int { i + 1 }
}