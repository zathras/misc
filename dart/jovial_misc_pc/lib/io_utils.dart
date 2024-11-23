///
/// Miscellaneous I/O utilities.  This includes for using Pointycastle to
/// encrypt or decrypt a stream of data, somewhat like
/// `javax.crytpo.CipherInputStream` and `javax.crypto.CypherOutputStream`.
///
library io_utils;

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:jovial_misc/io_utils.dart';
import 'package:async/async.dart'; // Only for Cipher*Stream
import 'package:pointycastle/export.dart'; // Only for Cipher*Stream

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
