@inline(never)
@usableFromInline
internal func _abstract(
  // file: StaticString = #file,
  // line: UInt = #line
) -> Never {
  fatalError()
}

@frozen
public struct AnyIterator<Element> {
  @usableFromInline
  internal let _box: _AnyIteratorBoxBase<Element>

  @inlinable
  public init<I : IteratorProtocol>(_ base: I) where I.Element == Element {
    self._box = _IteratorBox(base)
  }

  @inlinable
  public init(_ body: @escaping () -> Element?) {
    self._box = _IteratorBox(_ClosureBasedIterator(body))
  }

  @inlinable
  internal init(_box: _AnyIteratorBoxBase<Element>) {
    self._box = _box
  }
}

extension AnyIterator: IteratorProtocol {
  @inlinable
  public func next() -> Element? {
    return _box.next()
  }
}

extension AnyIterator: Sequence { }

@usableFromInline
@frozen
internal struct _ClosureBasedIterator<Element> : IteratorProtocol {
  @inlinable
  internal init(_ body: @escaping () -> Element?) {
    self._body = body
  }
  @inlinable
  internal func next() -> Element? { return _body() }
  @usableFromInline
  internal let _body: () -> Element?
}

@_fixed_layout
@usableFromInline
internal class _AnyIteratorBoxBase<Element> : IteratorProtocol {
  @inlinable // FIXME(sil-serialize-all)
  internal init() {}

  @inlinable // FIXME(sil-serialize-all)
  deinit {}
  @inlinable // FIXME(sil-serialize-all)
  internal func next() -> Element? { _abstract() }
}

// internal final class _IteratorBox ... this seems to cause missing protocol 'ExpressibleByStringLiteral'
@_fixed_layout
@usableFromInline
internal final class _IteratorBox<
  Base : IteratorProtocol
> : _AnyIteratorBoxBase<Base.Element> {
  @inlinable
  internal init(_ base: Base) { self._base = base }
  @inlinable // FIXME(sil-serialize-all)
  deinit {}
  @inlinable
  internal override func next() -> Base.Element? { return _base.next() }
  @usableFromInline
  internal var _base: Base
}

@usableFromInline
internal protocol _AnyIndexBox : class {
  var _typeID: ObjectIdentifier { get }

  func _unbox<T : Comparable>() -> T?

  func _isEqual(to rhs: _AnyIndexBox) -> Bool

  func _isLess(than rhs: _AnyIndexBox) -> Bool
}

@_fixed_layout
@usableFromInline
internal final class _IndexBox<BaseIndex: Comparable>: _AnyIndexBox {
  @usableFromInline
  internal var _base: BaseIndex

  @inlinable
  internal init(_base: BaseIndex) {
    self._base = _base
  }

  @inlinable
  internal func _unsafeUnbox(_ other: _AnyIndexBox) -> BaseIndex {
    return unsafeDowncast(other, to: _IndexBox.self)._base
  }

  @inlinable
  internal var _typeID: ObjectIdentifier {
    return ObjectIdentifier(type(of: self))
  }

  @inlinable
  internal func _unbox<T : Comparable>() -> T? {
    return (self as _AnyIndexBox as? _IndexBox<T>)?._base
  }

  @inlinable
  internal func _isEqual(to rhs: _AnyIndexBox) -> Bool {
    return _base == _unsafeUnbox(rhs)
  }

  @inlinable
  internal func _isLess(than rhs: _AnyIndexBox) -> Bool {
    return _base < _unsafeUnbox(rhs)
  }
}

@frozen
@_unavailableInEmbedded
public struct AnyIndex {
  @usableFromInline
  internal var _box: _AnyIndexBox

  @inlinable
  public init<BaseIndex : Comparable>(_ base: BaseIndex) {
    self._box = _IndexBox(_base: base)
  }

  @inlinable
  internal init(_box: _AnyIndexBox) {
    self._box = _box
  }

  @inlinable
  internal var _typeID: ObjectIdentifier {
    return _box._typeID
  }
}

@_unavailableInEmbedded
extension AnyIndex : Comparable {
  @inlinable
  public static func == (lhs: AnyIndex, rhs: AnyIndex) -> Bool {
    _precondition(lhs._typeID == rhs._typeID)
    return lhs._box._isEqual(to: rhs._box)
  }

