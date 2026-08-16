//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Generate comparison functions for tuples up to some reasonable arity.


@inlinable // trivial-implementation
public func ==(lhs: (), rhs: ()) -> Bool {
  return true
}

@inlinable // trivial-implementation
public func !=(lhs: (), rhs: ()) -> Bool {
    return false
}

@inlinable // trivial-implementation
public func <(lhs: (), rhs: ()) -> Bool {
    return false
}

@inlinable // trivial-implementation
public func <=(lhs: (), rhs: ()) -> Bool {
    return true
}

@inlinable // trivial-implementation
public func >(lhs: (), rhs: ()) -> Bool {
    return false
}

@inlinable // trivial-implementation
public func >=(lhs: (), rhs: ()) -> Bool {
    return true
}



@inlinable // trivial-implementation
public func == <A : Equatable, B : Equatable>(lhs: (A,B), rhs: (A,B)) -> Bool {
  guard lhs.0 == rhs.0 else { return false }
  /*tail*/ return (
    lhs.1
  ) == (
    rhs.1
  )
}

@inlinable // trivial-implementation
public func != <A : Equatable, B : Equatable>(lhs: (A,B), rhs: (A,B)) -> Bool {
  guard lhs.0 == rhs.0 else { return true }
  /*tail*/ return (
    lhs.1
  ) != (
    rhs.1
  )
}

@inlinable // trivial-implementation
public func < <A : Comparable, B : Comparable>(lhs: (A,B), rhs: (A,B)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
  /*tail*/ return (
    lhs.1
  ) < (
    rhs.1
  )
}
@inlinable // trivial-implementation
public func <= <A : Comparable, B : Comparable>(lhs: (A,B), rhs: (A,B)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 <= rhs.0 }
  /*tail*/ return (
    lhs.1
  ) <= (
    rhs.1
  )
}
@inlinable // trivial-implementation
public func > <A : Comparable, B : Comparable>(lhs: (A,B), rhs: (A,B)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 > rhs.0 }
  /*tail*/ return (
    lhs.1
  ) > (
    rhs.1
  )
}
@inlinable // trivial-implementation
public func >= <A : Comparable, B : Comparable>(lhs: (A,B), rhs: (A,B)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 >= rhs.0 }
  /*tail*/ return (
    lhs.1
  ) >= (
    rhs.1
  )
}


@inlinable // trivial-implementation
public func == <A : Equatable, B : Equatable, C : Equatable>(lhs: (A,B,C), rhs: (A,B,C)) -> Bool {
  guard lhs.0 == rhs.0 else { return false }
  /*tail*/ return (
    lhs.1, lhs.2
  ) == (
    rhs.1, rhs.2
  )
}

@inlinable // trivial-implementation
public func != <A : Equatable, B : Equatable, C : Equatable>(lhs: (A,B,C), rhs: (A,B,C)) -> Bool {
  guard lhs.0 == rhs.0 else { return true }
  /*tail*/ return (
    lhs.1, lhs.2
  ) != (
    rhs.1, rhs.2
  )
}

@inlinable // trivial-implementation
public func < <A : Comparable, B : Comparable, C : Comparable>(lhs: (A,B,C), rhs: (A,B,C)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2
  ) < (
    rhs.1, rhs.2
  )
}
@inlinable // trivial-implementation
public func <= <A : Comparable, B : Comparable, C : Comparable>(lhs: (A,B,C), rhs: (A,B,C)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 <= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2
  ) <= (
    rhs.1, rhs.2
  )
}
@inlinable // trivial-implementation
public func > <A : Comparable, B : Comparable, C : Comparable>(lhs: (A,B,C), rhs: (A,B,C)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 > rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2
  ) > (
    rhs.1, rhs.2
  )
}
@inlinable // trivial-implementation
public func >= <A : Comparable, B : Comparable, C : Comparable>(lhs: (A,B,C), rhs: (A,B,C)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 >= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2
  ) >= (
    rhs.1, rhs.2
  )
}


@inlinable // trivial-implementation
public func == <A : Equatable, B : Equatable, C : Equatable, D : Equatable>(lhs: (A,B,C,D), rhs: (A,B,C,D)) -> Bool {
  guard lhs.0 == rhs.0 else { return false }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3
  ) == (
    rhs.1, rhs.2, rhs.3
  )
}

@inlinable // trivial-implementation
public func != <A : Equatable, B : Equatable, C : Equatable, D : Equatable>(lhs: (A,B,C,D), rhs: (A,B,C,D)) -> Bool {
  guard lhs.0 == rhs.0 else { return true }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3
  ) != (
    rhs.1, rhs.2, rhs.3
  )
}

