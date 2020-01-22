## 0.0.1, Jan. 9 2020

- Initial version

## 0.0.2, 0.0.3, 0.0.4 Jan. 9 2020

- Fix some cosmetic issues

## 0.1.0 Jan. 9 2020

- All known issues fixed.

## 0.1.1

- Cosmetic fixes to README and example

## 0.2.0

- Added the ability to change the endianness of DataInputStream
  and DataOutputSink.
- Added float and double to DataInputStream and DataOutputSink.
- Fixed ByteBufferDataInputStream.readByte() to return a signed
  byte, as intended.
- Made the unintentionally public DataInputStream.utf8Decoder
  into a private value.
- Documentation improvements.

## 0.2.1, 0.2.2, 0.2.3

- Documentation improvements

## 0.3.0

- Improved IsolateStream.fromSink API to make it type-safe.

## 0.4.0

- Refactored IsolateStream to make the API more pleasing, by making
  IsolateStreamGenerator<T> an abstract superclass for the client to
  implement.

## 0.4.1

- Added FlushingIOSink

## 0.4.2

- Tightened up static type checking (`implicit-casts: false` and
  `implicit-dynamic: false`).

## 0.4.3

- Fixed a bug in DataInputStream, where it was assuming that
  Uint8List.buffer's first byte was the first byte of the list.

## 0.4.4

- DataInputStream:  Avoid unnecessary copying of underlying byte data.
