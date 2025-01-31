// This module contains a set of tests for isolate_stream.dart.  Add them
// to a test harness by calling add_isolate_stream_tests().

import 'dart:async';
import 'package:test/test.dart';

import 'package:jovial_misc_native/isolate_stream.dart';

class StringGenerator extends IsolateStreamGenerator<String> {
  final List<String> _strings;

  @override
  int bufferSize;

  StringGenerator(this._strings, this.bufferSize);

  @override
  Future<void> generate() async {
    for (var s in _strings) {
      await sendValue(s);
    }
  }

  @override
  int sizeOf(String value) => 1; // Count strings sent
}

Future<void> addIsolateStreamTests() async {
  for (var size = 0; size < 7; size++) {
    test('small IsolateStream - buffer size $size', () async {
      final testData = ['hello', 'isolate', 'world', 'five', 'elements'];
      print('testing $testData');
      var str = IsolateStream<String>(StringGenerator(testData, size));
      final ti = testData.iterator;
      final si = StreamIterator<String>(str);
      while (ti.moveNext()) {
        expect(await si.moveNext(), true);
        expect(ti.current, si.current);
      }
      expect(await si.moveNext(), false);
    });
  }
}
