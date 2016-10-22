#!/bin/sh -x
export JDK=/usr/lib/jvm/java-8-openjdk-amd64
rm -rf ../lib
mkdir ../lib
cd ../src
javah scurses.RawCurses
rm -f scurses/scurses_RawCurses.h
mv scurses_RawCurses.h scurses
cd scurses
gcc -fPIC -shared -I$JDK/include -I$JDK/include/linux *.c -lncurses -o ~/lib/libscurses.so
ls -ls ~/lib/libscurses.so
