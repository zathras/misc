import 'package:jovial_misc/async_fetcher.dart';
import 'package:test/test.dart';

import 'io_utils_tests.dart';

void main() {
  group('io_utils', () {
    setUp(() {});

    addIoUtilsTests();
    test('async_fetcher', asyncFetcherSmokeTest);
  });
}

class FetcherOf42 extends AsyncCanonicalizingFetcher<String, int> {
  @override
  Future<int> create(String key) {
    return Future.value(42);
  }
}

Future<void> asyncFetcherSmokeTest() async {
  final fetcher = FetcherOf42();
  final result = await fetcher.get('');
  expect(result, 42);
}
