/// This module contains a set of tests for io_utils.dart.  Add them
/// to a test harness by calling add_io_utils_tests().

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

import 'package:jovial_misc/io_utils.dart';

const _paranoia = 1;
// We multiply the amount of randomized testing by this.

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
  for (final e in testData) {
    goalBuilder.add(e);
  }
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
  for (var e in testData) {
    encrypt.add(e);
  }
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
  if (!(const IterableEquality<int>()).equals(result, goal)) {
    throw Exception('test failed');
  }
}

Future<void> addIoUtilsTests() async {
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
      for (var j = 0; j < 1000; j += 1 + j ~/ 5 + j ~/ 10) {
        final data = List<List<int>>.generate(i, (int ii) {
          return List.generate(rand.nextInt(j + 1), (int jj) {
            return rand.nextInt(0x100);
          });
        });
        _testStream(false, data);
      }
    });
  }

  //
  // Test all the different data types for DataInputStream/
  // DataOutputSink
  //
  for (var endian in [Endian.big, Endian.little]) {
    const iterations = 100 * _paranoia;
    // We do several iterations to make sure that we catch all of the
    // code paths in DataInputStream.  Note the use of
    // DataInputStream.debugStream.
    final name = (endian == Endian.big) ? 'big endian' : 'little endian';
    // Endian really should override toString to do this
    test('Data[Input|Output]Stream all methods, $name', () async {
      final acc = AccumulatorSink<Uint8List>();
      final out = DataOutputSink(acc, endian);
      for (var i = 0; i < iterations; i++) {
        final numExtraBytes = rand.nextInt(32);
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
      final allBytes = acc.events
          .fold(ByteAccumulatorSink(),
              (ByteAccumulatorSink a, List<int> b) => a..add(b))
          .bytes;
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
          DataInputStream(Stream.fromIterable(acc.events)).debugStream(rand),
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
    }, timeout: Timeout(Duration(seconds: 5 * _paranoia)));
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
}
