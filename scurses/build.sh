#!/bin/sh -x
rm -rf classes
mkdir classes
cd src
javac -d ../classes scurses/*.java

