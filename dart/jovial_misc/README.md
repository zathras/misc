Miscellaneous small-ish bits of Dart code.  It's mostly for my own
use, buy you're welcome to it.  Please to attribute it if you do, e.g.
with a link to https://jovial.com/bill.html.  Offered under
the [MIT license](../LICENSE).

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:jovial_misc/io_utils.dart';

main() {
  final acc = AccumulatorSink<Uint8List>();
  final out = DataOutputSink(acc);
  out.writeUTF8("Hello, world.");
  out.close();

  final allBytes =
      acc.events.fold(ByteAccumulatorSink(), (a, b) => a..add(b)).bytes;
  final dis = ByteBufferDataInputStream(allBytes);
  print(dis.readUTF8());
  dis.close();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/zathras/misc/issues
