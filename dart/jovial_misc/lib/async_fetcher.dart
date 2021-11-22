///
/// A utility for canonicalizing requests to fetch a resource over
/// the network.
///
library async_fetcher;

import 'package:meta/meta.dart';

///
/// Helper to fetch a value asynchronously, where multiple outstanding requests
/// for the same resource are canonicalized to a single request.  This can
/// prevent loading the same resource more than once.
///
/// Consider, for example, a cache of a resource loaded over the network, using
/// the following algorithm:
/// ```pseudo
/// Future<Thing> get(Key key) {
///   if (cache has an entry for key) {
///     return cache[key];
///   }
///   Fetch Thing t over network;
///   Store t at cache[key];
///   return t;
/// }
/// ```
/// If a resource associated with some key k is being fetched over the
/// network, and a second request for an equivalent key k2 comes in
/// while the network operation for k is ongoing,
/// the above algorithm would fetch the resource twice.  This can be avoided
/// by using [get] from a subclass of `AsyncCanonicalilzingFetcher<Thing, Key>`
/// that implements [create] to load a `Thing` over the network, like this:
/// ```pseudo
/// final fetcher = MyFetcher();
///
/// Future<Thing> get(Key key) => fetcher.get(key);
///
/// class MyFetcher extends AsyncCanonicalizingFetcher<Key, Thing> {
///
///   @override
///   Future<Thing> create(Key key) {
///     if (cache has an entry for key) {
///       return cache[key];
///     }
///     Fetch Thing t over network;
///     Store t at cache[key];
///     return t;
///   }
/// }
/// ```
///
/// A sample usage can be found in the
/// [`jovial_svg` caching sample](https://github.com/zathras/jovial_svg/blob/main/demo_hive/lib/hive_cache.dart).
///
abstract class AsyncCanonicalizingFetcher<K, V> {
  final Map<K, Future<V>> _pending = {};

  ///
  /// Get the value identified by [key].  If this is called with a key that
  /// is equivalent to one that is currently being loaded, a identical
  /// [Future] identical to the one returned for the prior call will be
  /// returned.
  ///
  Future<V> get(K key) => _pending.update(key, (v) => v, ifAbsent: () async {
        try {
          return await create(key);
        } finally {
          final check = _pending.remove(key);
          assert(check != null);
          // This finally block is guaranteed to execute after the Future 
          // created by the ifAbsent function has been stored in _pending, 
          // because the await in the try block always suspends the function.
          // See the Dart language specification, version 2.10, section 17.33
          // (https://dart.dev/guides/language/specifications/DartLangSpec-v2.10.pdf).
        }
      });

  ///
  /// Create a value given [key].  This method is to be overridden by
  /// subclasses.
  ///
  @protected
  Future<V> create(K key);
}
