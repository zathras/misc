import 'dart:async';
import 'dart:io';
import 'package:pointycastle/pointycastle.dart';
import 'package:jovial_misc/io_utils.dart';
import 'package:jovial_misc_pc/io_utils.dart';

///
/// Example of using [DataOutputSink] and [DataInputStream] with
/// PointyCastle encription/decryption to
/// encode values that are compatible with `java.io.DataInputStream`
/// and `java.io.DataOutputStream`
///
Future<void> dataIoStreamExample(BlockCipher cipher, Padding padding) async {
  final file = File.fromUri(Directory.systemTemp.uri.resolve('test.dat'));
  final sink = EncryptingSink(cipher, file.openWrite(), padding);
  final out = DataOutputSink(sink);
  out.writeUTF8('Hello, world.');
  sink.close();

  final str = DecryptingStream(cipher, file.openRead(), padding);
  final dis = DataInputStream(str);
  print(await dis.readUTF8());
  await dis.close();
  await file.delete();
}

