/// Miscellaneous I/O utilities.  This includes reading and writing binary
/// data in a way that's interoperable with `java.io.DataInputStream` and
/// `java.io.DataOutputStream`, and support for using Pointycastle to
/// encrypt or decrypt a stream of data, somewhat like
/// `javax.crytpo.CipherInputStream` and `javax.crypto.CypherOutputStream`.
/// ```
/// /// Example of using [DataOutputSink] and [DataInputStream] to
/// /// encode values that are compatible with `java.io.DataInputStream`
/// /// and `java.io.DataOutputStream`
/// ///
/// Future<void> data_io_stream_example() async {
///   final file = File.fromUri(Directory.systemTemp.uri.resolve('test.dat'));
///   final flushable = FlushingIOSink(file.openWrite());
///   final out = DataOutputSink(flushable);
///   out.writeUTF8('Hello, world.');
///   out.close();
///   await flushable.done;
///
///   final dis = DataInputStream(file.openRead());
///   print(await dis.readUTF8());
///   await dis.close();
///   await file.delete();
/// }

/// ```

library io_utils;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:async/async.dart'; // Only for Cipher*Stream
import 'package:pointycastle/export.dart'; // Only for Cipher*Stream

class EOFException implements IOException {
  final String message;

  const EOFException(this.message);

  @override
  String toString() => 'EOFException: $message';
}

/// A coroutines-style wrapper around a
/// `Stream<List<int>>`, like you get from a socket or a file in Dart.
/// This lets you asynchronously read a stream using an API much like
/// `java.io.DataInputStream`.
///
/// Note that this class does not read all of the data into a buffer first,
/// so it is very space-efficient.  It does, however, use asynchrony at a
/// fairly granular level.  This might have performance implications, depending
/// on how efficient async/await are in current Dart implementations.  As
/// of this writing (Jan. 2020), I have not measured.
///
/// See also [ByteBufferDataInputStream].
class DataInputStream {
  // Iterates through the provided Stream<List<int>> directly,
  // and buffers by hanging onto a Uint8List until it's been completely
  // read.  I suppose I could have based this off of quiver's
  // StreamBuffer class, but that doesn't seem to handle checking for
  // EOF.  Besides, as the great Japanese philosopher
  // Gudetama famously said, "meh."   (⊃◜⌓◝⊂)
  final StreamIterator<List<int>> _source;
  Uint8List _curr;
  int _pos;
  static const _utf8Decoder = Utf8Decoder(allowMalformed: true);

  /// The current endian setting, either [Endian.big] or [Endian.little].
  /// This is used for converting numeric types.  Choose [Endian.big]
  /// for interoperability with `java.io.DataInputStream`.
  Endian endian;

  /// Create a stream that takes its data from source with the given
  /// initial [endian] setting.  Choose [Endian.big]
  /// for interoperability with `java.io.DataInputStream`.
  DataInputStream(Stream<List<int>> source, [this.endian = Endian.big])
      : _source = StreamIterator<List<int>>(source);

  /// Returns the number of bytes that can be read from the internal buffer.
  ///  If we're at EOF, returns zero, otherwise, returns a non-zero positive
  ///  integer.  If the buffer is currently exhausted, this method will wait
  ///  for the next block of data to come in.
  Future<int> get bytesAvailable async {
    if (await isEOF()) {
      return 0;
    }
    return _curr.length - _pos;
  }

  /// Check if we're at end of file.
  Future<bool> isEOF() async {
    while (_curr == null || _pos == _curr.length) {
      final ok = await _source.moveNext();
      if (!ok) {
        return true;
      }
      if (_source.current is Uint8List) {
        _curr = _source.current as Uint8List;
      } else {
        _curr = Uint8List.fromList(_source.current);
      }
      _pos = 0;
      // Loop around again, in case we got an empty buffer.
    }
    return false;
  }

