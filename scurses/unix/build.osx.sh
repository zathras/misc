#!/bin/sh -x
export JDK=/Library/java/JavaVirtualMachines/jdk1.8.0_45.jdk/Contents/Home
rm -rf ../lib
mkdir ../lib
cd ../src
javah scurses.RawCurses
rm -f scurses/scurses_RawCurses.h
mv scurses_RawCurses.h scurses
cd scurses
gcc -I$JDK/include -I$JDK/include/darwin -shared -dynamiclib -o ~/lib/libscurses.jnilib -lncurses *.c
