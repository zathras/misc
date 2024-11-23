/// This module contains a set of tests for io_utils.dart.  Add them
/// to a test harness by calling add_io_utils_tests().

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/export.dart';

import 'package:jovial_misc_pc/io_utils.dart';

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
  final encryptCipher = CBCBlockCipher(AESEngine())
    ..init(true, ParametersWithIV(KeyParameter(key), iv)); // true=encrypt
  final decryptCipher = CBCBlockCipher(AESEngine())
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
}