  /// Make sure that at least one byte is in the buffer.
  Future<void> _ensureNext() async {
    if (await isEOF()) {
      throw EOFException('Unexpected EOF');
    }
    // isEOF() sets up _curr and _pos as a side effect.
  }

  /// Returns a new, mutable [Uint8List] containing the desired number
  /// of bytes.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<Uint8List> readBytes(int num) async {
    if (num == 0) {
      return Uint8List(0);
    }
    await _ensureNext();
    if (_pos == 0 && num == _curr.length) {
      _pos = _curr.length;
      return Uint8List.fromList(_curr);
    } else if (_pos + num <= _curr.length) {
      final result = Uint8List.fromList(_curr.sublist(_pos, _pos + num));
      _pos += num;
      return result;
    } else {
      final len = _curr.length - _pos;
      assert(len > 0 && len < num);
      final result = Uint8List(num);
      final buf = await readBytesImmutable(len);
      result.setRange(0, len, buf);
      final buf2 = await readBytesImmutable(num - len);
      result.setRange(len, num, buf2);
      return result;
    }
  }

  /// Returns a potentially immutable [Uint8List] containing the desired number
  /// of bytes.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<Uint8List> readBytesImmutable(int num) async {
    if (num == 0) {
      return Uint8List(0);
    }
    await _ensureNext();
    if (_pos == 0 && num == _curr.length) {
      _pos = _curr.length;
      return _curr;
    } else if (_pos + num <= _curr.length) {
      final result = _curr.sublist(_pos, _pos + num);
      _pos += num;
      return result;
    } else {
      final len = _curr.length - _pos;
      assert(len > 0 && len < num);
      final result = Uint8List(num);
      var buf = await readBytesImmutable(len);
      result.setRange(0, len, buf);
      buf = await readBytesImmutable(num - len);
      result.setRange(len, num, buf);
      return result;
    }
  }

  /// Returns a potentially immutable [ByteData] containing the desired number
  /// of bytes.
  Future<ByteData> readByteDataImmutable(int num) async {
    final bytes = await readBytesImmutable(num);
    return bytes.buffer.asByteData(bytes.offsetInBytes, num);
  }

  /// Reads and returns a 4-byte signed integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<int> readInt() async {
    await _ensureNext();
    if (_curr.length - _pos < 4) {
      // If we're on a buffer boundary, keep it simple
      return (await readByteDataImmutable(4)).getInt32(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getInt32(_pos + _curr.offsetInBytes, endian);
      _pos += 4;
      return result;
    }
  }

  /// Reads and returns a 4-byte unsigned integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<int> readUnsignedInt() async {
    await _ensureNext();
    if (_curr.length - _pos < 4) {
      // If we're on a buffer boundary
      // Keep it simple
      return (await readByteDataImmutable(4)).getUint32(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getUint32(_pos + _curr.offsetInBytes, endian);
      _pos += 4;
      return result;
    }
  }

  /// Reads and returns a 2-byte unsigned integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<int> readUnsignedShort() async {
    await _ensureNext();
    if (_curr.length - _pos < 2) {
      // If we're on a buffer boundary
      // Keep it simple
      return (await readByteDataImmutable(2)).getUint16(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getUint16(_pos + _curr.offsetInBytes, endian);
      _pos += 2;
      return result;
    }
  }

  /// Reads and returns a 2-byte signed integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<int> readShort() async {
    await _ensureNext();
    if (_curr.length - _pos < 2) {
      // If we're on a buffer boundary
      // Keep it simple
      return (await readByteDataImmutable(2)).getInt16(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getInt16(_pos + _curr.offsetInBytes, endian);
      _pos += 2;
      return result;
    }
  }

  /// Reads and returns an unsigned byte.
  ///
  /// Throws [EOFException] if EOF is reached before the needed byte is read.
  Future<int> readUnsignedByte() async {
    await _ensureNext();
    return _curr[_pos++];
  }

  /// Reads a signed byte.  Returns an `int` between -128 and 127, inclusive.
  /// See also [readUnsignedByte].
  ///
  /// Throws EOFException if EOF is reached before the needed byte is read.
  Future<int> readByte() async {
    final b = await readUnsignedByte();
    if (b & 0x80 != 0) {
      return b - 0x100;
    } else {
      return b;
    }
  }

  /// Reads and returns an 8-byte integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<int> readLong() async {
    await _ensureNext();
    if (_curr.length - _pos < 8) {
      // If we're on a buffer boundary
      // Keep it simple
      return (await readByteDataImmutable(8)).getInt64(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getInt64(_pos + _curr.offsetInBytes, endian);
      _pos += 8;
      return result;
    }
  }

  /// Reads and returns an 8-byte integer, converted to
  /// a Dart int according to the semantics of [ByteData.getUint64]
  /// using the current [endian] setting.
  ///
  /// NOTE:  Dart doesn't support unsigned longs, but you can get an
  ///        unsigned [BigInt] using [BigInt.toUnsigned].
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<int> readUnsignedLong() async {
    await _ensureNext();
    if (_curr.length - _pos < 8) {
      // If we're on a buffer boundary
      // Keep it simple
      return (await readByteDataImmutable(8)).getUint64(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getUint64(_pos + _curr.offsetInBytes, endian);
      _pos += 8;
      return result;
    }
  }

  /// Reads and returns a 4-byte float, using the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<double> readFloat() async {
    await _ensureNext();
    if (_curr.length - _pos < 4) {
      // If we're on a buffer boundary
      // Keep it simple
      return (await readByteDataImmutable(4)).getFloat32(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getFloat32(_pos + _curr.offsetInBytes, endian);
      _pos += 4;
      return result;
    }
  }

  /// Reads and returns an 8-byte double, using the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<double> readDouble() async {
    await _ensureNext();
    if (_curr.length - _pos < 8) {
      // If we're on a buffer boundary
      // Keep it simple
      return (await readByteDataImmutable(8)).getFloat64(0, endian);
    } else {
      final result = _curr.buffer
          .asByteData()
          .getFloat64(_pos + _curr.offsetInBytes, endian);
      _pos += 8;
      return result;
    }
  }

  /// Reads a string encoded in UTF8.  This method first reads a 2 byte
  /// unsigned integer decoded with the current [endian] setting,
  /// giving the number of UTF8 bytes to read.  It then reads
  /// those bytes, and converts them to a string using Dart's UTF8 conversion.
  /// This may be incompatible with `java.io.DataOutputStream`
  /// for a string that contains nulls.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Future<String> readUTF8() async {
    final len = await readUnsignedShort();
    final bytes = await readBytesImmutable(len);
    return _utf8Decoder.convert(bytes);
  }

  /// Reads a byte, and returns false if it is 0, true otherwise.
  ///
  /// Throws [EOFException] if EOF is reached before the needed byte is read.
  Future<bool> readBoolean() async {
    await _ensureNext();
    return _curr[_pos++] != 0;
  }

  /// Returns the next unsigned byte, or -1 on EOF
  Future<int> read() async {
    if (await isEOF()) {
      return -1;
    } else {
      return _curr[_pos++];
    }
  }

  /// Test out the buffer logic by returning randomized, smallish chunks
  /// of data at a time.  The stream
  /// obtained from this method can be fed into another DataInputStream.
  Stream<Uint8List> debugStream([Random random]) async* {
    random ??= Random();
    while (!(await isEOF())) {
      var remain = _curr.length - _pos;
      while (remain > 0) {
        final len = random.nextInt(remain + 1);
        yield Uint8List.view(_curr.buffer, _curr.offsetInBytes + _pos, len);
        remain -= len;
        _pos += len;
      }
      assert(_pos == _curr.length);
    }
  }

  /// Give a stream containing our as-yet-unread bytes.
  Stream<Uint8List> remaining() async* {
    if (_curr != null && _pos < _curr.length) {
      yield await readBytesImmutable(_curr.length - _pos);
    }
    while (true) {
      if (!await _source.moveNext()) {
        break;
      }
      if (_source.current is Uint8List) {
        yield _source.current as Uint8List;
      } else {
        yield Uint8List.fromList(_source.current);
      }
    }
    // No need to close, because a StreamIterator cancels when
    // moveNext completes with false or error.
  }

  /// Cancel our underling stream.
  Future<void> close() {
    return _source.cancel();
  }
}