  @inlinable
  public static func < (lhs: AnyIndex, rhs: AnyIndex) -> Bool {
    _precondition(lhs._typeID == rhs._typeID)
    return lhs._box._isLess(than: rhs._box)
  }
}

@usableFromInline
@frozen
internal struct _ClosureBasedSequence<Iterator : IteratorProtocol> {
  @usableFromInline
  internal var _makeUnderlyingIterator: () -> Iterator

  @inlinable
  internal init(_ makeUnderlyingIterator: @escaping () -> Iterator) {
    self._makeUnderlyingIterator = makeUnderlyingIterator
  }
}

extension _ClosureBasedSequence: Sequence {
  @inlinable
  internal func makeIterator() -> Iterator {
    return _makeUnderlyingIterator()
  }
}

@frozen
public struct AnySequence<Element> {
  @usableFromInline
  internal let _box: _AnySequenceBox<Element>
  
  @inlinable
  public init<I : IteratorProtocol>(
    _ makeUnderlyingIterator: @escaping () -> I
  ) where I.Element == Element {
    self.init(_ClosureBasedSequence(makeUnderlyingIterator))
  }

  @inlinable
  internal init(_box: _AnySequenceBox<Element>) {
    self._box = _box
  }
}

extension  AnySequence: Sequence {
  public typealias Iterator = AnyIterator<Element>

  @inlinable
  public init<S : Sequence>(_ base: S)
    where
    S.Element == Element {
    self._box = _SequenceBox(_base: base)
  }
}

extension AnySequence {
  @inline(__always)
  @inlinable
  public __consuming func makeIterator() -> Iterator {
    return _box._makeIterator()
  }
  @inlinable
  public __consuming func dropLast(_ n: Int = 1) -> [Element] {
    return _box._dropLast(n)
  }
  @inlinable
  public __consuming func prefix(
    while predicate: (Element) throws -> Bool
  ) rethrows -> [Element] {
    return try _box._prefix(while: predicate)
  }
  @inlinable
  public __consuming func suffix(_ maxLength: Int) -> [Element] {
    return _box._suffix(maxLength)
  }

  @inlinable
  public var underestimatedCount: Int {
    return _box._underestimatedCount
  }

  @inlinable
  public func map<T>(
    _ transform: (Element) throws -> T
  ) rethrows -> [T] {
    return try _box._map(transform)
  }

  @inlinable
  public __consuming func filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> [Element] {
    return try _box._filter(isIncluded)
  }

  @inlinable
  public __consuming func forEach(
    _ body: (Element) throws -> Void
  ) rethrows {
    return try _box._forEach(body)
  }

  @inlinable
  public __consuming func drop(
    while predicate: (Element) throws -> Bool
  ) rethrows -> AnySequence<Element> {
    return try AnySequence(_box: _box._drop(while: predicate))
  }

  @inlinable
  public __consuming func dropFirst(_ n: Int = 1) -> AnySequence<Element> {
    return AnySequence(_box: _box._dropFirst(n))
  }

  @inlinable
  public __consuming func prefix(_ maxLength: Int = 1) -> AnySequence<Element> {
    return AnySequence(_box: _box._prefix(maxLength))
  }

  @inlinable
  public func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    return _box.__customContainsEquatableElement(element)
  }

  @inlinable
  public __consuming func _copyToContiguousArray() -> ContiguousArray<Element> {
    return self._box.__copyToContiguousArray()
  }

  @inlinable
  public __consuming func _copyContents(initializing buf: UnsafeMutableBufferPointer<Element>)
  -> (AnyIterator<Element>,UnsafeMutableBufferPointer<Element>.Index) {
    let (it,idx) = _box.__copyContents(initializing: buf)
    return (AnyIterator(it),idx)
  }
}

@_fixed_layout
@usableFromInline
internal final class _SequenceBox<S : Sequence> : _AnySequenceBox<S.Element>
{
  @usableFromInline
  internal typealias Element = S.Element

