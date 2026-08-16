public protocol ExpressibleByStringInterpolation
  // : ExpressibleByStringLiteral
  {

  associatedtype StringInterpolation : StringInterpolationProtocol
    // = DefaultStringInterpolation
    // where StringInterpolation.StringLiteralType == StringLiteralType

  init(stringInterpolation: StringInterpolation)
}

// extension ExpressibleByStringInterpolation
//   where StringInterpolation == DefaultStringInterpolation {

//   public init(stringInterpolation: DefaultStringInterpolation) {
//     self.init(stringLiteral: stringInterpolation.make())
//   }
// }

public protocol StringInterpolationProtocol {
  associatedtype StringLiteralType : _ExpressibleByBuiltinStringLiteral

  init(literalCapacity: Int, interpolationCount: Int)

  mutating func appendLiteral(_ literal: StringLiteralType)

  // Informal requirement: Any desired appendInterpolation overloads, e.g.:
  //
  //   mutating func appendInterpolation<T>(_: T)
  //   mutating func appendInterpolation(_: Int, radix: Int)
  //   mutating func appendInterpolation<T: Encodable>(json: T) throws
}