/// A wrapper around a List<int>, for synchronous reading
/// of typed binary data from a byte array.  This is similar to a
/// `java.io.DataInputStream` over a `java.io.ByteArrayInputStream`.
///
/// See also [DataInputStream]
class ByteBufferDataInputStream {
  final Uint8List _source;
  final ByteData _asByteData;
  int _pos = 0;
  static const _utf8Decoder = Utf8Decoder(allowMalformed: true);

  /// The current endian setting, either [Endian.big] or [Endian.little].
  /// This is used for converting numeric types.  Choose [Endian.big]
  /// for interoperability with `java.io.DataInputStream`.
  Endian endian;

  /// Create a stream that takes its data from source with the given
  /// initial [endian] setting.  Choose [Endian.big]
  /// for interoperability with `java.io.DataInputStream`.
  ByteBufferDataInputStream(Uint8List source, [Endian endian = Endian.big])
      : this._internal(
            source is Uint8List ? source : Uint8List.fromList(source), endian);

  ByteBufferDataInputStream._internal(Uint8List source, this.endian)
      : _source = source,
        _asByteData = source.buffer
            .asByteData(source.offsetInBytes, source.lengthInBytes);

  /// Returns the number of bytes that can be read from the internal buffer.
  ///  If we're at EOF, returns zero, otherwise, returns a non-zero positive
  ///  integer.
  int get bytesAvailable => _source.lengthInBytes - _pos;

