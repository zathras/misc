/// This module contains a set of tests for io_utils.dart.  Add them
/// to a test harness by calling add_io_utils_tests().

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:jovial_misc_native/io_utils_native.dart';
import 'package:jovial_misc/io_utils.dart';
import 'package:test/test.dart';


void _test_flushing_iosink() async {
  final file = File.fromUri(Directory.systemTemp.uri.resolve('test.dat'));
  final flushable = FlushingIOSink(file.openWrite());
  final out = DataOutputSink(flushable);
  out.writeUTF8('Hello, world.');
  out.close();
  await flushable.done;

  final dis = DataInputStream(file.openRead());
  expect(await dis.readUTF8(), 'Hello, world.');
  await dis.close();
  await file.delete();
}

Future<void> add_io_utils_tests() async {
  final rand = Random(0x2a); // Give it a seed so any bugs are repeatable

  test('flushing_iosink', _test_flushing_iosink);
}