  @inline(__always)
  @inlinable
  internal override func _makeIterator() -> AnyIterator<Element> {
    return AnyIterator(_base.makeIterator())
  }
  @inlinable
  internal override var _underestimatedCount: Int {
    return _base.underestimatedCount
  }
  @inlinable
  internal override func _map<T>(
    _ transform: (Element) throws -> T
  ) rethrows -> [T] {
    return try _base.map(transform)
  }
  @inlinable
  internal override func _filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> [Element] {
    return try _base.filter(isIncluded)
  }
  @inlinable
  internal override func _forEach(
    _ body: (Element) throws -> Void
  ) rethrows {
    return try _base.forEach(body)
  }
  @inlinable
  internal override func __customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    return _base._customContainsEquatableElement(element)
  }
  @inlinable
  internal override func __copyToContiguousArray() -> ContiguousArray<Element> {
    return _base._copyToContiguousArray()
  }
  @inlinable
  internal override func __copyContents(initializing buf: UnsafeMutableBufferPointer<Element>)
    -> (AnyIterator<Element>,UnsafeMutableBufferPointer<Element>.Index) {
    let (it,idx) = _base._copyContents(initializing: buf)
    return (AnyIterator(it),idx)
  }
  @inlinable
  internal override func _dropFirst(_ n: Int) -> _AnySequenceBox<Element> {
    return _SequenceBox<DropFirstSequence<S>>(_base: _base.dropFirst(n))
  }
  @inlinable
  internal override func _drop(
    while predicate: (Element) throws -> Bool
  ) rethrows -> _AnySequenceBox<Element> {
    return try _SequenceBox<DropWhileSequence<S>>(_base: _base.drop(while: predicate))
  }
  @inlinable
  internal override func _dropLast(_ n: Int) -> [Element] {
    return _base.dropLast(n)
  }
  @inlinable
  internal override func _prefix(_ n: Int) -> _AnySequenceBox<Element> {
    return _SequenceBox<PrefixSequence<S>>(_base: _base.prefix(n))
  }

  @available(*, unavailable, message: "cannot build arbitrary sized arrays with prefix(while:), see uSwift documentation")
  @inlinable
  internal override func _prefix(
    while predicate: (Element) throws -> Bool
  ) rethrows -> [Element] {
    return Array<Element>() // dummy return value
    // return try _base.prefix(while: predicate)
  }
  @inlinable
  internal override func _suffix(_ maxLength: Int) -> [Element] {
    return _base.suffix(maxLength)
  }

  @inlinable // FIXME(sil-serialize-all)
  deinit {}

  @inlinable
  internal init(_base: S) {
    self._base = _base
  }
  @usableFromInline
  internal var _base: S
}

//===--- Sequence ---------------------------------------------------------===//
//===----------------------------------------------------------------------===//


@_fixed_layout
@usableFromInline
internal class _AnySequenceBox<Element>
{

  @inlinable // FIXME(sil-serialize-all)
  internal init() { }

  @inlinable
  internal func _makeIterator() -> AnyIterator<Element> { _abstract() }

  @inlinable
  internal var _underestimatedCount: Int { _abstract() }

  @inlinable
  internal func _map<T>(
    _ transform: (Element) throws -> T
  ) rethrows -> [T] {
    _abstract()
  }

  @inlinable
  internal func _filter(
    _ isIncluded: (Element) throws -> Bool
  ) rethrows -> [Element] {
    _abstract()
  }

  @inlinable
  internal func _forEach(
    _ body: (Element) throws -> Void
  ) rethrows {
    _abstract()
  }

  @inlinable
  internal func __customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    _abstract()
  }

  @inlinable
  internal func __copyToContiguousArray() -> ContiguousArray<Element> {
    _abstract()
  }

  @inlinable
  internal func __copyContents(initializing buf: UnsafeMutableBufferPointer<Element>)
    -> (AnyIterator<Element>,UnsafeMutableBufferPointer<Element>.Index) {
    _abstract()
  }

  @inlinable // FIXME(sil-serialize-all)
  deinit {}

  @inlinable
  internal func _drop(
    while predicate: (Element) throws -> Bool
  ) rethrows -> _AnySequenceBox<Element> {
    _abstract()
  }

  @inlinable
  internal func _dropFirst(_ n: Int) -> _AnySequenceBox<Element> {
    _abstract()
  }

  @inlinable
  internal func _dropLast(_ n: Int) -> [Element] {
    _abstract()
  }

  @inlinable
  internal func _prefix(_ maxLength: Int) -> _AnySequenceBox<Element> {
    _abstract()
  }

  @inlinable
  internal func _prefix(
    while predicate: (Element) throws -> Bool
  ) rethrows -> [Element] {
    _abstract()
  }

  @inlinable
  internal func _suffix(_ maxLength: Int) -> [Element] {
    _abstract()
  }
}