  /// Check if we're at end of file.
  bool isEOF() => _source.lengthInBytes <= _pos;

  /// Returns a new, mutable [Uint8List] containing the desired number
  /// of bytes.
  Uint8List readBytes(int num) {
    return Uint8List.fromList(readBytesImmutable(num));
  }

  /// Returns a potentially immutable [Uint8List] containing the desired number
  /// of bytes.  If the returned list is mutable, changing it might write
  /// through our internal buffer.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  Uint8List readBytesImmutable(int num) {
    if (_pos + num > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _source.sublist(_pos, _pos + num);
      _pos += num;
      return result;
    }
  }

  /// Reads and returns a 4-byte signed integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  int readInt() {
    if (_pos + 4 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getInt32(_pos, endian);
      _pos += 4;
      return result;
    }
  }

  /// Reads and returns a 4-byte unsigned integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  int readUnsignedInt() {
    if (_pos + 4 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getUint32(_pos, endian);
      _pos += 4;
      return result;
    }
  }

  /// Reads and returns a 2-byte unsigned integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  int readUnsignedShort() {
    if (_pos + 2 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getUint16(_pos, endian);
      _pos += 2;
      return result;
    }
  }

  /// Reads and returns a 2-byte signed integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  int readShort() {
    if (_pos + 2 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getInt16(_pos, endian);
      _pos += 2;
      return result;
    }
  }

  /// Reads and returns an unsigned byte.
  ///
  /// Throws [EOFException] if EOF is reached before the needed byte is read.
  int readUnsignedByte() {
    if (_pos + 1 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getUint8(_pos);
      _pos += 1;
      return result;
    }
  }

  /// Reads a signed byte.  Returns an `int` between -128 and 127, inclusive.
  /// See also [readUnsignedByte].
  ///
  /// Throws [EOFException] if EOF is reached before the needed byte is read.
  int readByte() {
    if (_pos + 1 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final b = _asByteData.getInt8(_pos);
      _pos += 1;
      return b;
    }
  }

  /// Reads and returns an 8-byte signed integer
  /// decoded with the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  int readLong() {
    if (_pos + 8 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getInt64(_pos, endian);
      _pos += 8;
      return result;
    }
  }

  /// Reads and returns an 8-byte unsigned integer, converted to
  /// a Dart int according to the semantics of [ByteData.getUint64]
  /// using the current [endian] setting.
  ///
  /// NOTE:  Dart doesn't support unsigned longs, but you can get an
  ///        unsigned [BigInt] using [BigInt.toUnsigned].
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  int readUnsignedLong() {
    if (_pos + 8 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getUint64(_pos, endian);
      _pos += 8;
      return result;
    }
  }

  /// Reads and returns a 4-byte float, using the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  double readFloat() {
    if (_pos + 4 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getFloat32(_pos, endian);
      _pos += 4;
      return result;
    }
  }

  /// Reads and returns an 8-byte double, using the current [endian] setting.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  double readDouble() {
    if (_pos + 8 > _source.lengthInBytes) {
      throw EOFException('Attempt to read beyond end of input');
    } else {
      final result = _asByteData.getFloat64(_pos, endian);
      _pos += 8;
      return result;
    }
  }

  /// Reads a string encoded in UTF8.  This method first reads a 2 byte
  /// unsigned integer decoded with the current [endian] setting,
  /// giving the number of UTF8 bytes to read.  It then reads
  /// those bytes, and converts them to a string using Dart's UTF8 conversion.
  /// This may be incompatible with `java.io.DataOutputStream` for a string
  /// that contains nulls.
  ///
  /// Throws [EOFException] if EOF is reached before the needed bytes are read.
  String readUTF8() {
    final len = readUnsignedShort();
    final bytes = readBytesImmutable(len);
    return _utf8Decoder.convert(bytes);
  }

  /// Reads a byte, and returns `false` if it is 0, `true` otherwise.
  ///
  /// Throws EOFException if EOF is reached before the needed byte is read.
  bool readBoolean() {
    return readUnsignedByte() != 0;
  }

  /// Returns the next unsigned byte, or -1 on EOF
  int read() {
    if (isEOF()) {
      return -1;
    } else {
      return readUnsignedByte();
    }
  }

  /// Render this stream un-readalbe.  This positions the stream to EOF.
  void close() {
    _pos = _source.lengthInBytes;
  }
}

