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
