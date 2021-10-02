import 'dart:async';
import 'dart:io';
import 'package:jovial_misc/io_utils.dart';

///
/// Example of using [DataOutputSink] and [DataInputStream] to
/// encode values that are compatible with `java.io.DataInputStream`
/// and `java.io.DataOutputStream`
///
Future<void> dataIoStreamExample() async {
  final file = File.fromUri(Directory.systemTemp.uri.resolve('test.dat'));
  final sink = file.openWrite();
  final out = DataOutputSink(sink);
  out.writeUTF8('Hello, world.');
  await sink.close();

  final dis = DataInputStream(file.openRead());
  print(await dis.readUTF8());
  await dis.close();
  await file.delete();
}

///
/// Run the example
///
void main() async {
  await dataIoStreamExample();
}