/// An adapter over a `Sink<List<int>>` for writing to a stream.  This class
/// presents an API based on Java's `java.io.DataOutputStream`.
///
/// DataOutputSink does no buffering.
class DataOutputSink {
  final Sink<List<int>> _dest;

  /// The current endian setting, either [Endian.big] or [Endian.little].
  /// This is used for converting numeric types.  Choose [Endian.big]
  /// for interoperability with `java.io.DataOutputStream`.
  Endian endian;

  /// Create a sink that sends its data to dest with the given
  /// initial [endian] setting.  Choose [Endian.big]
  /// for interoperability with `java.io.DataOutputStream`.
  DataOutputSink(this._dest, [this.endian = Endian.big]);

  /// Write the low 8 bits of the given integer as a single byte.
  void writeByte(int b) {
    _dest.add(Uint8List.fromList([b & 0xff]));
  }

  /// Write the given bytes.  A [Uint8List] is the recommended subtype
  /// of `List<int>`.
  void writeBytes(List<int> bytes) {
    if (bytes is Uint8List) {
      _dest.add(bytes);
    } else {
      _dest.add(Uint8List.fromList(bytes)); // Make a more compact copy
    }
  }

  /// Writes a byte containg `0` if `v` is `false`, and `1` if it is `true`.
  void writeBoolean(bool v) {
    writeByte(v ? 1 : 0);
  }

