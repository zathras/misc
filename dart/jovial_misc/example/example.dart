import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:jovial_misc/io_utils.dart';
import 'package:jovial_misc/io_utils_native.dart';
import 'package:jovial_misc/isolate_stream.dart';

///
/// Example of using [DataOutputSink] and [DataInputStream] to
/// encode values that are compatible with `java.io.DataInputStream`
/// and `java.io.DataOutputStream`
///
Future<void> data_io_stream_example() async {
  final file = File.fromUri(Directory.systemTemp.uri.resolve('test.dat'));
  final flushable = FlushingIOSink(file.openWrite());
  final out = DataOutputSink(flushable);
  out.writeUTF8('Hello, world.');
  out.close();
  await flushable.done;

  final dis = DataInputStream(file.openRead());
  print(await dis.readUTF8());
  await dis.close();
  await file.delete();
}

///
/// Example of using [IsolateStream] to run a computationally-intensive
/// generator function in an isolate.  We use FizzBuzz as a
/// stand-in for a computationally intensive series of values.
///
Future<void> isolate_stream_example() async {
  const max = 25;
  final fmt = NumberFormat();
  const iterationPause = Duration(milliseconds: 250);
  print('Generating FizzBuzz sequence up to ${fmt.format(max)}');

  final stream = IsolateStream<String>(FizzBuzzGenerator(max));
  // Our stream will be limited to 11 strings in the buffer at a time.
  for (var iter = StreamIterator(stream); await iter.moveNext();) {
    print(iter.current);
    await Future<void>.delayed(iterationPause);
  }
  // Note that the producer doesn't run too far ahead of the consumer,
  // because the buffer is limited to 30 strings.
}

/// The generator that runs in a separate isolate.
class FizzBuzzGenerator extends IsolateStreamGenerator<String> {
  final int _max;

  FizzBuzzGenerator(this._max) {
    print('FizzBuzzGenerator constructor.  Note that this only runs once.');
    // This demonstrats that when FizzBuzzGenerator is sent to the other
    // isolate, the receiving isolate does not run the constructor.
  }

  @override
  Future<void> generate() async {
    for (var i = 1; i <= _max; i++) {
      var result = '';
      if (i % 3 == 0) {
        result = 'Fizz';
      }
      if (i % 5 == 0) {
        result += 'Buzz';
      }
      print('        Generator sending $i $result');
      if (result == '') {
        await sendValue(i.toString());
      } else {
        await sendValue(result);
      }
    }
  }

  @override
  int sizeOf(String value) => 1; // 1 entry

  @override
  int get bufferSize => 7; // Buffer up to 7 entries
}

///
/// Run the examples
///
void main() async {
  await data_io_stream_example();
  print('');
  await isolate_stream_example();
}
