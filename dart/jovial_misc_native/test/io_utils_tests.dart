// This module contains a set of tests for io_utils.dart.  Add them
// to a test harness by calling add_io_utils_tests().

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:jovial_misc_native/io_utils_native.dart';
import 'package:jovial_misc/io_utils.dart';
import 'package:jovial_misc_pc/io_utils.dart';
import 'package:jovial_misc_native/isolate_stream.dart';
import 'package:pointycastle/export.dart';
import 'package:test/test.dart';


const _paranoia = 1;
// We multiply the amount of randomized testing by this.

Uint8List _nextBytes(Random rand, int size) {
  final result = Uint8List(size);
  for (var i = 0; i < size; i++) {
    result[i] = rand.nextInt(0x100);
  }
  return result;
}

void _testFlushingIosink() async {
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

/// Test encryption/decryption of a big dataset without buffering
/// it all in memory
void bigTest(Random rand, int numItems) async {
  final srand = Random.secure();
  final key = _nextBytes(srand, 16);
  final iv = _nextBytes(srand, 16);

  final Stream<Uint8List> encrypted = IsolateStream<Uint8List>(
      _BigTestGenerator(rand.nextInt(1 << 32), key, iv, numItems));
  final decryptCipher = CBCBlockCipher(AESEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), iv));
  final decrypt = DecryptingStream(decryptCipher, encrypted, PKCS7Padding());
  final dis = DataInputStream(decrypt);
  for (var i = 0; i < numItems; i++) {
    var received = await dis.readLong();
    if (received != i) {
      throw Exception('$i expected, $received received');
    }
    var numBytes = await dis.readInt();
    await dis.readBytes(numBytes);
  }
  if (!(await dis.isEOF())) {
    throw Exception('EOF expected but not seen');
  }
}

final _numFmt = NumberFormat();

class _BigTestGenerator extends IsolateByteStreamGenerator {
  final int seed;
  final Uint8List key;
  final Uint8List iv;
  final int numItems;

  _BigTestGenerator(this.seed, this.key, this.iv, this.numItems);

  @override
  Future<void> generate() async {
    final rand = Random(seed);
    final encryptCipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(key), iv));
    final encrypt = EncryptingSink(encryptCipher, this, PKCS7Padding());
    final ds = DataOutputSink(encrypt);
    var bytesWritten = 0;
    for (var i = 0; i < numItems; i++) {
      ds.writeLong(i);
      var numBytes =
          rand.nextInt(2) == 0 ? rand.nextInt(34) : rand.nextInt(600);
      ds.writeUnsignedInt(numBytes);
      ds.writeBytes(Uint8List(numBytes));
      bytesWritten += 12 + numBytes;
      if (i % 10000 == 0) {
        print('  Isolate wrote ${_numFmt.format(bytesWritten)} bytes so far.');
      }
      await flushIfNeeded();
    }
    ds.close();
    print(
        'Isolate generator done, wrote ${_numFmt.format(bytesWritten)} bytes.');
  }
}

Future<void> addIoUtilsTests() async {
  final rand = Random(0x2a); // Give it a seed so any bugs are repeatable

  test('flushing_iosink', _testFlushingIosink);

  // Create an isolate so we can stream data through
  // encryption/decryption without buffering it all in memory.  These
  // tests are randomized, so we run a fair number of iterations.
  test('stream test 5', () => bigTest(rand, 5));
  for (var i = 0; i < 100 * _paranoia; i++) {
    test('stream test 250 $i', () => bigTest(rand, 250));
  }
  // And finally, run one with a larger amount of data.
  test('stream test 25000', () => bigTest(rand, 25000 * _paranoia),
      timeout: Timeout(Duration(seconds: 30 * _paranoia)));
}
