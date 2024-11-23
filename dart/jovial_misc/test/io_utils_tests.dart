/// This module contains a set of tests for io_utils.dart.  Add them
/// to a test harness by calling add_io_utils_tests().

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';

import 'package:jovial_misc/io_utils.dart';

const _paranoia = 1;
// We multiply the amount of randomized testing by this.

Future<void> addIoUtilsTests() async {
  final rand = Random(0x2a); // Give it a seed so any bugs are repeatable

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