@inlinable // trivial-implementation
public func < <A : Comparable, B : Comparable, C : Comparable, D : Comparable>(lhs: (A,B,C,D), rhs: (A,B,C,D)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3
  ) < (
    rhs.1, rhs.2, rhs.3
  )
}
@inlinable // trivial-implementation
public func <= <A : Comparable, B : Comparable, C : Comparable, D : Comparable>(lhs: (A,B,C,D), rhs: (A,B,C,D)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 <= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3
  ) <= (
    rhs.1, rhs.2, rhs.3
  )
}
@inlinable // trivial-implementation
public func > <A : Comparable, B : Comparable, C : Comparable, D : Comparable>(lhs: (A,B,C,D), rhs: (A,B,C,D)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 > rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3
  ) > (
    rhs.1, rhs.2, rhs.3
  )
}
@inlinable // trivial-implementation
public func >= <A : Comparable, B : Comparable, C : Comparable, D : Comparable>(lhs: (A,B,C,D), rhs: (A,B,C,D)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 >= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3
  ) >= (
    rhs.1, rhs.2, rhs.3
  )
}


@inlinable // trivial-implementation
public func == <A : Equatable, B : Equatable, C : Equatable, D : Equatable, E : Equatable>(lhs: (A,B,C,D,E), rhs: (A,B,C,D,E)) -> Bool {
  guard lhs.0 == rhs.0 else { return false }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4
  ) == (
    rhs.1, rhs.2, rhs.3, rhs.4
  )
}

@inlinable // trivial-implementation
public func != <A : Equatable, B : Equatable, C : Equatable, D : Equatable, E : Equatable>(lhs: (A,B,C,D,E), rhs: (A,B,C,D,E)) -> Bool {
  guard lhs.0 == rhs.0 else { return true }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4
  ) != (
    rhs.1, rhs.2, rhs.3, rhs.4
  )
}

@inlinable // trivial-implementation
public func < <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable>(lhs: (A,B,C,D,E), rhs: (A,B,C,D,E)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4
  ) < (
    rhs.1, rhs.2, rhs.3, rhs.4
  )
}
@inlinable // trivial-implementation
public func <= <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable>(lhs: (A,B,C,D,E), rhs: (A,B,C,D,E)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 <= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4
  ) <= (
    rhs.1, rhs.2, rhs.3, rhs.4
  )
}
@inlinable // trivial-implementation
public func > <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable>(lhs: (A,B,C,D,E), rhs: (A,B,C,D,E)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 > rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4
  ) > (
    rhs.1, rhs.2, rhs.3, rhs.4
  )
}
@inlinable // trivial-implementation
public func >= <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable>(lhs: (A,B,C,D,E), rhs: (A,B,C,D,E)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 >= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4
  ) >= (
    rhs.1, rhs.2, rhs.3, rhs.4
  )
}


@inlinable // trivial-implementation
public func == <A : Equatable, B : Equatable, C : Equatable, D : Equatable, E : Equatable, F : Equatable>(lhs: (A,B,C,D,E,F), rhs: (A,B,C,D,E,F)) -> Bool {
  guard lhs.0 == rhs.0 else { return false }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4, lhs.5
  ) == (
    rhs.1, rhs.2, rhs.3, rhs.4, rhs.5
  )
}

@inlinable // trivial-implementation
public func != <A : Equatable, B : Equatable, C : Equatable, D : Equatable, E : Equatable, F : Equatable>(lhs: (A,B,C,D,E,F), rhs: (A,B,C,D,E,F)) -> Bool {
  guard lhs.0 == rhs.0 else { return true }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4, lhs.5
  ) != (
    rhs.1, rhs.2, rhs.3, rhs.4, rhs.5
  )
}

@inlinable // trivial-implementation
public func < <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable, F : Comparable>(lhs: (A,B,C,D,E,F), rhs: (A,B,C,D,E,F)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 < rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4, lhs.5
  ) < (
    rhs.1, rhs.2, rhs.3, rhs.4, rhs.5
  )
}
@inlinable // trivial-implementation
public func <= <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable, F : Comparable>(lhs: (A,B,C,D,E,F), rhs: (A,B,C,D,E,F)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 <= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4, lhs.5
  ) <= (
    rhs.1, rhs.2, rhs.3, rhs.4, rhs.5
  )
}
@inlinable // trivial-implementation
public func > <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable, F : Comparable>(lhs: (A,B,C,D,E,F), rhs: (A,B,C,D,E,F)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 > rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4, lhs.5
  ) > (
    rhs.1, rhs.2, rhs.3, rhs.4, rhs.5
  )
}
@inlinable // trivial-implementation
public func >= <A : Comparable, B : Comparable, C : Comparable, D : Comparable, E : Comparable, F : Comparable>(lhs: (A,B,C,D,E,F), rhs: (A,B,C,D,E,F)) -> Bool {
  if lhs.0 != rhs.0 { return lhs.0 >= rhs.0 }
  /*tail*/ return (
    lhs.1, lhs.2, lhs.3, lhs.4, lhs.5
  ) >= (
    rhs.1, rhs.2, rhs.3, rhs.4, rhs.5
  )
}

// Local Variables:
// eval: (read-only-mode 1)
// End:
