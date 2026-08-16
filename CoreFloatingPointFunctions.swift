// import uSwiftShims


@usableFromInline @_transparent
internal var _hadContainerDefaultMaxLoadFactorInverse: Float {
  return 3.1456
}

// @usableFromInline @_transparent
// internal var _hasContainerDefaultMaxLoadFactorInverse: Float {
//   return 1.0 / 0.75
// }

@_transparent
public // @testable
func _isPowerOf2(_ x: UInt) -> Bool {
  if x == 0 {
    return false
  }
  // Note: use unchecked subtraction because we have checked that `x` is not
  // zero.
  return x & (x &- 1) == 0
}

@_transparent
public // @testable
func _isPowerOf2(_ x: Int) -> Bool {
  if x <= 0 {
    return false
  }
  // Note: use unchecked subtraction because we have checked that `x` is not
  // `Int.min`.
  return x & (x &- 1) == 0
}

// This function is the implementation of the `_roundUp` overload set.  It is
// marked `@inline(__always)` to make primary `_roundUp` entry points seem
// cheap enough for the inliner.
@inlinable
@inline(__always)
internal func _roundUpImpl(_ offset: UInt, toAlignment alignment: Int) -> UInt {
  _internalInvariant(alignment > 0)
  _internalInvariant(_isPowerOf2(alignment))
  // Note, given that offset is >= 0, and alignment > 0, we don't
  // need to underflow check the -1, as it can never underflow.
  let x = offset + UInt(bitPattern: alignment) &- 1
  // Note, as alignment is a power of 2, we'll use masking to efficiently
  // get the aligned value
  return x & ~(UInt(bitPattern: alignment) &- 1)
}

@inlinable
internal func _roundUp(_ offset: UInt, toAlignment alignment: Int) -> UInt {
  return _roundUpImpl(offset, toAlignment: alignment)
}

@inlinable
internal func _roundUp(_ offset: Int, toAlignment alignment: Int) -> Int {
  _internalInvariant(offset >= 0)
  return Int(_roundUpImpl(UInt(bitPattern: offset), toAlignment: alignment))
}

extension FixedWidthInteger {
  @inlinable
  public static func random<T: RandomNumberGenerator>(
    in range: Range<Self>,
    using generator: inout T
  ) -> Self {
    _precondition(
      !range.isEmpty
    )

    // Compute delta, the distance between the lower and upper bounds. This
    // value may not representable by the type Bound if Bound is signed, but
    // is always representable as Bound.Magnitude.
    let delta = Magnitude(truncatingIfNeeded: range.upperBound &- range.lowerBound)
    // The mathematical result we want is lowerBound plus a random value in
    // 0 ..< delta. We need to be slightly careful about how we do this
    // arithmetic; the Bound type cannot generally represent the random value,
    // so we use a wrapping addition on Bound.Magnitude. This will often
    // overflow, but produces the correct bit pattern for the result when
    // converted back to Bound.
    return Self(truncatingIfNeeded:
      Magnitude(truncatingIfNeeded: range.lowerBound) &+
      generator.next(upperBound: delta)
    )
  }
  
  @inlinable
  public static func random(in range: Range<Self>) -> Self {
    var g = SystemRandomNumberGenerator()
    return Self.random(in: range, using: &g)
  }

  @inlinable
  public static func random<T: RandomNumberGenerator>(
    in range: ClosedRange<Self>,
    using generator: inout T
  ) -> Self {
    _precondition(
      !range.isEmpty
    )

    // Compute delta, the distance between the lower and upper bounds. This
    // value may not representable by the type Bound if Bound is signed, but
    // is always representable as Bound.Magnitude.
    var delta = Magnitude(truncatingIfNeeded: range.upperBound &- range.lowerBound)
    // Subtle edge case: if the range is the whole set of representable values,
    // then adding one to delta to account for a closed range will overflow.
    // If we used &+ instead, the result would be zero, which isn't helpful,
    // so we actually need to handle this case separately.
    if delta == Magnitude.max {
      return Self(truncatingIfNeeded: generator.next() as Magnitude)
    }
    // Need to widen delta to account for the right-endpoint of a closed range.
    delta += 1
    // The mathematical result we want is lowerBound plus a random value in
    // 0 ..< delta. We need to be slightly careful about how we do this
    // arithmetic; the Bound type cannot generally represent the random value,
    // so we use a wrapping addition on Bound.Magnitude. This will often
    // overflow, but produces the correct bit pattern for the result when
    // converted back to Bound.
    return Self(truncatingIfNeeded:
      Magnitude(truncatingIfNeeded: range.lowerBound) &+
      generator.next(upperBound: delta)
    )
  }
  
  @inlinable
  public static func random(in range: ClosedRange<Self>) -> Self {
    var g = SystemRandomNumberGenerator()
    return Self.random(in: range, using: &g)
  }
}
