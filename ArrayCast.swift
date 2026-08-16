//===--- ArrayCast.swift - Casts and conversions for Array ----------------===//
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
//
//  Because NSArray is effectively an [AnyObject], casting [T] -> [U]
//  is an integral part of the bridging process and these two issues
//  are handled together.
//
//===----------------------------------------------------------------------===//

@_silgen_name("_swift_arrayDownCastIndirect")
internal func _arrayDownCastIndirect<SourceValue, TargetValue>(
  _ source: UnsafePointer<Array<SourceValue>>,
  _ target: UnsafeMutablePointer<Array<TargetValue>>) {
  target.initialize(to: _arrayForceCast(source.pointee))
}

@inlinable //for performance reasons
public func _arrayForceCast<SourceElement, TargetElement>(
  _ source: Array<SourceElement>
) -> Array<TargetElement> {
  return source.map { $0 as! TargetElement }
}

@_silgen_name("_swift_arrayDownCastConditionalIndirect")
internal func _arrayDownCastConditionalIndirect<SourceValue, TargetValue>(
  _ source: UnsafePointer<Array<SourceValue>>,
  _ target: UnsafeMutablePointer<Array<TargetValue>>
) -> Bool {
  if let result: Array<TargetValue> = _arrayConditionalCast(source.pointee) {
    target.initialize(to: result)
    return true
  }
  return false
}

@inlinable //for performance reasons
public func _arrayConditionalCast<SourceElement, TargetElement>(
  _ source: [SourceElement]
) -> [TargetElement]? {
  var sourceCount = source.count
  guard sourceCount > 0 else {
    return [] // hopefully this is all optimised away in most cases
  }

  var successfulCasts = Array<TargetElement>(_uninitializedCount: &sourceCount)
  guard sourceCount == source.count else {
    // we were unable to allocate enough memory
    return nil
  }

  var castedCount: Int = 0
  for element in source {
    if let casted = element as? TargetElement {
      successfulCasts[castedCount] = casted
      castedCount += 1
    } else {
      return nil
    }
  }
  return successfulCasts
}
