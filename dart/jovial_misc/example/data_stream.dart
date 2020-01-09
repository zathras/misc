
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
