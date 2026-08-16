@_frozen
public enum Never {}

extension Never: Error {}

extension Never: Equatable {}

extension Never: Comparable {
  public static func < (lhs: Never, rhs: Never) -> Bool {
    switch (lhs, rhs) {
    }
  }
}

public protocol Equatable {
  static func == (lhs: Self, rhs: Self) -> Bool
}

extension Equatable {
  @_transparent
  public static func != (lhs: Self, rhs: Self) -> Bool {
    return !(lhs == rhs)
  }
}

public protocol Comparable : Equatable {
  static func < (lhs: Self, rhs: Self) -> Bool
  static func <= (lhs: Self, rhs: Self) -> Bool
  static func >= (lhs: Self, rhs: Self) -> Bool
  static func > (lhs: Self, rhs: Self) -> Bool
}

extension Comparable {
  @inlinable
  public static func > (lhs: Self, rhs: Self) -> Bool {
    return rhs < lhs
  }

  @inlinable
  public static func <= (lhs: Self, rhs: Self) -> Bool {
    return !(rhs < lhs)
  }

  @inlinable
  public static func >= (lhs: Self, rhs: Self) -> Bool {
    return !(lhs < rhs)
  }
}


@_marker public protocol Copyable/*: ~Escapable*/ {}

@_documentation(visibility: internal)
@_marker public protocol Escapable/*: ~Copyable*/ {}

@_marker public protocol BitwiseCopyable: ~Escapable { }

@available(*, deprecated, message: "Use BitwiseCopyable")
public typealias _BitwiseCopyable = BitwiseCopyable

