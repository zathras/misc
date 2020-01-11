/// Illustration of IsolateStream, using FizzBuzz as
/// a stand-in for a computationally intensive series

import 'dart:async';
import 'package:intl/intl.dart';
import 'package:jovial_misc/isolate_stream.dart';

final fmt = NumberFormat();

void main() async {
  final max = 1000000000;
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

// The generator function that runs in a separate isolate:
Future<void> _generator(int max, IsolateGeneratorSink<dynamic> sinkArg) async {
  // Keep our sink type-safe:
  final sink = IsolateGeneratorSink<String>.fromDynamic(sinkArg);

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
  }
}

// The sizeOf function, in the same units as maxBuf.  This tells us how
// many strings are in a string, in our case.
int _sizeOf(String s) => 1;
