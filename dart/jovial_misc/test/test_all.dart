import 'package:test/test.dart';

import 'io_utils_tests.dart';
import 'isolate_stream_tests.dart';

void main() {
  group('isolate_stream', () {
    setUp(() {});

    add_isolate_stream_tests();
  });
  group('io_utils', () {
    setUp(() {});

    add_io_utils_tests();
  });
}
