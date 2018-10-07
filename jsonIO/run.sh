#!/bin/sh
rm -rf out
javac -d out `find . -name '*.java' -print`
if [ $? != 0 ] ; then
    exit 1
fi
java -ea -cp out Main
rm -rf out

