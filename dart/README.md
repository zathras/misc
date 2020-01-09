# misc-dart
Miscellaneous small-ish bits of Dart code.  It's mostly for my own
use, buy you're welcome to it.  Please to attribute it if you do, e.g.
with a link to https://bill.jovial.com/.  See ../LICENSE.

This directory contains:

    io_utils.md
    io_utils_tests.md
        I/O helper utilities, including adapters to interoperate with
        java.io.DataInputStream and java.io.DataOutputStream.

    isolate_stream.md
    isolate_stream_tests.md
        A library to run a stream generator function in an isolate,
        with flow control.  This allows a space-efficient generatore
        for a stream to run in its own Isolate (and therefore, thread).

