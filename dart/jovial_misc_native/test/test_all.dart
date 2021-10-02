import 'package:test/test.dart';

import 'io_utils_tests.dart';
import 'isolate_stream_tests.dart';

void main() {
  group('io_utils', () {
    setUp(() {});

    addIoUtilsTests();
  });
  group('isolate_stream', () {
    setUp(() {});

    addIsolateStreamTests();
  });
}