  /// Writes a 2 byte signed short using the current [endian] format.
  void writeShort(int v) {
    final d = ByteData(2)..setInt16(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 2));
  }

  /// Writes a 2 byte unsigned short using the current [endian] format.
  void writeUnsignedShort(int v) {
    final d = ByteData(2)..setUint16(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 2));
  }

  /// Writes a 4 byte int using the current [endian] format.
  void writeInt(int v) {
    final d = ByteData(4)..setInt32(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 4));
  }

  /// Writes a 4 byte unsigned int using the current [endian] format.
  void writeUnsignedInt(int v) {
    final d = ByteData(4)..setUint32(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 4));
  }

  /// Writes an 8 byte long int using the current [endian] format.
  void writeLong(int v) {
    final d = ByteData(8)..setInt64(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 8));
  }

  /// Writes an unsigned 8 byte long using the current [endian] format.
  /// Converts a Dart
  /// `int` according to the semantics of [ByteData.setUint64`.
  void writeUnsignedLong(int v) {
    final d = ByteData(8)..setUint64(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 8));
  }

  /// Writes a four-byte float using the current [endian] format.
  void writeFloat(double v) {
    final d = ByteData(4)..setFloat32(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 4));
  }

  /// Writes an eight-byte double using the current [endian] format.
  void writeDouble(double v) {
    final d = ByteData(8)..setFloat64(0, v, endian);
    _dest.add(d.buffer.asUint8List(d.offsetInBytes, 8));
  }

  /// Write the given string as an unsigned short giving the byte length,
  /// followed by that many bytes containing the UTF8 encoding.
  /// The short is written using the current [endian] format.
  /// This should be compatable with
  /// Java's `DataOutputStream.writeUTF8()`, as long as the string contains no
  /// nulls and no UTF formats beyond the 1, 2 and 3 byte formats.  See
  /// https://docs.oracle.com/en/java/javase/11/docs/api/java.base/java/io/DataInput.html#modified-utf-8
  ///
  /// Throws an ArgumentError if the encoded string length doesn't fit
  /// in an unsigned short.
  void writeUTF8(String s) {
    final utf8 = (const Utf8Encoder()).convert(s);
    if (utf8.length > 0xffffffff) {
      throw ArgumentError(
          'Byte length ${utf8.length} exceeds maximum of ${0xffffffff}');
    }
    writeUnsignedShort(utf8.length);
    _dest.add(utf8);
  }

  void close() {
    _dest.close();
  }
}

/// A wrapper around a [DataInputStream] that decrypts using
/// a Pointycastle [BlockCipher], resulting in a `Stream<List<int>>`.
/// This is functionally similar to `javax.crypto.CipherInputStream`.
class DecryptingStream extends DelegatingStream<Uint8List> {
  DecryptingStream(BlockCipher cipher, Stream<List<int>> input, Padding padding)
      : this.fromDataInputStream(cipher, DataInputStream(input), padding);

  DecryptingStream.fromDataInputStream(
      BlockCipher cipher, DataInputStream input, Padding padding)
      : super(_generate(cipher, input, padding));

  static Stream<Uint8List> _generate(
      BlockCipher cipher, DataInputStream input, Padding padding) async* {
    final bs = cipher.blockSize;
    while (true) {
      final len = max(((await input.bytesAvailable) ~/ bs) * bs, bs);
      // A well-formed encrypted stream will have at least one block,
      // due to padding, and its length will be evenly divisible by the
      // block size.  A well-formed encrypted stream will therefore never
      // generate an EOF in the following line.
      final cipherText = await input.readBytesImmutable(len);
      final plainText = Uint8List(len);
      for (var i = 0; i < len; i += bs) {
        cipher.processBlock(cipherText, i, plainText, i);
      }
      if (await input.isEOF()) {
        final padBytes = padding.padCount(plainText.sublist(len - bs, len));
        if (padBytes < plainText.length) {
          // If not all padding
          yield plainText.sublist(0, plainText.length - padBytes);
        }
        break;
      } else {
        yield plainText;
      }
    }
  }
}

