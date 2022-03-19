///
/// Misc. collection classes
///
library collection;

import 'dart:collection';

///
/// A circular buffer, based on an underlying fixed-length list.
///
class CircularBuffer<T> extends ListMixin<T> {
  final List<T> _store;
  int _first = 0;
  int _last = -1;

  ///
  /// A circular buffer that uses the fixed-size list [store] to store
  /// the elements.  The initial elements of store are ignored.
  ///
  /// Example usages:
  /// ```
  /// final buf = CircularBuffer(Float64List(10));
  /// CircularBuffer<String> buf2 = CircularBuffer(List.filled(10, ''));
  /// ```
  CircularBuffer(List<T> store) : _store = store;

  ///
  /// Create a circular buffer with `capacity` slots, where `empty` is a
  /// default value that can fill unused slots in an underlying container.
  ///
  /// Example usage, nullable type:
  /// ```
  /// final buf = CircularBuffer<MyThing?>.create(10, null)
  /// ```
  ///
  /// Example usage, non-nullable type:
  /// ```
  /// final buf = CircularBuffer.create(10, '')
  /// ```
  ///
  CircularBuffer.create(int capacity, T empty)
      : _store = List.filled(capacity, empty);

  @override
  int get length => (_last == -1) ? 0 : ((_last - _first) % _store.length + 1);

  @override
  set length(int v) {
    if (v < 0 || v > length) {
      throw ArgumentError();
    } else if (v == 0) {
      reset();
    } else {
      _first = (_last + 1 - v);
    }
  }

  ///
  /// Add [element] to the buffer.  If the buffer was already at capacity,
  /// remove the least recently added element.
  ///
  @override
  void add(T element) {
    if (_last == -1) {
      _store[_last = 0] = element;
    } else {
      _last = (_last + 1) % _store.length;
      _store[_last] = element;
      if (_last == _first) {
        _first = (_first + 1) % _store.length;
        assert(length == _store.length);
      }
    }
  }

  ///
  /// Reset the circular buffer to the empty state, without clearing the
  /// old elements from the underlying storage.  See [resetAndClear].
  ///
  void reset() {
    _first = 0;
    _last = -1;
  }

  ///
  /// Give the maximum number of lines this buffer can hold
  ///
  int get maxLines => _store.length;

  ///
  /// Reset the circular buffer to the empty state, and clear out the
  /// old elements from the underlying storage by filling it with
  /// [empty].  Usually this isn't necessary, because those elements are
  /// inaccessible, but not clearing them makes the inelilgible for GC, until
  /// those positions are overwritten.
  ///
  void resetAndClear(T empty) {
    for (int i = 0; i < length; i++) {
      this[i] = empty;
    }
    reset();
  }

  @override
  T operator [](int index) {
    if (index >= length || index < 0) {
      throw ArgumentError('Illegal index');
    }
    index = (index + _first) % _store.length;
    return _store[index];
  }

  @override
  void operator []=(int index, T value) {
    if (index >= length || index < 0) {
      throw ArgumentError('Illegal index');
    }
    index = (index + _first) % _store.length;
    _store[index] = value;
  }
}
