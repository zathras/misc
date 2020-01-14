/// This module contains a set of tests for io_utils.dart.  Add them
/// to a test harness by calling add_io_utils_tests().

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:intl/intl.dart';
import 'package:pointycastle/export.dart';

import 'package:jovial_misc/io_utils.dart';
import 'package:jovial_misc/isolate_stream.dart';

Uint8List _nextBytes(Random rand, int size) {
  final result = Uint8List(size);
  for (var i = 0; i < size; i++) {
    result[i] = rand.nextInt(0x100);
  }
  return result;
}

/// Test encryption/decryption in memory
void _testStream(bool chatter, List<List<int>> testData) async {
  final goalBuilder = BytesBuilder(copy: false);
  testData.forEach((e) => goalBuilder.add(e));
  final goal = goalBuilder.takeBytes();

  final srand = Random.secure();
  final key = _nextBytes(srand, 16);
  final iv = _nextBytes(srand, 16);
  final encryptCipher = CBCBlockCipher(AESFastEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt
  final decryptCipher = CBCBlockCipher(AESFastEngine())
    ..init(false, ParametersWithIV(KeyParameter(key), iv));

  if (chatter) {
    print('Original:  $testData');
  }

  // I could do this:
  //   final encrypted = StreamController<List<int>>();
  //   final encrypt = EncryptingSink(encryptCipher, encrypted, PKCS7Padding());
  //    final Stream<Uint8List> decrypt
  //      = DecryptingStream(decryptCipher, encrypted.stream, PKCS7Padding());
  // but it's more efficient to just collect the encrypted bytes into a
  // byte array.
  final encrypted = ByteAccumulatorSink();
  final encrypt = EncryptingSink(encryptCipher, encrypted, PKCS7Padding());
  testData.forEach((e) => encrypt.add(e));
  encrypt.close();
  if (chatter) {
    print('Encrypted: ${encrypted.bytes}');
  }

  final encryptedStream = Stream.value(encrypted.bytes);
  final decrypt =
      DecryptingStream(decryptCipher, encryptedStream, PKCS7Padding());
  final resultBuilder = BytesBuilder(copy: false);
  await decrypt.forEach((a) => resultBuilder.add(a));
  final result = resultBuilder.takeBytes();
  if (chatter) {
    print('goal $goal');
    print('result $result');
    print('');
  }
  if (!(const IterableEquality()).equals(result, goal)) {
    throw Exception('test failed');
  }
}

/// Test encryption/decryption of a big dataset without buffering
/// it all in memory
void bigTest(Random rand, int numItems) async {
  final srand = Random.secure();
  final key = _nextBytes(srand, 16);
  final iv = _nextBytes(srand, 16);

  // ignore: omit_local_variable_types
  final Stream<Uint8List> encrypted = IsolateStream<Uint8List>(
      _BigTestGenerator(rand.nextInt(1 << 32), key, iv, numItems));
  final decryptCipher = CBCBlockCipher(AESFastEngine())
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
    final encryptCipher = CBCBlockCipher(AESFastEngine())
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

Future<void> add_io_utils_tests() async {
  final rand = Random(0x2a); // Give it a seed so any bugs are repeatable

  test('empty', () => _testStream(true, [[]]));
  test(
      'short',
      () => _testStream(true, [
            [1, 2, 3, 4, 5]
          ]));
  test('empty x2', () => _testStream(true, [[], []]));
  test(
      '1 to 7',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7]
          ]));
  test(
      '1 to 15',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7],
            [8, 9, 10, 11, 12, 13, 14, 15]
          ]));
  test(
      '1 to 16',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7],
            [8, 9, 10, 11, 12, 13, 14, 15, 16]
          ]));
  test(
      '1 to 17',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7],
            [8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
          ]));
  test(
      '1 to 31',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7],
            [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
            [23, 24, 25, 26, 27, 28, 29, 30, 31]
          ]));
  test(
      '1 to 32',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7],
            [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
            [23, 24, 25, 26, 27, 28, 29, 30, 31, 32]
          ]));
  test(
      '1 to 33',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7],
            [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
            [23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]
          ]));
  test(
      '1 to 34',
      () => _testStream(true, [
            [1, 2, 3, 4, 5],
            [6, 7],
            [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22],
            [23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34]
          ]));

  //
  // Mix up a bunch of sizes to try to catch every permutation of
  // the buffer filling logic...
  //
  for (var i = 0; i < 250; i += 1 + i ~/ 5 + i ~/ 10) {
    test('length factor $i', () async {
      final data = List<List<int>>(i);
      for (var j = 0; j < 1000; j += 1 + j ~/ 5 + j ~/ 10) {
        for (var ii = 0; ii < i; ii++) {
          data[ii] = List(rand.nextInt(j + 1));
          for (var jj = 0; jj < data[ii].length; jj++) {
            data[ii][jj] = rand.nextInt(0x100);
          }
        }
        _testStream(false, data);
      }
    });
  }

  //
  // Test all the different data types for DataInputStream/
  // DataOutputSink
  //
  for (var endian in [Endian.big, Endian.little]) {
    const iterations = 100;
    // We do several iterations to make sure that we catch all of the
    // code paths in DataInputStream.  Note the use of
    // DataInputStream.debugStream.
    final name = (endian == Endian.big) ? 'big endian' : 'little endian';
    // Endian really should override toString to do this
    test('Data[Input|Output]Stream all methods, $name', () async {
      final acc = AccumulatorSink<Uint8List>();
      final out = DataOutputSink(acc, endian);
      for (var i = 0; i < iterations; i++) {
        final numExtraBytes = rand.nextInt(3);
        out.writeUnsignedShort(numExtraBytes);
        out.writeBytes(Uint8List(numExtraBytes));
        // We emit a random amount of space to catch all the code paths
        // in DataOutputStream relating to buffer management.  See also
        // the use of DataInputStream.debugStream().

        out.writeBoolean(false);
        out.writeByte(1);
        out.writeBytes(const [2, 3]);
        out.writeBytes(const [4, 5]);
        out.writeShort(6);
        out.writeUnsignedShort(7);
        out.writeInt(8);
        out.writeUnsignedInt(9);
        out.writeLong(10);
        out.writeUnsignedLong(11);
        out.writeUTF8('zero X zero C');
        out.writeFloat(13.3);
        out.writeDouble(14.4);
        out.writeBytes(const <int>[]);
      }
      out.close();

      final equals = ListEquality<int>().equals;
      final allBytes =
          acc.events.fold(ByteAccumulatorSink(), (a, b) => a..add(b)).bytes;
      final dis = ByteBufferDataInputStream(allBytes, endian);
      for (var i = 0; i < iterations; i++) {
        final numExtraBytes = dis.readUnsignedShort();
        dis.readBytes(numExtraBytes); // Thow them away
        expect(dis.readBoolean(), false);
        expect(dis.readByte(), 1);
        expect(equals(dis.readBytes(2), const [2, 3]), true);
        expect(equals(dis.readBytesImmutable(2), const [4, 5]), true);
        expect(dis.readShort(), 6);
        expect(dis.readUnsignedShort(), 7);
        expect(dis.readInt(), 8);
        expect(dis.readUnsignedInt(), 9);
        expect(dis.readLong(), 10);
        expect(dis.readUnsignedLong(), 11);
        expect(dis.readUTF8(), 'zero X zero C');
        expect((13.3 - dis.readFloat()).abs() < 0.00001, true);
        expect(dis.readDouble(), 14.4);
        expect(equals(dis.readBytes(0), const <int>[]), true);
        expect(equals(dis.readBytesImmutable(0), const <int>[]), true);
      }
      expect(dis.isEOF(), true);
      dis.close();

      final dis2 = DataInputStream(
          DataInputStream(Stream.fromIterable(acc.events)).debugStream(),
          endian);
      for (var i = 0; i < iterations; i++) {
        final numExtraBytes = await dis2.readUnsignedShort();
        await dis2.readBytes(numExtraBytes); // Thow them away
        expect(await dis2.readBoolean(), false);
        expect(await dis2.readByte(), 1);
        expect(equals(await dis2.readBytes(2), const [2, 3]), true);
        expect(equals(await dis2.readBytesImmutable(2), const [4, 5]), true);
        expect(await dis2.readShort(), 6);
        expect(await dis2.readUnsignedShort(), 7);
        expect(await dis2.readInt(), 8);
        expect(await dis2.readUnsignedInt(), 9);
        expect(await dis2.readLong(), 10);
        expect(await dis2.readUnsignedLong(), 11);
        expect(await dis2.readUTF8(), 'zero X zero C');
        expect((13.3 - await dis2.readFloat()).abs() < 0.00001, true);
        expect(await dis2.readDouble(), 14.4);
        expect(equals(dis.readBytes(0), const <int>[]), true);
        expect(equals(dis.readBytesImmutable(0), const <int>[]), true);
      }
      expect(await dis2.isEOF(), true);
      await dis2.close();
    });
  }

  test('Data[Input|Output]Stream, endian mismatch', () async {
    final acc = AccumulatorSink<Uint8List>();
    final out = DataOutputSink(acc, Endian.little);
    out.writeUnsignedInt(0xdeadbeef);
    out.close;

    final dis = DataInputStream(Stream.fromIterable(acc.events));
    expect(await dis.readUnsignedInt(), 0xefbeadde);
    expect(await dis.isEOF(), true);
    await dis.close();
  });

  // Create an isolate so we can stream data through
  // encryption/decryption without buffering it all in memory.  These
  // tests are randomized, so we run a fair number of iterations.
  test('stream test 5', () => bigTest(rand, 5));
  for (var i = 0; i < 100; i++) {
    test('stream test 250 $i', () => bigTest(rand, 250));
  }
  // And finally, run one with a larger amount of data.
  test('stream test 25000', () => bigTest(rand, 25000));
}
