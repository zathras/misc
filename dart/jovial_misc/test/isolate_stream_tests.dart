/// This module contains a set of tests for isolate_stream.dart.  Add them
/// to a test harness by calling add_isolate_stream_tests().

import 'dart:async';
import 'package:test/test.dart';

import 'package:jovial_misc/isolate_stream.dart';

Iterator<String> _generateStringIterator(List<String> arg) => arg.iterator;

StreamIterator<String> _generateStringStreamIterator(List<String> arg) =>
    StreamIterator<String>(Stream.fromIterable(arg));

Future<void> _generateStringSink(
    List<String> arg, IsolateGeneratorSink<dynamic> rawDest) async {
  var dest = IsolateGeneratorSink<String>.fromDynamic(rawDest);
  for (var s in arg) {
    dest.add(s);
    await dest.flushIfNeeded();
  }
  dest.close();
}

int _stringSize(String s) => 1;

void add_isolate_stream_tests() {
  test('small IsolateStream - Iterator', () async {
    final testData = ['hello', 'isolate', 'world', 'five', 'elements'];
    print('testing $testData');
    var str = IsolateStream<String, List<String>>(
        _generateStringIterator, testData, _stringSize,
        maxBuf: 1);
    final ti = testData.iterator;
    final si = StreamIterator(str);
    while (ti.moveNext()) {
      expect(await si.moveNext(), true);
      expect(ti.current, await si.current);
    }
    expect(await si.moveNext(), false);
  });

  test('small IsolateStream - StreamIterator', () async {
    final testData = ['hello', 'isolate', 'world', 'five', 'elements'];
    print('testing $testData');
    var str = IsolateStream<String, List<String>>.fromStreamIterator(
        _generateStringStreamIterator, testData, _stringSize,
        maxBuf: 4);
    final ti = testData.iterator;
    final si = StreamIterator(str);
    while (ti.moveNext()) {
      expect(await si.moveNext(), true);
      expect(ti.current, await si.current);
    }
    expect(await si.moveNext(), false);
  });

  test('small IsolateStream - Sink', () async {
    final testData = ['hello', 'isolate', 'world', 'five', 'elements'];
    print('testing $testData');
    var str = IsolateStream<String, List<String>>.fromSink(
        _generateStringSink, testData, _stringSize,
        maxBuf: 4);
    final ti = testData.iterator;
    final si = StreamIterator(str);
    while (ti.moveNext()) {
      expect(await si.moveNext(), true);
      expect(ti.current, await si.current);
    }
    expect(await si.moveNext(), false);
  });
}
