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

# 0.5.0

Update for null safety

# 0.5.1

Added seek and remainingCopy to io_utils

# 0.6.0

Made io_utils work on JS runtime by:
- Making `EOFException` not subclass IOException
  - This is an API change, since `catch IOException` will no longer catch `EOFException`.
- making io_utils not depend on dart.io, so it can be used in the browser
  - moved `FlushingIOSink` to a new package.  This is an API change,
    since client imports will need to be adjusted.

# 0.6.1
dartfmt -w

# 0.7.0
- Split off `FlushingIOSink` to an entirely different `pub.dev` listing, so that it's
  clear that the rest of this is fine on the JS runtime.
  - This is an API change, since client pubspec.yaml files need to add the new
    jovial_misc_native entry.  Sigh.

# 0.8.0
- Split off the isolate stuff to `jovial_misc_native`
  - This is an API change, since client pubspec.yaml files need to add the new
    jovial_misc_native entry.

# 0.8.1
- Migrated from pedantic to new lints introduced with SDK 1.4.

# 0.8.2
- Added `AsyncCanonicalizingFetcher`

# 0.8.3
- Fixed typo in documentation

# 0.8.4
- Added smoke test for AsyncCanonicalizingFetcher
- Used marginally more efficient Map.putIfAbsent method in AsyncCanonicalizingFetcher
- Add CircularBuffer
- Broaden `ByteBufferDataInputStream` constructor to take `List<int>`.

# 0.8.5
- Remove ununsed dependency on intl

# 0.9.0
- Split off encrypting/decrypting streams to `jovial_misc_pc`

# 0.9.1
- Update dependencies
