#!/bin/bash
# 
#  Note:  If you're on OSX and you need stdbuf, you can get a quick and
#         dirty version from https://github.com/tcreech/stdbuf-osx.git .
#         Or you can install gnu coreutils, which most people seem to do
#         using homebrew, which uses ruby.

if [ $# != 1 ] ; then
    echo "Defaulting to 1200 baud."
    baud=1200
else
    baud=$1
fi
exec stdbuf -o0 bash -i 2>&1 | stdbuf -i0 -o0 -e0 ./baudsim $baud
