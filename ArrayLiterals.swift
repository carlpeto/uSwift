public protocol ExpressibleByArrayLiteral {
  associatedtype ArrayLiteralElement
  init(arrayLiteral elements: ArrayLiteralElement...)
}

public protocol ExpressibleByDictionaryLiteral {
  associatedtype Key
  associatedtype Value
  init(dictionaryLiteral elements: (Key, Value)...)
}

public protocol _DestructorSafeContainer {
}
