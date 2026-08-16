public protocol RawRepresentable {

  associatedtype RawValue

  init?(rawValue: RawValue)

  var rawValue: RawValue { get }
}

@inlinable // FIXME(sil-serialize-all)
public func == <T : RawRepresentable>(lhs: T, rhs: T) -> Bool
  where T.RawValue : Equatable {
  return lhs.rawValue == rhs.rawValue
}

@inlinable // FIXME(sil-serialize-all)
public func != <T : RawRepresentable>(lhs: T, rhs: T) -> Bool
  where T.RawValue : Equatable {
  return lhs.rawValue != rhs.rawValue
}

@inlinable // FIXME(sil-serialize-all)
public func != <T : Equatable>(lhs: T, rhs: T) -> Bool
  where T : RawRepresentable, T.RawValue : Equatable {
  return lhs.rawValue != rhs.rawValue
}

public protocol CaseIterable {
  associatedtype AllCases: Collection
    where AllCases.Element == Self

  static var allCases: AllCases { get }
}