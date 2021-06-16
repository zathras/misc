import 'dart:async';
import 'dart:io';
import 'package:jovial_misc/io_utils.dart';
import 'package:jovial_misc_native/io_utils_native.dart';
import 'package:pedantic/pedantic.dart';

///
/// Example of using [FlushingIOSink] with [DataOutputSink] and
/// [DataInputStream] to encode values that are compatible with
/// `java.io.DataInputStream` and `java.io.DataOutputStream`
///
Future<void> data_io_stream_example() async {
  final file = File.fromUri(Directory.systemTemp.uri.resolve('test.dat'));
  final sink = FlushingIOSink(file.openWrite());
  final out = DataOutputSink(sink);
  out.writeUTF8('Hello, world.');
  unawaited(sink.close());
  await sink.done;

  final dis = DataInputStream(file.openRead());
  print(await dis.readUTF8());
  await dis.close();
  await file.delete();
}

///
/// Run the example
///
void main() async {
  await data_io_stream_example();
}
