Miscellaneous small-ish bits of Dart code.  It's mostly for my own
use, but you're welcome to it.  Please attribute it if you do, e.g.
with a link to https://jovial.com/bill.html.  Offered under
the [MIT license](https://opensource.org/licenses/MIT).

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:convert/convert.dart';
import 'package:jovial_misc/io_utils.dart';

void main() async {
  final acc = ByteAccumulatorSink();
  final out = DataOutputSink(acc);
  out.writeUTF8('Hello, world.');
  out.close();

  final stream = Stream<List<int>>.fromIterable([acc.bytes]);
  final dis = DataInputStream(stream);
  print(await dis.readUTF8());
  await dis.close();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/zathras/misc/issues
