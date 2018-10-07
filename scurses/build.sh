#!/bin/sh -x
rm -rf classes
mkdir classes
cd src
javac -source 1.5 -target 1.5 -d ../classes scurses/*.java