/// A wrapper around a `Sink<List<int>>` that encrypts data using
/// a Pointycastle [BlockCipher].  This sink needs to buffer to build
/// up blocks that can be encrypted, so it's essential that [close()]
/// be called.  This is functionally similar to
/// `javax.crypto.CipherOutputStream`
class EncryptingSink implements Sink<List<int>> {
  final BlockCipher _cipher;
  final Sink<List<int>> _dest;
  final Padding _padding;
  final Uint8List _lastPlaintext;
  int _lastPlaintextPos = 0;
  bool _closed = false;

  EncryptingSink(this._cipher, this._dest, this._padding)
      : _lastPlaintext = Uint8List(_cipher.blockSize);

  @override
  void close() {
    assert(!_closed);
    final bs = _cipher.blockSize;
    if (_lastPlaintextPos > 0) {
      for (var i = _lastPlaintextPos; i < bs; i++) {
        _lastPlaintext[i] = 0;
      }
    }
    _padding.addPadding(_lastPlaintext, _lastPlaintextPos);
    _emit(_lastPlaintext, 0, _lastPlaintext.length);
    _closed = true;
    _dest.close();
  }

  @override
  void add(List<int> data) {
    final bs = _cipher.blockSize;

    // Deal with any pending bytes
    var fromPos = 0;
    {
      final total = _lastPlaintextPos + data.length;
      if (total < bs) {
        _lastPlaintext.setRange(_lastPlaintextPos, total, data);
        _lastPlaintextPos = total;
        return;
      }
      _lastPlaintext.setRange(_lastPlaintextPos, bs, data);
      _emit(_lastPlaintext, 0, bs);
      fromPos = bs - _lastPlaintextPos;
    }

    if (fromPos == data.length) {
      _lastPlaintextPos = 0;
      return; // No more to do
    }

    final toEmit = ((data.length - fromPos) ~/ bs) * bs;
    _emit(data, fromPos, toEmit);
    fromPos += toEmit;

    _lastPlaintextPos = data.length - fromPos;
    if (_lastPlaintextPos > 0) {
      _lastPlaintext.setRange(0, _lastPlaintextPos,
          data.getRange(fromPos, fromPos + _lastPlaintextPos));
    } else {
      // Keep the last block of plaintext around, in case we need it
      // to generate the padding.  See Padding.addPadding() in Pointycastle.
      _lastPlaintext.setRange(
          0, bs, data.getRange(data.length - bs, data.length));
    }
  }

  void _emit(List<int> block, int offset, int len) {
    final bs = _cipher.blockSize;
    assert(len % bs == 0);
    if (len == 0) {
      return;
    }
    final block8 = (block is Uint8List) ? block : Uint8List.fromList(block);
    final out = Uint8List(len);
    for (var i = 0; i < out.length; i += bs) {
      _cipher.processBlock(block8, i + offset, out, i);
    }
    _dest.add(out);
  }
}

/// A wrapper around an [IOSink] that ensures that all data is flushed before
/// the [IOSink] is closed.  This is needed when an [IOSink] is being used with
/// an API obeying the [Sink] contract, which includes [close] but not [flush].
class FlushingIOSink implements Sink<List<int>> {
  final IOSink _dest;
  Future<void> _lastClose;

  FlushingIOSink(this._dest);

  @override
  void add(List<int> data) {
    assert(_lastClose == null);
    _dest.add(data);
  }

  /// Flush all pending data from the underlying [IOSink], and close it.
  /// Returns a future that completes when the flush and close are finished.
  /// Calling this method more than once has no effect.
  /// See also [done].
  @override
  Future<void> close() {
    _lastClose ??= Future(() async {
      await flush();
      return _dest.close();
    });
    return _lastClose;
  }

  /// Flush all pending data from the underlying [IOSink].  Returns a
  /// [Future] that completes when the flush is finished.
  /// See [IOSink.flush].
  Future<void> flush() => _dest.flush();

  /// Get a future that will complete the previous [close]
  /// operation has completed.  It is an error if [close] has not been
  /// called; in this case, the results are undefined.
  Future<void> get done {
    assert(_lastClose != null);
    return _lastClose;
  }
}
