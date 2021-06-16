///
/// A small library that was split off of `io_utils` when Flutter on the browser
/// became more mature.  The small utility class in this library depends on
/// `dart.io`, so it was split off into this "native-only" library so that
/// `io_utils` wouldn't need to depend on `dart.io`.
///
library io_utils_native;

import 'dart:io';

/// A wrapper around an [IOSink] that ensures that all data is flushed before
/// the [IOSink] is closed.  This is needed when an [IOSink] is being used with
/// an API obeying the [Sink] contract, which includes [close] but not [flush].
class FlushingIOSink implements Sink<List<int>> {
  final IOSink _dest;
  Future<void>? _lastClose;

  FlushingIOSink(this._dest);

  @override
  void add(List<int> data) {
    assert(_lastClose == null);
    _dest.add(data);
  }

  /// Flush all pending data from the underlying [IOSink], and close it.
  /// Returns a future that completes when the flush and close are finished.
  /// Calling this method more than once has no effect.
  /// See also [done].
  @override
  Future<void> close() {
    _lastClose ??= Future(() async {
      await flush();
      return _dest.close();
    });
    return _lastClose!;
  }

  /// Flush all pending data from the underlying [IOSink].  Returns a
  /// [Future] that completes when the flush is finished.
  /// See [IOSink.flush].
  Future<void> flush() => _dest.flush();

  /// Get a future that will complete the previous [close]
  /// operation has completed.  It is an error if [close] has not been
  /// called; in this case, the results are undefined.
  Future<void> get done {
    assert(_lastClose != null);
    return _lastClose!;
  }
}
