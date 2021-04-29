#!/bin/sh -x
rm -rf ../lib
mkdir ../lib
cd ../src
javah scurses.RawCurses
rm -f scurses/scurses_RawCurses.h
mv scurses_RawCurses.h scurses
cd scurses

# Build for both Arm and Intel, since we might be on an M1 chip computer
# running under Rosetta.  Or not.
#
# This is a really long way to go to get some ANSI terminal sequences out of
# the curses library!  Oh well.

cc -arch x86_64 -arch arm64 -I$JAVA_HOME/include -I$JAVA_HOME/include/darwin -shared -dynamiclib -o ~/lib/libscurses.jnilib -lncurses *.c
