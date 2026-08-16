@_transparent
public func ~= <T : Equatable>(a: T, b: T) -> Bool {
  return a == b
}

// precedencegroup AssignmentPrecedence { assignment: true }
precedencegroup AssignmentPrecedence {
  assignment: true
  associativity: right
}
precedencegroup FunctionArrowPrecedence {
  associativity: right
  higherThan: AssignmentPrecedence
}
precedencegroup TernaryPrecedence {
  associativity: right
  higherThan: FunctionArrowPrecedence
}
precedencegroup DefaultPrecedence {
  higherThan: TernaryPrecedence
}
precedencegroup LogicalDisjunctionPrecedence {
  associativity: left
  higherThan: TernaryPrecedence
}
precedencegroup LogicalConjunctionPrecedence {
  associativity: left
  higherThan: LogicalDisjunctionPrecedence
}
precedencegroup ComparisonPrecedence {
  higherThan: LogicalConjunctionPrecedence
}
precedencegroup NilCoalescingPrecedence {
  associativity: right
  higherThan: ComparisonPrecedence
}
precedencegroup CastingPrecedence {
  higherThan: NilCoalescingPrecedence
}
precedencegroup RangeFormationPrecedence {
  higherThan: CastingPrecedence
}
precedencegroup AdditionPrecedence {
  associativity: left
  higherThan: RangeFormationPrecedence
}
precedencegroup MultiplicationPrecedence {
  associativity: left
  higherThan: AdditionPrecedence
}
precedencegroup BitwiseShiftPrecedence {
  higherThan: MultiplicationPrecedence
}

infix operator  <  : ComparisonPrecedence
infix operator  <= : ComparisonPrecedence
infix operator  >  : ComparisonPrecedence
infix operator  >= : ComparisonPrecedence
infix operator  == : ComparisonPrecedence
infix operator  != : ComparisonPrecedence
infix operator === : ComparisonPrecedence
infix operator !== : ComparisonPrecedence
infix operator  ~= : ComparisonPrecedence
infix operator && : LogicalConjunctionPrecedence
infix operator || : LogicalDisjunctionPrecedence

postfix operator ++
postfix operator --
postfix operator ...

prefix operator ++
prefix operator --
prefix operator !
prefix operator ~
prefix operator +
prefix operator -
prefix operator ...
prefix operator ..<

infix operator   *= : AssignmentPrecedence
infix operator  &*= : AssignmentPrecedence
infix operator   /= : AssignmentPrecedence
infix operator   %= : AssignmentPrecedence
infix operator   += : AssignmentPrecedence
infix operator  &+= : AssignmentPrecedence
infix operator   -= : AssignmentPrecedence
infix operator  &-= : AssignmentPrecedence
infix operator  <<= : AssignmentPrecedence
infix operator &<<= : AssignmentPrecedence
infix operator  >>= : AssignmentPrecedence
infix operator &>>= : AssignmentPrecedence
infix operator   &= : AssignmentPrecedence
infix operator   ^= : AssignmentPrecedence
infix operator   |= : AssignmentPrecedence

// FIXME: is this the right precedence level for "..." ?
infix operator  ... : RangeFormationPrecedence, Comparable
infix operator  ..< : RangeFormationPrecedence, Comparable

infix operator  << : BitwiseShiftPrecedence, BinaryInteger
infix operator &<< : BitwiseShiftPrecedence, FixedWidthInteger
infix operator  >> : BitwiseShiftPrecedence, BinaryInteger
infix operator &>> : BitwiseShiftPrecedence, FixedWidthInteger

// "Multiplicative"

infix operator   * : MultiplicationPrecedence, Numeric
infix operator  &* : MultiplicationPrecedence, FixedWidthInteger
infix operator   / : MultiplicationPrecedence, BinaryInteger, FloatingPoint
infix operator   % : MultiplicationPrecedence, BinaryInteger
infix operator   & : MultiplicationPrecedence, BinaryInteger

// "Additive"

infix operator   + : AdditionPrecedence, AdditiveArithmetic
infix operator  &+ : AdditionPrecedence, FixedWidthInteger
infix operator   - : AdditionPrecedence, AdditiveArithmetic
infix operator  &- : AdditionPrecedence, FixedWidthInteger
infix operator   | : AdditionPrecedence, BinaryInteger
infix operator   ^ : AdditionPrecedence, BinaryInteger

infix operator ?? : NilCoalescingPrecedence