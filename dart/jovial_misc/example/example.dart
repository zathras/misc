import 'dart:async';
import 'package:convert/convert.dart';
import 'package:intl/intl.dart';
import 'package:jovial_misc/io_utils.dart';
import 'package:jovial_misc/isolate_stream.dart';

///
/// Example of using [DataOutputSink] and [DataInputStream] to
/// encode values that are compatible with `java.io.DataInputStream`
/// and `java.io.DataOutputStream`
///
Future<void> data_io_stream_example() async {
  final acc = ByteAccumulatorSink();
  final out = DataOutputSink(acc);
  out.writeUTF8('Hello, world.');
  out.close();

  final stream = Stream<List<int>>.fromIterable([acc.bytes]);
  final dis = DataInputStream(stream);
  print(await dis.readUTF8());
  await dis.close();
}

///
/// Example of [IslateStream] to run a computationally-intensive
/// generator function in an isolate.  We use FizzBuzz as a
/// stand-in for a computationally intensive series of values.
///
Future<void> isolate_stream_example() async {
  final max = 1000000000;
  final fmt = NumberFormat();
  const iterationPause = Duration(milliseconds: 250);
  print('Generating FizzBuzz sequence up to ${fmt.format(max)}');

  final stream = IsolateStream.fromSink(_generator, max, _sizeOf, maxBuf: 30);
  // Our stream will be limited to 30 strings in the buffer at a time.
  for (var iter = StreamIterator(stream); await iter.moveNext();) {
    print(iter.current);
    await Future.delayed(iterationPause);
  }
  // Note that the producer doesn't run too far ahead of the consumer,
  // because the buffer is limited to 30 strings.
}

// Two support functions for the isolate streams.  As fo this writing (January
// 2020), these need to be top-level functions, and not closures, due to
// current limitations in Dart's Isolate.  (There's no fundamental reason
// why a lambda that holds no references to values on the heap can't be
// passed to another isolate, so this restriction could theoretically be
// lifted in future versions of Dart.  However, it's understandable why
// the Dart designers have drawn a simple, bright line.)

// The generator function that runs in a separate isolate:
Future<void> _generator(int max, IsolateGeneratorSink<String> sink) async {
  for (var i = 1; i <= max; i++) {
    var result = '';
    if (i % 3 == 0) {
      result = 'Fizz';
    }
    if (i % 5 == 0) {
      result += 'Buzz';
    }
    if (result == '') {
      sink.add(i.toString());
    } else {
      sink.add(result);
    }
    if (i % 25 == 0) {
      print('        Generator is up to $i');
    }
    await sink.flushIfNeeded();
    // If flushIfNeeded() weren't called, the generator would run without
    // limit until the buffer between the isolates exceeded available memory.
  }
}

// The sizeOf function, in the same units as maxBuf.  This tells us how
// many strings are in a string, in our case.
int _sizeOf(String s) => 1;

///
/// Run the examples
///
void main() async {
  await data_io_stream_example();
  print('');
  await isolate_stream_example();
}
