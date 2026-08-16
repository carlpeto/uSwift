// public typealias Void = ()
public typealias _MaxBuiltinIntegerType = Builtin.Int2048

// public typealias CInt = Int32
// public typealias CChar = Int8

public typealias Void = ()
// public typealias IntegerLiteralType = UInt8
// the latest stdlib was balking with our familiar definition of
// constants as UInt8, so we'll use the more standard Int
// this might cause some code to break but such is the price of progress
// and it's easily fixed
public typealias IntegerLiteralType = Int
public typealias BooleanLiteralType = Bool

// public typealias FloatLiteralType = Double

public typealias AnyObject = Builtin.AnyObject
public typealias AnyClass = AnyObject.Type

// these are necessary for the clang importer to work
// public typealias CChar = Int8

// public typealias CUnsignedChar = UInt8
// public typealias CUnsignedShort = UInt16
// public typealias CUnsignedInt = UInt32
// public typealias CUnsignedLong = UInt
// // public typealias CUnsignedLongLong = UInt64

// public typealias CSignedChar = Int8
// public typealias CShort = Int16
// public typealias CInt = Int32
// public typealias CLong = Int
// // public typealias CLongLong = Int64
// public typealias CFloat = Float
// // public typealias CDouble = Double

// // public typealias CLongDouble = Double
// // public typealias CWideChar = Unicode.Scalar

// public typealias CChar16 = UInt16
// // public typealias CChar32 = Unicode.Scalar
// public typealias CBool = Bool